# Design: Two-Layer Memory Architecture

**Date:** 2026-04-14
**Status:** Approved
**Topic:** Scalable memory file structure for 500+ entry projects

---

## Problem Statement

The current memory system appends all captured knowledge into four context files
(`decisions.md`, `tech-stack.md`, `industry.md`, `project.md`). On active teams
running `/memorise` daily, these files reach 500+ entries over a year. This creates
three compounding problems:

1. **Session start cost** — loading entire files into context every session is token-expensive
2. **Query performance** — a natural language query like "any conflicts with adding Redis?"
   cannot work when the answer is buried in a 500-entry document Claude must read whole
3. **Write cost** — `/memorise` reading large files to check for duplicates gets slow

The target use case driving this design: a developer about to implement a change asks
Claude "has this been done before, and are there any conflicts?" That query must be
fast and accurate at scale.

---

## Decision Threshold

Not every observation warrants a decision log entry. Log only if the decision meets
at least one of these criteria:

- Affects multiple files, developers, or will persist for months
- Single-file change but major in impact — rewrites core logic, changes a public
  interface, or introduces a new project-wide pattern
- Rejects a commonly-used approach ("we chose not to use X because...")
- Reverses a previous decision ("switched from X to Y")
- Encodes a business rule or constraint
- Resolves a meaningful tradeoff with lasting consequences

**Skip:** routine version bumps, bug fixes with no architectural implication, minor
implementation details with no lasting impact, style choices that don't establish
a new convention.

**Test:** *"Would a new developer joining the team need to know this decision to
understand why the codebase is the way it is?"* If yes, log it.

## Tech-Stack Capture Threshold

Log only if the observation introduces or confirms something a developer would need
to look up or might get wrong without knowing:

- A new language, framework, library, or tool added to the project
- A naming convention, file pattern, or structural rule that applies project-wide
- A tooling constraint (minimum version, required flag, known incompatibility)
- A convention that differs from the framework's default ("we do X instead of Y")

**Skip:** use of a language feature that's obvious from the code, standard library
calls with no project-specific meaning, implementation details inside a single
function, anything a developer would discover immediately by reading the file.

**Test:** *"Would a developer unfamiliar with this project misconfigure or misuse
this tool/pattern without this entry?"* If yes, log it.

## Industry Capture Threshold

Log only if the observation names or explains something that is specific to this
business, domain, or product — not general knowledge:

- Domain terms that have a specific meaning in this product ("in our system, X means...")
- Business rules that constrain behavior ("users can only do Y if Z")
- External systems, APIs, or partners that the codebase integrates with
- Concepts explained in conversation that are not obvious from the code

**Skip:** general programming concepts, framework documentation, terms that are
defined by their plain English meaning, anything a developer could find in a
public API reference without needing project-specific context.

**Test:** *"Would an experienced developer, new to this domain, misunderstand how
the system works without this entry?"* If yes, log it.

---

## Architecture

Split each high-volume context file into two layers:

```
memory/
├── INDEX.md                        ← compact navigation map (loaded at session start)
├── context/
│   ├── decisions.md                ← card index: one line per decision
│   ├── tech-stack.md               ← card index: one line per tool/convention
│   ├── industry.md                 ← card index: one line per domain term/rule
│   └── project.md                  ← unchanged (low write volume)
│
├── decisions-log/
│   └── YYYY-MM.md                  ← full decision entries, partitioned by month
│
├── tech-stack-log/
│   └── YYYY-MM.md
│
└── industry-log/
    └── YYYY-MM.md
```

**Layer 1 — Card indexes** (`context/*.md`): always small, loaded on demand.
**Layer 2 — Monthly logs** (`*-log/YYYY-MM.md`): append-only detail, read on demand.

`/memorise` writes to both layers simultaneously. Neither layer is ever rewritten —
only appended to. Nothing is ever deleted.

---

## Card Index Format

One entry per line. Compact enough that 500 entries fits in a single context read.

### decisions.md

```
YYYY-MM-DD #tag #tag [@author] — One sentence summary → decisions-log/YYYY-MM
```

