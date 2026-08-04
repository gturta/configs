---
name: design
description: Produces a detailed per-milestone design document (DESIGN_M<n>.md) that fills the gap between BLUEPRINT.md and code. Reads the requirements, blueprint, and any relevant on-disk artifacts (schemas, existing files, fixtures), investigates spike tasks, and conducts a focused interactive interview — offering concrete options rather than guessing — to pin down request/response shapes, key type definitions, module interfaces, per-task acceptance criteria, and test fixtures. Use after the blueprint skill and before the implement skill.
allowed-tools: read bash write edit
---

# Design Skill

> Part of the four-skill pipeline: `requirements` → `blueprint` → **design** → `implement`. See `skills/README.md` for the full flow and re-planning rules.

Turn a milestone's tasks into a concrete low-level design that leaves nothing for the implementer to guess. Interactive by default: when a decision needs to be made, **ask the user with a shortlist of options**, don't invent an answer.

## Principles

- **Ask, don't guess.** Any decision that isn't fully pinned down by the spec, blueprint, or on-disk artifacts becomes a question. Never silently pick.
- **Offer options.** Every question comes with 2–4 concrete named options plus a recommendation and one-line rationale. Open-ended "how should this work?" questions are a last resort.
- **Investigate first, ask second.** Before asking, look at the artifacts that already exist on disk (schemas, source files, skill files, fixtures, existing code). Many "questions" are actually already answered by a file — resolve those silently.
- **One milestone at a time.** Design for the milestone that's about to be built, not the whole plan. Volatile detail stays close to the code.
- **Resolve spikes properly.** Any task flagged 🔍 in the blueprint is investigated during design (read library docs, existing code, run a small probe) — not deferred to the implementer.
- **Contract-first.** The design fixes public shapes: request/response JSON, key types, module function signatures, error shapes. Internal implementation is left to `implement`.
- **Per-task acceptance criteria.** Every task in the milestone gets checkable, test-level "done when" statements so `implement` has an unambiguous stop condition.
- **Small deltas.** If the user has already answered something in an earlier round or in the spec, don't re-ask it.

## Workflow

### Step 1 — Locate Inputs

Find the spec, blueprint, and any prior design docs:

```bash
ls REQUIREMENTS.md BLUEPRINT.md REQUIREMENTS_QUESTIONS.md DESIGN_M*.md 2>/dev/null
find . -maxdepth 3 \( -name "REQUIREMENTS.md" -o -name "BLUEPRINT.md" -o -name "REQUIREMENTS_QUESTIONS.md" -o -name "DESIGN_M*.md" \) 2>/dev/null | head -20
```

`BLUEPRINT.md` is required. If missing, tell the user to run the blueprint skill first and stop. Read the blueprint and spec in full. Read any prior `DESIGN_M<n>.md` files too — earlier milestones' design decisions constrain later ones.

**Guard: unresolved requirements.** If `REQUIREMENTS_QUESTIONS.md` exists and still contains unresolved Critical or Important questions, warn the user:

> "The blueprint audit left unresolved spec questions in `REQUIREMENTS_QUESTIONS.md`. Design decisions built on a shaky spec often get thrown away. Recommend running the `requirements` skill first. Continue anyway? (y/N)"

If the user declines, stop. Otherwise proceed but note in the design doc's Assumptions table which spec questions were still open.

### Step 2 — Pick the Milestone

Determine which milestone to design for:

1. If the user named one ("design M2"), use it.
2. Otherwise, pick the lowest-numbered milestone that has no matching `DESIGN_M<n>.md` yet.
3. If all milestones have design docs, ask the user which one to update / redesign.

Announce:

> "Designing **Milestone <n> — <name>** (<k> tasks). I'll read the blueprint, scan the codebase and artifacts, resolve any spike tasks, and then ask you focused questions with options. Let's go."

### Step 3 — Inventory Artifacts

Scan the codebase and any referenced files:

```bash
find . -maxdepth 4 -type f ! -path "*/.git/*" ! -path "*/node_modules/*" ! -path "*/target/*" ! -path "*/dist/*" ! -path "*/build/*" ! -path "*/venv/*" | head -80
```

Then, based on what the milestone touches, `read` the relevant artifacts fully. Examples:

