# Skills Pipeline

Four skills work together to take an idea from a fuzzy request to shipped, quality code. They're designed to be run in order, each producing a durable artifact that the next skill consumes.

```
   requirements       blueprint          design             implement
        │                 │                 │                    │
        ▼                 ▼                 ▼                    ▼
  REQUIREMENTS.md    BLUEPRINT.md    DESIGN_M<n>.md          source code
                                    (one per milestone)   + updated BLUEPRINT.md
```

## The stages

| # | Skill | Input | Output | Purpose |
|---|-------|-------|--------|---------|
| 1 | `requirements` | (conversation) | `REQUIREMENTS.md` | Define **what** to build and **why**. Users, features, acceptance criteria, non-goals. Problem-space only. |
| 2 | `blueprint` | `REQUIREMENTS.md` | `BLUEPRINT.md` (+ `REQUIREMENTS_QUESTIONS.md` if gaps found) | Define the **shape**: architecture, tech stack, milestones, task list. Solution-space at the "system" level. |
| 3 | `design` | `BLUEPRINT.md` + `REQUIREMENTS.md` + on-disk artifacts | `DESIGN_M<n>.md` per milestone | Define the **low-level contracts**: exact JSON shapes, type signatures, module interfaces, per-task acceptance criteria. Resolves 🔍 spike tasks. Interactive with options. |
| 4 | `implement` | `BLUEPRINT.md` + `REQUIREMENTS.md` + `DESIGN_M<n>.md` | Source code + updated `BLUEPRINT.md` | Turn tasks into code one at a time, verify each, mark status in the plan. |

## Artifacts and ownership

Each file has one clear owner and a documented set of edits other skills may make.

| File | Owner | Other writers | Notes |
|------|-------|---------------|-------|
| `REQUIREMENTS.md` | `requirements` | — | Rewritten in place during Improvement Mode. |
| `REQUIREMENTS_QUESTIONS.md` | `blueprint` (writer), `requirements` (consumer) | — | Deleted by `requirements` once resolved. |
| `BLUEPRINT.md` | `blueprint` | `design` (marks milestones as designed; closes `Open Decisions`), `implement` (updates `Status` column, `Implementation Notes`, `Open Decisions` on blockers) | Task tables include a `Status` column from the start. `Implementation Notes` section is reserved for `implement`. |
| `DESIGN_M<n>.md` | `design` | — | Per milestone. Authoritative for shapes/signatures/acceptance criteria in that milestone. |

## When to run what

- **Starting a new project** → `requirements` → `blueprint` → `design` (M0/M1) → `implement`.
- **Blueprint audit found gaps** → `requirements` in Improvement Mode → re-run `blueprint`.
- **Ready to start a new milestone** → `design` for that milestone → `implement`.
- **A task hits a blocker** → `implement` marks it `blocked`, adds to `Open Decisions`. Resolve via `design` (if a shape question) or a conversation with the user, then resume.
- **Something changed upstream** → see Re-planning below.

## Re-planning: what to do when things change

Plans drift. Use these rules:

| What changed | What to re-run |
|--------------|----------------|
| `REQUIREMENTS.md` edited by hand or via `requirements` | Re-run `blueprint` (it will audit and diff). Re-run `design` for any milestone whose scope changed. |
| Architecture / tech stack decision in `BLUEPRINT.md` changed | Re-run `design` for every milestone that already had a design doc (its contracts may be invalid). |
| A milestone's task list changed | Re-run `design` for that milestone. |
| A design decision proved wrong during `implement` | Stop, re-open `DESIGN_M<n>.md` via `design` (Improvement Mode is implicit — it reads the existing file first), fix the decision, then resume `implement`. |
| A new task discovered during implementation | `implement` adds it to `BLUEPRINT.md` automatically. If it needs new contracts, re-run `design` for the milestone. |

The `implement` skill already runs a staleness check on `DESIGN_M<n>.md` against `REQUIREMENTS.md` / `BLUEPRINT.md` mtimes and will warn you before working on a stale design.

## Vocabulary

The skills use these terms consistently. Aliases are noted for readability but the canonical name is what appears in filenames and headings.

| Canonical | Aliases (prose only) | Meaning |
|-----------|----------------------|---------|
| **requirements** | spec | The `REQUIREMENTS.md` document. Problem, users, features, acceptance criteria, non-goals. |
| **blueprint** | plan | The `BLUEPRINT.md` document. Architecture, milestones, task tables. |
| **design** | low-level design, LLD | A `DESIGN_M<n>.md` document. Contracts, signatures, per-task acceptance criteria for one milestone. |
| **task** | — | A row in a milestone's task table. Identified by `T<milestone>.<n>` (e.g., `T1.3`). |
| **milestone** | — | A grouping of tasks that ships or verifies together. Identified by `M<n>` (e.g., `M1`). |
| **spike** | investigation, 🔍 | A task with material uncertainty that needs investigation before implementation. Resolved by `design`, not `implement`. |
| **contract** | interface, shape | A public JSON schema, function signature, type definition, or error format. Pinned in the design doc. |
| **acceptance criteria** | — | Checkable pass/fail statements. Feature-level in `REQUIREMENTS.md`, task-level in `DESIGN_M<n>.md`. |

## Design principles across the pipeline

Each skill has its own principles, but three are shared:

1. **Every decision has a home.** Requirements decisions live in `REQUIREMENTS.md`. Architectural decisions in `BLUEPRINT.md`. Contract decisions in `DESIGN_M<n>.md`. Never encode a design decision in code that isn't reflected in the design doc.
2. **Ask, don't guess, at the right level.** `requirements` and `design` are interactive interviews. `blueprint` and `implement` proceed with sensible defaults but surface every assumption in writing.
3. **Trace forward and back.** Every task cites a requirement. Every contract cites a task. Every code change cites a task ID. Reviewers and future contributors can walk the chain in either direction.

## What's missing (not yet built)

- **`code-review`** — reviews a diff against the requirements, blueprint, and design docs for a milestone. Distinct from `code-quality-compare` (which needs two versions).
- **`verify`** — walks the `REQUIREMENTS.md` acceptance criteria and confirms each is actually met at milestone completion.
- **`retro`** — after a milestone ships, updates the docs with what actually happened vs. what was planned.
- **`status`** — a quick read-only view of "where are we in the plan" without invoking `implement`.
