---
name: implement
description: Executes tasks from a BLUEPRINT.md one at a time — picks the next unblocked task, writes the code, updates task status in the blueprint, and stops for review before moving on. When a DESIGN_M<n>.md exists for the current milestone, treats it as authoritative for contracts, type signatures, and per-task acceptance criteria. Use after the blueprint (and optionally design) skills have produced a plan and the user is ready to turn tasks into code. Traces every change back to a task ID and the requirements it satisfies.
allowed-tools: read bash write edit
---

# Implement Skill

> Part of the four-skill pipeline: `requirements` → `blueprint` → `design` → **implement**. See `skills/README.md` for the full flow and re-planning rules.

Turn blueprint tasks into working code, one task at a time, with a tight feedback loop and a visible audit trail.

## Principles

- **One task at a time.** Never batch-implement multiple tasks silently. Finish one, mark it done, stop for review.
- **Follow the plan.** The blueprint is the contract for scope and structure; the design doc (when present) is the contract for shapes and signatures. Use the specified tech stack, project structure, interfaces, task boundaries, and — if `DESIGN_M<n>.md` exists — its exact request/response JSON, type definitions, module signatures, and per-task acceptance criteria. If reality forces a deviation, surface it — don't silently rewrite the plan.
- **Design beats blueprint on detail.** When the design doc and blueprint conflict on a low-level shape (a JSON field, a signature, a status code), the design doc wins — it was made later, with more information, and interactively. If the conflict is structural (task boundaries, dependencies, tech stack), stop and ask.
- **Trace to requirements.** Every task ties back to a requirement. When implementing, keep the acceptance criteria from `REQUIREMENTS.md` (feature-level) and `DESIGN_M<n>.md` (task-level) in mind and verify against them before marking done.
- **Small, verifiable steps.** Prefer code that compiles/runs/tests green over code that's "almost there." If a task is too big to finish in one shot, split it and update the blueprint.
- **Update the ledger.** After each task, mark its status in `BLUEPRINT.md` so the plan reflects reality. Never lose track of what's done.
- **Ask only when blocked.** Interrupt for clarification only when a decision would materially change the shape of the code and can't be inferred from the spec/blueprint. Otherwise proceed and note assumptions.

## Workflow

### Step 1 — Locate Plan, Spec, and Design

Find all planning documents in the current directory (or ask):

```bash
ls REQUIREMENTS.md BLUEPRINT.md DESIGN_M*.md 2>/dev/null
find . -maxdepth 3 \( -name "REQUIREMENTS.md" -o -name "BLUEPRINT.md" -o -name "DESIGN_M*.md" \) 2>/dev/null | head -20
```

`BLUEPRINT.md` is required. If it's missing, tell the user to run the blueprint skill first. If `REQUIREMENTS.md` is missing but `BLUEPRINT.md` is present, warn the user and proceed using the blueprint as the sole source of truth.

Read every found file in full before doing anything else — spec, blueprint, and every `DESIGN_M<n>.md`. Earlier milestones' design decisions constrain later ones (a type defined in `DESIGN_M1.md` is still authoritative when implementing an M3 task that uses it).

**Staleness check.** For each `DESIGN_M<n>.md`, compare its mtime to `REQUIREMENTS.md` and `BLUEPRINT.md`:

```bash
stat -c '%Y %n' REQUIREMENTS.md BLUEPRINT.md DESIGN_M*.md 2>/dev/null | sort
```

If any design doc predates the last change to spec or blueprint, warn the user:

> "⚠️ `DESIGN_M1.md` was written before the last edit to `BLUEPRINT.md` — it may be stale. Recommend re-running the `design` skill for M1 before implementing tasks in that milestone. Continue anyway?"

Only warn — don't refuse. The user may know the change didn't affect that milestone.

Also scan the current codebase to understand what's already there:

```bash
find . -maxdepth 3 -type f ! -path "*/.git/*" ! -path "*/node_modules/*" ! -path "*/venv/*" ! -path "*/dist/*" ! -path "*/build/*" | head -40
```

### Step 2 — Pick the Next Task

Parse the milestone/task tables in `BLUEPRINT.md`. Build a mental model of:

- **Status** of each task. Recognise these conventions in the task table (add a `Status` column if none exists yet — see Step 6):
  - `todo` / blank / `[ ]` — not started
  - `in-progress` / `wip` / `🚧` — started but not done
  - `done` / `[x]` / `✅` — complete
  - `blocked` / `⛔` — cannot proceed