- Schemas mentioned in the blueprint (`schema/*.json`, `*.proto`, OpenAPI docs)
- Existing source files this milestone will modify
- Fixture files, sample inputs, example configs
- Skill / prompt / template files if the domain uses them
- Prior `DESIGN_M<n>.md` files
- Library docs when needed to resolve 🔍 tasks (via `bash` to check `Cargo.toml`, `package.json`, etc. and known API shapes)

**Do not ask the user about anything a file on disk already answers.** Silently resolve those.

### Step 4 — Extract the Decision List

Go through each task in the milestone and list every concrete decision that must be made to implement it without guessing. Categorise:

| Category | What belongs here |
|----------|-------------------|
| **Resolved from artifacts** | Answers you found by reading files — record them, don't ask. |
| **Resolved from spec/blueprint** | Answers already stated upstream — record them, don't ask. |
| **Spike (needs investigation)** | Any 🔍 flag or genuinely uncertain library/protocol question — investigate now (Step 5) before asking. |
| **User decision** | Everything else — turn into a question with options for Step 6. |

Typical decisions to cover for a milestone:

- **API contract** for each endpoint: exact request JSON, exact success response JSON, exact error response JSON, status codes.
- **Key type definitions**: error enums, state structs, config structs, domain types.
- **Module interfaces**: public function signatures with argument and return types.
- **Data flow through state**: how shared state is threaded (globals, DI, per-request extractors).
- **File / path conventions**: where things live, naming rules, config keys.
- **Error semantics**: what maps to which status code / exit code / log level.
- **Test fixtures**: which fixtures exist, what each proves, where they live.
- **Per-task acceptance criteria**: checkable statements for each task.

### Step 5 — Resolve Spikes

For every 🔍 task or genuine investigation item, do the investigation now:

- Read the relevant library source or docs via `bash`/`read` (e.g., `find ~/.cargo/registry -path "*async_openai*" -name "*.rs" | head`).
- Write a small probe script if genuinely necessary (rare — usually reading source is enough).
- Record the finding in a scratchpad, cite the file/line.

If a spike genuinely can't be resolved from available material, that becomes a user question in Step 6 — but frame it as "I looked at X and Y; here's what I found; here are the two viable options."

### Step 6 — Interactive Interview

Now the interactive part. Work through the "User decision" list from Step 4, one question at a time.

Rules:

- **One question per turn.** Never dump a batch. Wait for the answer before moving on.
- **Group related sub-decisions** into a single question when they're small and tightly coupled (e.g., all four fields of a request body), but still one question per turn.
- **Always offer options.** Prefer this shape:

  > **Q: How should `/compare` accept its two invoices?**
  >
  > - **A.** `{ "current": {...}, "previous": {...} }` — bare documents at top level. Simplest, matches how `/explain` currently takes one document.
  > - **B.** `{ "current": { "factura": {...} }, "previous": { "factura": {...} } }` — envelope-per-document, mirrors `/explain` exactly.
  > - **C.** `{ "invoices": [{...}, {...}] }` — array form.
  >
  > **Recommendation: B**, because it means every endpoint validates the same document shape with no branching. Which do you want?

- **Give a recommendation** with a one-line rationale, but don't push.
- **Confirm short answers.** After each answer, restate what you'll record in one sentence, then move on.
- **Skip cascades.** If an answer makes a later question moot, skip it and say so.
- **Free-form fallback.** When options genuinely don't apply (e.g., naming), ask an open question but still propose a default: *"I'll name the config struct `Config` unless you'd prefer something else."*
- **Track progress.** Every few questions, briefly say how many remain: *"3 down, ~4 to go — all on error shapes and fixtures."*

### Step 7 — Draft and Review

Once all decisions are recorded, briefly summarise before writing:

- Number of contracts pinned (endpoints, types, module interfaces)
- Number of spikes resolved
- Any assumptions carried forward
- Any questions the user deferred

Ask: *"Ready for me to write `DESIGN_M<n>.md`, or want to revisit anything?"* Write on confirmation. Default path: `DESIGN_M<n>.md` in the same directory as `BLUEPRINT.md`.

### Step 8 — Update the Blueprint

Two things always happen to the blueprint at the end of design; a third is optional.