Example:
```
2026-04-13 #tooling #install [@gordon] — Chose npx over curl-pipe-bash for Windows support → decisions-log/2026-04
2026-04-14 #architecture #memory [@gordon] — Two-layer card index to handle 500+ entries → decisions-log/2026-04
2026-05-03 #api #auth [@sarah] — JWT over sessions for stateless horizontal scaling → decisions-log/2026-05
```

Token cost: ~15 tokens/line. 500 entries ≈ 7,500 tokens.

Author (`[@name]`) applies to `decisions.md` only — decisions are attributed choices.
`tech-stack.md` and `industry.md` omit the author field (they are observations, not choices).

### tech-stack.md

```
YYYY-MM-DD #tag #tag — One sentence summary → tech-stack-log/YYYY-MM
```

### industry.md

```
YYYY-MM-DD #tag #tag — One sentence summary → industry-log/YYYY-MM
```

---

## Detail Log Format

Monthly files, append-only. Created by `/memorise` on first write for that month.

### decisions-log/YYYY-MM.md

```markdown
---
title: Decisions Log — YYYY-MM
tags: [decisions-log]
month: YYYY-MM
updated: YYYY-MM-DD
---

# Decisions Log — Month YYYY

---

## YYYY-MM-DD — Decision Title #tag #tag
**Author:** name
**Source:** conversation | commit abc1234 | session abc123
**Decision:** What was decided.
**Context:** What situation or problem prompted this.
**Options considered:**
- Option A — pros / cons
- Option B — pros / cons
**Reason:** Why this option was chosen, in the decision-maker's own words where possible.
**Consequences:** What this means going forward. Tradeoffs accepted.

---
```

### tech-stack-log/YYYY-MM.md and industry-log/YYYY-MM.md

Lighter schema — no author, no options-considered:

```markdown
## YYYY-MM-DD — Entry Title #tag
**Source:** commit abc1234 | session abc123
**Observed:** What was seen and where.
**Note:** Anything worth knowing for future reference.

---
```

---

## INDEX.md Format

Compact navigation map. No summaries, no entry counts, no recent-changes tables.
Claude reads this once at session start and knows where everything lives.

```markdown
---
tags: [index]
updated: YYYY-MM-DD
---

# Memory Index

## Context
- [[context/decisions]] — decision card index + log refs
- [[context/tech-stack]] — stack + conventions card index + log refs
- [[context/industry]] — domain terms + business rules card index + log refs
- [[context/project]] — goals, constraints, stakeholders

## Logs (read on demand)
- [[decisions-log/]] — full decision entries by month
- [[tech-stack-log/]] — full stack entries by month
- [[industry-log/]] — full domain entries by month
- [[code-changes/]] — daily code change logs

## Find something
- Decisions & conflicts → decisions.md
- Tech conventions → tech-stack.md
- Domain terms → industry.md
- What changed recently → code-changes/
```

---

## Session Start Behaviour

Load `memory/INDEX.md` only. Do not pre-load context files speculatively.

Load other files on demand when the conversation makes them relevant:

| Developer asks | Claude reads |
|---|---|
| "Any conflicts with adding Redis?" | `decisions.md` → relevant `decisions-log/YYYY-MM.md` |
| "What's our auth approach?" | `decisions.md` + `tech-stack.md` card indexes |
| "What does 'idempotency key' mean?" | `industry.md` → relevant `industry-log/YYYY-MM.md` |
| "What are the project constraints?" | `project.md` |
| "What changed last week?" | recent `code-changes/YYYY-MM-DD.md` |

---

## Developer Query Flow

When a developer asks a natural language question about past decisions:

1. Claude reads the relevant card index (if not already in context)
2. Scans all one-liners in one pass — identifies candidates by tag and keyword match
3. Reads only the monthly log files referenced by matching cards (2-3 files maximum)
4. Extracts and presents the relevant full entries with context

Claude never loads detail logs speculatively. If the card index has no matching
entries, Claude reports "no related decisions found" without opening any log files.

---

## /memorise Write Flow

Steps 7, 7b, and 7c each produce raw observations. After each step, classify every
observation into one of three buckets before writing:

| Bucket | What belongs here |
|---|---|
| **decisions** | Explicit choices between options, architectural direction, things ruled out, reversals of previous decisions, business rules that constrain the codebase |
| **tech-stack** | Languages, frameworks, libraries, conventions, naming patterns, file structures, tooling decisions |
| **industry** | Domain terminology, business concepts, how the company or product works, external APIs or systems, user-facing rules |