- **Dependencies** from the "Depends on" column.
- **Milestone order** — don't jump ahead to M2 tasks while M1 has unfinished work, unless the user asks.

Select the next task by this rule:
1. Lowest-numbered milestone with any incomplete tasks.
2. Within that milestone, the lowest-numbered task whose dependencies are all `done` and whose status is `todo` or `in-progress`.
3. If multiple candidates tie, prefer the one with size **S** to build momentum.
4. If nothing is unblocked, list the blockers and ask the user how to proceed.

If the user named a specific task ID (e.g., "implement T1.3"), honour that instead — but warn if its dependencies aren't done.

Once a task is picked, check whether a matching design doc exists for its milestone (`DESIGN_M<n>.md`). Behaviour:

- **Design present** → announce that it will be treated as authoritative for contracts and acceptance criteria.
- **Design absent** → tell the user and offer a choice:

  > "No `DESIGN_M<n>.md` for this milestone. Options:
  > - **A.** Run the `design` skill first to pin down contracts and acceptance criteria interactively (recommended).
  > - **B.** Proceed anyway — I'll derive shapes from the spec, blueprint, and codebase, and record every assumption as I go.
  >
  > Which do you want?"

  If the user picks B, continue but log every inferred contract in Step 6's Implementation Notes so a later design pass (or reviewer) can see what was assumed.

  **In batch mode, do not silently proceed without a design doc.** Stop batch mode and require an explicit A/B answer before continuing. Batching guesses across many tasks is exactly the failure mode design is meant to prevent.

Announce the pick:

> "Next task: **T1.2 — <description>** (size M, depends on T1.1 ✅). Design: `DESIGN_M1.md` ✅ (or: no design doc — proceeding with assumptions). This satisfies requirement _<feature name>_ in the spec. Proceeding — I'll stop for review when it's done."

### Step 3 — Plan the Task

Before writing code, think through:

1. **Scope.** Restate the task's goal and done criterion in your own words.
2. **Acceptance criteria.** If a design doc exists, use its **Per-Task Acceptance Criteria** section for this task ID verbatim — those are the checklist. Otherwise, pull the matching feature-level acceptance criteria from `REQUIREMENTS.md`. List them explicitly — these are what "done" means.
3. **Files to touch.** Which files will be created or modified? Match the blueprint's Project Structure.
4. **Interfaces.** What contracts (function signatures, API shapes, data schemas) does this task expose or consume? If a design doc exists, take the exact JSON shapes, type definitions, and module signatures from it — do not paraphrase or "improve" them. Otherwise, respect anything already fixed by earlier tasks and the spec.
5. **Tests.** What tests will prove this works? Follow the blueprint's Testing Strategy table, and use the fixtures listed in the design doc's **Test Fixtures** table if present.

If any of these can't be resolved from the design+spec+blueprint+codebase, this is a real blocker — go to Step 5b.

For an XL task (or one that turns out to be larger than expected), stop and propose splitting it in the blueprint before writing code.

### Step 4 — Implement

First, flip the task's `Status` to `in-progress` in `BLUEPRINT.md` using `edit`. This lets the plan reflect work-in-progress if the process is interrupted, and lets someone else see at a glance what's active.

Then write the code. Guidelines:

- **Match existing conventions** in the codebase (formatting, naming, module layout) over your own preferences.
- **Match the blueprint's tech stack.** If a task tempts you to reach for a different library, don't — flag it as an open decision instead.
- **Match the design doc's contracts byte-for-byte.** JSON field names, casing, status codes, error shapes, function signatures — take them as-is from `DESIGN_M<n>.md`. If you think the design is wrong, stop and raise it (Step 5b), don't silently "fix" it in code.
- **Keep changes scoped to the task.** Don't refactor unrelated code, don't fix unrelated bugs, don't rename things "while you're there." If you spot something worth doing, add it as a new task in Step 6 rather than doing it now.
- **Write tests alongside code** unless the blueprint explicitly defers testing to a later milestone.
- **Small commits mentally.** Structure the work so it could be reviewed as one coherent change.

Use `edit` for targeted changes, `write` for new files, `bash` for scaffolding commands (e.g., `mkdir`, `npm init`, `cargo new`).

### Step 5a — Verify

Before declaring done, actually run something. What "verify" means depends on the task:

| Task type | Minimum verification |
|-----------|---------------------|
| Scaffolding / config | Project builds / installs cleanly (`npm install`, `cargo build`, `go build`, `pip install -e .`). |
| Feature code | Unit tests pass. If E2E is realistic at this stage, run those too. |
| Bug fix | A regression test exists and passes; the original failure mode no longer occurs. |
| Refactor | Existing tests still pass; behaviour is unchanged. |
| Docs / non-code | Links resolve, examples run, formatting renders. |