**Always: mark the milestone as designed.** Under the milestone heading in `BLUEPRINT.md`, add a line like `**Design:** DESIGN_M<n>.md ✅` so the plan self-documents which milestones have a low-level design.

**Always: close resolved Open Decisions.** Walk the blueprint's `Open Decisions` table. For every row that this design pass resolved (spike outcomes, contract choices confirmed with the user, tech clarifications), mark the row as resolved with the chosen option and a pointer to the design doc. Leave rows that are still open untouched. If the user opted out of resolving one, note that in the design doc's Assumptions table instead.

**Optional: propagate structural feedback.** If design surfaced changes that affect the blueprint's structure — task splits, dependency changes, new tasks discovered, an XL task that must be broken down — record them in a **Design Feedback** section appended to the design doc, then offer:

> "Design resolved 🔍 on T2.3 and split T3.1 into two tasks. Want me to update `BLUEPRINT.md`'s task tables to reflect this, or leave it alone?"

Apply those structural edits only on confirmation. The milestone-designed marker and Open Decisions closures do not need a separate confirmation — they're bookkeeping.

## Output Format

```markdown
# Design: Milestone <n> — <name>

_Generated from `REQUIREMENTS.md` and `BLUEPRINT.md`. Covers tasks T<n>.1 … T<n>.k._

---

## Summary

<2–3 sentences: what this milestone builds and the shape of the design.>

## Inputs Consulted

- `REQUIREMENTS.md` — sections: <list>
- `BLUEPRINT.md` — milestone <n>, plus tech stack and architectural decisions
- Artifacts: `<path>` (<what it told us>), `<path>` (<what it told us>), …
- Prior design: `DESIGN_M<n-1>.md` (<what carried over>)

## Contracts

### API

#### `<METHOD> <path>`

**Request**
```json
{ ... }
```

**Success — 200**
```json
{ ... }
```

**Errors**
| Status | When | Body |
|--------|------|------|
| 400 | ... | `{ "error": "..." }` |
| 500 | ... | `{ "error": "..." }` |

_(Repeat per endpoint touched in this milestone.)_

### Key Types

```<language>
// Rust / TypeScript / etc. type stubs — signatures only, no implementation.
struct AppState { ... }
enum ApiError { ... }
struct Skill { name: String, description: String, body: String }
```

### Module Interfaces

#### `<module>`

```<language>
pub fn foo(x: X) -> Result<Y, ApiError>;
pub fn bar(...) -> ...;
```

_(Repeat per module touched.)_

### State & Wiring

<How shared state is constructed and threaded. Where it's mutated (if ever). Lifetime.>

## Spike Resolutions

| Task | Question | Investigation | Resolution |
|------|----------|---------------|------------|
| T2.3 | How does `async_openai` Responses API expose text? | Read `<crate>/src/responses.rs` | `response.output[0].content[0].text` — see cite. |
| ... | ... | ... | ... |

## Test Fixtures

| Fixture | Path | Purpose |
|---------|------|---------|
| valid `factura` | `fixtures/invoice_valid.json` | happy path for validation + `/explain` |
| missing required | `fixtures/invoice_missing_field.json` | 400 with pointer |
| ... | ... | ... |

## Per-Task Acceptance Criteria

### T<n>.1 — <name>

- [ ] <checkable statement>
- [ ] <checkable statement>
- [ ] Unit test `<name>` passes.

### T<n>.2 — <name>

- [ ] ...

_(Repeat for every task in the milestone.)_

## Assumptions & Deferred Questions

| # | Assumption / Deferred | Impact if wrong |
|---|-----------------------|-----------------|
| 1 | ... | ... |

## Design Feedback for the Blueprint

<Empty if none. Otherwise: tasks to split, dependencies to adjust, new tasks to add, open decisions closed.>
```

## Starting

When this skill is loaded:
1. Run the file-detection command from Step 1.
2. If `BLUEPRINT.md` is missing: *"I need a `BLUEPRINT.md` to design against. Run the blueprint skill first, then come back."*
3. Otherwise: *"Found the plan. I'll pick the next milestone, read the artifacts, resolve any spikes, and then ask you focused questions with options. One moment…"*
4. Proceed through Steps 2–3 silently (reading), then start the interview at Step 6. Do not skip Step 5 (spike investigation) — resolving those before the interview is what keeps question count low.
