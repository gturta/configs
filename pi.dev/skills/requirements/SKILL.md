---
name: requirements
description: "Guides the user through a structured requirements interview to produce a detailed REQUIREMENTS.md file. Use when the user wants to define, clarify, or document requirements for a feature, product, or system before implementation begins. Also handles improvement mode: when REQUIREMENTS.md has Open Questions that are unfinished (added by the blueprint skill), it conducts a focused interview to fill in the gaps, marks them Closed/Deferred in place, and updates the spec."
allowed-tools: read bash write edit
---

# Requirements Skill

> Part of the four-skill pipeline: **requirements** → `blueprint` → `design` → `implement`. See `skills/README.md` for the full flow.

Help the user produce a detailed `REQUIREMENTS.md` by conducting a focused requirements interview. Ask questions, synthesize answers, and write the file when you have enough information.

This skill operates in two modes:

- **New spec mode** — No spec exists yet. Conduct a full requirements interview and produce `REQUIREMENTS.md` from scratch.
- **Improvement mode** — A `REQUIREMENTS.md` already exists with an **Open Questions** section containing unfinished rows (those added by the blueprint skill's audit). Conduct a focused interview using those rows, then update `REQUIREMENTS.md` in place.

## Principles

- **One topic at a time.** Never dump a wall of questions. Ask the most important open question first, then follow up based on the answer.
- **Dig, don't assume.** If an answer is vague, ask a clarifying follow-up before moving on.
- **Track what you know.** Keep a mental model of answered vs. open areas so you never ask redundant questions.
- **Know when to stop.** Once all required sections have enough detail, offer to write the spec. Don't keep asking for the sake of it.
- **Stay neutral.** Suggest options when helpful, but don't push a technical direction unless the user asks.

---

## Mode Detection (run on startup)

Before doing anything else, check whether a spec exists:

```bash
ls REQUIREMENTS.md 2>/dev/null || find . -maxdepth 3 -name "REQUIREMENTS.md" | head -10
```

**If `REQUIREMENTS.md` is found and has an Open Questions section with at least one `Open` row** → recommend **Improvement Mode** (see below).
**If `REQUIREMENTS.md` is found but has no finished-unfinished distinction needed** → ask the user: *"I found an existing `REQUIREMENTS.md`. Do you want to improve it, or start a new spec from scratch?"* If improving, read the spec and proceed as Improvement Mode (do a general gap review). If starting fresh, enter New Spec Mode.
**If not found** → enter **New Spec Mode**.

---

## Improvement Mode

### Goal
Use the **Open Questions** section of `REQUIREMENTS.md` (rows with `Status: Open`) to conduct a focused interview that fills in the gaps, marking each row `Closed` (or `Deferred`) with the resolution recorded, then update the surrounding spec content in place.

### Step 1 — Read Context
Read `REQUIREMENTS.md` in full. Extract every `Open` row from the Open Questions table, noting its Priority (Critical / Important / Minor) and its Concern (Missing / Vague / Contradictory / Untestable / Architectural).

### Step 2 — Summarise and Confirm
Tell the user what you found, for example:

> "I've read the spec and there are **N open questions** in its Open Questions table:
> - **C critical** rows that must be resolved before architecture can be finalised
> - **I important** rows that shape significant design choices
> - **M minor** rows (I'll make reasonable assumptions for these unless you want to address them)
>
> I'll work through the critical and important ones first. Ready?"

### Step 3 — Focused Interview
Work through the questions in priority order: Critical first, then Important, then (if the user wants) Minor.

Rules for this interview:
- **Group by spec section.** If several questions relate to the same section, address them together naturally in conversation — don't just read out the table row by row.
- **One question at a time.** Ask the most pressing open question, then follow up based on the answer before moving to the next topic.
- **Synthesise, don't transcribe.** After getting an answer, briefly confirm your understanding before moving on (e.g., *"Got it — so the API will be REST with JWT auth. Moving on…"*).
- **Skip what becomes obvious.** If an earlier answer resolves a later question, skip it and note why.
- **Handle minor questions with defaults.** For minor questions, propose a sensible default and ask for confirmation rather than an open-ended question: *"For X, I'll assume Y — does that work, or do you want to change it?"*

### Step 4 — Write the Updated Spec
Once all critical and important questions are answered:
1. Summarise the key changes you are going to make to the spec.
2. Update `REQUIREMENTS.md` in place using `edit`: rewrite the affected sections to incorporate the new answers, and flip each resolved row `Open → Closed` (recording a short resolution after the status) or `Open → Deferred` (with a one-line reason, for questions deliberately parked out of scope). Do not lose any existing detail — only add and improve.
3. If you spot redundant or fully-resolved rows, they may be trimmed, but keep a row per resolved decision so the audit trail stays readable. There is no separate questions file to delete.

Remember: `Closed` rows are definitive; `Deferred` rows are intentionally parked (usually Minor, or explicitly out-of-scope). The `design` skill's guard ignores `Deferred` and `Minor` rows.

---

## New Spec Mode

### Interview Flow

Work through these topic areas in roughly this order, but adapt to what the user volunteers — skip what's already clear, dive deeper where things are fuzzy.

#### 1. Context & Problem
- What are we building? (feature, product, service, CLI tool, API, …)
- What problem does it solve? Who has this problem?
- What exists today? Why is it not good enough?
- What does success look like in concrete terms?

#### 2. Users & Actors
- Who are the primary users? (personas, roles, technical level)
- Are there secondary actors? (admins, external systems, background jobs)
- Any users who are explicitly out of scope?

#### 3. Core Functional Requirements
- What are the key things the system must do? (happy path first)
- For each feature: what is the input, the action, the output?
- What are the acceptance criteria — how will you know it works?

#### 4. Edge Cases & Error Handling
- What can go wrong? (invalid input, network failures, missing data, race conditions)
- How should each failure mode behave from the user's perspective?
- Are there any security or permission boundaries to enforce?

#### 5. Non-Functional Requirements
- Performance: any latency, throughput, or scale targets?
- Reliability: uptime, data durability, retry expectations?
- Security & privacy: authentication, authorization, data sensitivity?
- Accessibility or internationalisation requirements?

#### 6. Technical Constraints & Stack
- Existing codebase, language, or framework to fit into?
- External services, APIs, or data sources involved?
- Deployment environment (cloud, on-prem, serverless, mobile)?
- Any hard constraints (budget, timeline, team skill set)?

#### 7. Data & Interfaces
- What data entities are involved and what are their key fields?
- What are the main interfaces: UI screens, API endpoints, CLI commands, events?
- Any integration points with other systems?

#### 8. Non-Goals & Open Questions
- What is explicitly out of scope for this version?
- What decisions are still unresolved and need a follow-up?

### Determining When to Write

Offer to write the spec when you have covered:
- A clear problem statement
- Identified users
- At least the happy-path functional requirements with acceptance criteria
- Key edge cases
- Major technical constraints

If critical information is still missing, say which areas need answers before you can write a useful spec.

---

## Writing the Spec

When ready, ask the user where to save the file (default: `REQUIREMENTS.md` in the current directory), then write it using the `write` tool.

Use the following structure:

```markdown
# Requirements: <title>

## Overview
One paragraph describing what is being built and why.

## Problem Statement
What problem this solves and for whom. Current pain points or gaps.

## Goals
- Measurable or verifiable outcomes this spec targets.

## Non-Goals
- What is explicitly out of scope for this version.

## Users & Actors
| Actor | Description | Notes |
|-------|-------------|-------|
| ...   | ...         | ...   |

## Functional Requirements

### <Feature Name>
**Description:** What it does.  
**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

_(Repeat for each feature)_

## Edge Cases & Error Handling
| Scenario | Expected Behaviour |
|----------|--------------------|
| ...      | ...                |

## Non-Functional Requirements
| Category | Requirement |
|----------|-------------|
| Performance | ... |
| Security | ... |
| Reliability | ... |

## Technical Constraints
- Language / framework: ...
- External dependencies: ...
- Deployment target: ...

## Data Model
Brief description of key entities and their fields.

## Interfaces
- **UI:** key screens or flows
- **API:** key endpoints or contracts
- **Events / Queues:** if applicable

## Open Questions
| # | Question | Concern | Priority | Owner | Status |
|---|----------|---------|----------|-------|--------|
| 1 | ...      | ...     | ...      | ...   | Open   |
```

---

## Starting

When this skill is loaded:
1. Run the mode detection check (bash command above).
2. **Improvement mode:** *"I found an existing `REQUIREMENTS.md` with N open questions. I'll work through them and mark them Closed/Deferred in place. Give me a moment…"* Then read the spec and follow the Improvement Mode workflow.
3. **New spec mode:** Greet the user and ask the first question:

> "Let's define your requirements. To get started — **what are you building, and what problem should it solve?**"

From there, follow the New Spec Mode interview flow, adapting to their answers. Keep responses concise and focused on the next question or clarification needed.