Run the appropriate command(s) via `bash`. Capture output. If something fails:
- If it's within the task's scope → fix and re-verify.
- If it's outside scope (pre-existing failure, environmental issue) → note it, don't silently paper over it, and either surface it as a blocker or a new task.

Then walk the acceptance criteria list from Step 3 and confirm each one is satisfied by the code + verification you just did. If any criterion isn't met, the task isn't done.

When a design doc exists, additionally spot-check contract compliance: pick one endpoint / function touched by the task and confirm its actual shape matches the design doc's declared shape exactly (field names, types, status codes). Contract drift caught here is much cheaper than in code review.

### Step 5b — Handle Blockers

If you hit a genuine blocker (missing decision, ambiguous requirement, unavailable dependency, failing environment), do not guess. Do this instead:

1. Mark the task `blocked` in `BLUEPRINT.md` with a one-line reason.
2. If the blocker is a spec/architecture gap, add a row to an **Open Decisions** section in the blueprint (create the section if it doesn't exist).
3. Report to the user: what you tried, what's blocking, and 1–2 concrete options for resolving it.
4. Stop. Do not move to the next task until the blocker is resolved.

### Step 6 — Update the Blueprint

After a task is verified done (or blocked), update `BLUEPRINT.md`:

- **Status column.** If the task tables don't have a `Status` column, add one (the first time you run). Set the just-finished task to `done` (with a ✅), or `blocked` (with ⛔ and a note).
- **New tasks discovered.** If implementation surfaced work that wasn't in the plan (e.g., a helper module, a migration, a follow-up refactor), add it as a new task row in the appropriate milestone, with a fresh ID, size, and dependencies. Briefly note in the change summary that you added it.
- **Deviations.** If you deviated from the plan (different library, different file layout, split a task in two, contract shape adjusted after user approval), record it in an **Implementation Notes** section at the bottom of the blueprint (create it if needed) with the task ID, what changed, and why. If the deviation contradicts the design doc, also note it there and flag that `DESIGN_M<n>.md` should be updated (or invite the user to re-run the `design` skill for the affected milestone).
- **Inferred contracts (no-design mode).** If you're implementing without a design doc, list every contract you had to infer (JSON shape, signature, error code) under Implementation Notes so nothing is invisible.
- **Open decisions resolved.** If your implementation resolved an item in the Open Decisions table, mark it resolved with the chosen option.

Use `edit` for these updates — preserve the rest of the file exactly.

### Step 7 — Report and Stop

Give the user a concise summary:

> **T1.2 done ✅**
>
> - **What changed:** `<file>` (new), `<file>` (edited) — <1-line summary>
> - **Verification:** `<command>` → passed (X tests). Acceptance criteria met: <list>.
> - **Design compliance:** contracts match `DESIGN_M<n>.md` (or: N contracts inferred — see Implementation Notes).
> - **Deviations from plan:** <none / short note>
> - **New tasks added:** <none / T1.5>
> - **Blueprint updated:** status set to done.
>
> Next up would be **T1.3 — <description>**. Want me to continue, or review this first?

**Stop and wait.** Do not automatically start the next task unless the user says "continue" or gave an explicit up-front instruction to run through a milestone unattended.

## Batch Mode (opt-in)

If the user asks to "implement milestone M1" or "run through the plan," acknowledge and switch to batch mode:

- Still do one task at a time internally (plan → implement → verify → update blueprint).
- Report a compact one-line summary per task instead of the full report.
- Stop immediately on any blocker or verification failure and switch back to interactive mode.
- Stop at the end of the requested batch (milestone / task list) and give a full summary.

Never batch across milestone boundaries without explicit permission — milestone completion is a natural review point.

## Starting

When this skill is loaded:
1. Run the file-detection command from Step 1.
2. If `BLUEPRINT.md` is present, say: *"Found `BLUEPRINT.md`<, `REQUIREMENTS.md`, and design docs: DESIGN_M1.md, …> — reading them and picking the next task…"* (list whichever were actually found). Then proceed through the workflow.
3. If `BLUEPRINT.md` is missing: *"I couldn't find a `BLUEPRINT.md`. Run the blueprint skill first to produce an implementation plan, then come back to me."*
4. If the picked task's milestone has no matching `DESIGN_M<n>.md`, offer the A/B choice in Step 2 before starting work.
5. If the user named a specific task in their request, jump straight to Step 2 with that task pre-selected.