An observation can belong to more than one bucket — write it to each relevant file.

All three buckets apply their respective threshold before writing. If an observation
does not clear the threshold for a bucket, skip that bucket — do not write to either
layer for it. The thresholds differ in strictness: decisions is the tightest,
tech-stack and industry are lighter but still filtered. Noise in the card index
compounds over time — when in doubt, skip it.

```
For each decisions entry:

1. Get author:
   git config user.name

2. Determine tags from content (#architecture, #tooling, #auth, etc.)

3. Write one-liner to memory/context/decisions.md:
   YYYY-MM-DD #tag [@author] — One sentence → decisions-log/YYYY-MM

4. Open memory/decisions-log/YYYY-MM.md
   Create with frontmatter if it does not exist.
   Append full entry at the bottom — do not modify existing entries.

For each tech-stack entry:

1. Determine tags from content (#language, #framework, #convention, etc.)

2. Write one-liner to memory/context/tech-stack.md:
   YYYY-MM-DD #tag — One sentence → tech-stack-log/YYYY-MM

3. Open memory/tech-stack-log/YYYY-MM.md
   Create with frontmatter if it does not exist.
   Append full entry at the bottom — do not modify existing entries.

For each industry entry:

1. Determine tags from content (#domain, #api, #business-rule, etc.)

2. Write one-liner to memory/context/industry.md:
   YYYY-MM-DD #tag — One sentence → industry-log/YYYY-MM

3. Open memory/industry-log/YYYY-MM.md
   Create with frontmatter if it does not exist.
   Append full entry at the bottom — do not modify existing entries.
```

Source reference: tag each entry with where it was found — `source: commit <hash>`,
`source: session <uuid-prefix>`, or `source: conversation` — so entries are traceable
back to origin if the reasoning needs to be verified later.

---

## template/CLAUDE.md Changes

Replace the session-start file list with:

```markdown
### At Session Start
Read `memory/INDEX.md` only. Load other memory files on demand when the
conversation makes them relevant — do not pre-load speculatively.

### Answering questions about the project
- Decisions, conflicts, past choices → read `memory/context/decisions.md`,
  then open the relevant `memory/decisions-log/YYYY-MM.md` if detail is needed
- Tech stack, conventions → `memory/context/tech-stack.md`
- Domain terms, business rules → `memory/context/industry.md`
- Project goals, constraints → `memory/context/project.md`
- Recent code changes → `memory/code-changes/YYYY-MM-DD.md`
```

---

## README Changes

Add to "How It Works" — Querying the memory:

```markdown
### Querying the memory
Ask Claude in plain language:
- "Any conflicts with adding Redis caching?"
- "Have we made decisions about authentication before?"
- "What does 'idempotency key' mean in our system?"

Claude reads the relevant card index, finds matching entries, and pulls full
detail from the monthly log only for what's relevant. No manual searching — just ask.
```

---

## Migration Plan

Current context files are placeholder stubs — no real content to preserve.

Steps:
1. Replace `memory/context/decisions.md` with card index format
2. Replace `memory/context/tech-stack.md` with card index format
3. Replace `memory/context/industry.md` with card index format
4. Replace `memory/INDEX.md` with compact navigation map
5. Create `memory/decisions-log/.gitkeep`, `memory/tech-stack-log/.gitkeep`, `memory/industry-log/.gitkeep` so git tracks the empty directories
6. Update `.claude/commands/memorise.md` — new write flow
7. Update `template/CLAUDE.md` — new session start behaviour
8. Update `README.md` — add queryability section

For already-installed projects: `--update` only refreshes `memorise.md` and
`verify.sh` — existing context file content is never touched. Users with real
content can manually restructure if they want the two-layer format.

---

## Success Criteria

- `decisions.md` card index remains readable and scannable at 500 entries
- Session start loads only `INDEX.md` — no speculative context file loading
- A developer query "any conflicts with X?" reads at most 3 files total
- Monthly log files are append-only — no existing entry is ever modified
- `/memorise` only logs decisions that meet the threshold — noise stays out
