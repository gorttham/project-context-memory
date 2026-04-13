# Persistent Memory System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a portable, Obsidian-compatible persistent memory folder structure that any project can copy in, giving Claude a structured place to log code changes and capture project/industry context — activated on demand via `/memorise [Xh|Xd]`.

**Architecture:** All data lives in a `memory/` directory as markdown files with YAML frontmatter and wikilinks. A `CLAUDE.md` file instructs Claude to read memory at session start. A `.claude/skills/memorise.md` file defines the `/memorise` slash command, which mines git history and conversation context to populate the memory files.

**Tech Stack:** Pure Markdown, YAML frontmatter, Obsidian wikilinks + callouts, Claude Code skills system

---

## File Map

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Instructs Claude to load memory at session start and update on `/memorise` |
| `memory/INDEX.md` | Obsidian vault home — tag index, section links, recent changes |
| `memory/code-changes/README.md` | Schema documentation for daily change log entries |
| `memory/code-changes/.gitkeep` | Keeps the directory tracked in git |
| `memory/context/project.md` | Project goals, constraints, stakeholders |
| `memory/context/industry.md` | Domain/industry knowledge learned during sessions |
| `memory/context/tech-stack.md` | Languages, frameworks, conventions, tooling |
| `memory/context/decisions.md` | Architectural and design decisions log |
| `memory/people/people.md` | Team members, contributors, stakeholders |
| `memory/preferences/preferences.md` | Coding style and workflow preferences |
| `.claude/skills/memorise.md` | `/memorise` skill definition |
| `README.md` | How to adopt this system in any project |

---

## Task 1: Scaffold Directory Structure

**Files:**
- Create: `memory/code-changes/.gitkeep`
- Create: `memory/context/.gitkeep`
- Create: `memory/people/.gitkeep`
- Create: `memory/preferences/.gitkeep`
- Create: `.claude/skills/.gitkeep`

- [ ] **Step 1: Create all directories**

```bash
mkdir -p memory/code-changes
mkdir -p memory/context
mkdir -p memory/people
mkdir -p memory/preferences
mkdir -p .claude/skills
touch memory/code-changes/.gitkeep
touch memory/context/.gitkeep
touch memory/people/.gitkeep
touch memory/preferences/.gitkeep
touch .claude/skills/.gitkeep
```

- [ ] **Step 2: Verify structure**

```bash
find . -not -path './.git/*' -not -path './docs/*' | sort
```

Expected output (order may vary):
```
.
./CLAUDE.md             ← will be created in Task 2
./.claude
./.claude/skills
./.claude/skills/.gitkeep
./memory
./memory/code-changes
./memory/code-changes/.gitkeep
./memory/context
./memory/context/.gitkeep
./memory/people
./memory/people/.gitkeep
./memory/preferences
./memory/preferences/.gitkeep
```

- [ ] **Step 3: Commit scaffolding**

```bash
git add -A
git commit -m "chore: scaffold memory system directory structure"
```

---

## Task 2: Write CLAUDE.md

**Files:**
- Create: `CLAUDE.md`

- [ ] **Step 1: Create CLAUDE.md**

Create `CLAUDE.md` with the following content exactly:

```markdown
# Claude Session Instructions

## Memory System

This project uses a persistent memory system in the `memory/` directory.

### At Session Start — Read These Files

Load the following in order to restore context:

1. `memory/INDEX.md` — overview of all memory sections
2. `memory/context/project.md` — project goals and constraints
3. `memory/context/tech-stack.md` — conventions and tooling
4. `memory/code-changes/` — open the most recently dated file (YYYY-MM-DD.md)

If any file is missing or empty, skip it and continue.

### During the Session

- When you learn something new about the project domain, note it for `memory/context/industry.md`
- When an architectural decision is made, note it for `memory/context/decisions.md`
- When you observe a new tool, pattern, or convention, note it for `memory/context/tech-stack.md`

You do NOT write these immediately — collect them and write during `/memorise`.

### On /memorise Invocation

The `/memorise` command is defined in `.claude/skills/memorise.md`.
When invoked, follow the skill instructions exactly.

### Memory File Conventions

- All files use YAML frontmatter (`tags`, `updated`, `related`)
- Cross-reference with `[[wikilinks]]` between memory files
- Use callout blocks for highlights:
  - `> [!note]` — general notes
  - `> [!warning]` — things to be careful about
  - `> [!tip]` — useful patterns or shortcuts
  - `> [!decision]` — architectural/design decisions
- Tag vocabulary: `#decision`, `#pattern`, `#domain`, `#preference`, `#person`, `#tech`
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "feat: add CLAUDE.md with memory system session instructions"
```

---

## Task 3: Write memory/INDEX.md

**Files:**
- Create: `memory/INDEX.md`

- [ ] **Step 1: Create INDEX.md**

Create `memory/INDEX.md`:

```markdown
---
tags: [index, memory]
updated: YYYY-MM-DD
---

# Memory Index

> [!note] This is the entry point for the project memory vault.
> Start here to navigate all stored context.

---

## Sections

| Section | Description |
|---------|-------------|
| [[project]] | Project goals, constraints, and stakeholders |
| [[industry]] | Domain/industry knowledge learned |
| [[tech-stack]] | Languages, frameworks, conventions |
| [[decisions]] | Architectural and design decisions |
| [[people]] | Team members, contributors, stakeholders |
| [[preferences]] | Coding style and workflow preferences |

## Recent Code Changes

<!-- Updated by /memorise — most recent entries appear here -->

| Date | Summary |
|------|---------|
| _(none yet)_ | Run `/memorise` to begin capturing |

---

## Tag Index

- `#decision` — [[decisions]]
- `#pattern` — [[tech-stack]]
- `#domain` — [[industry]]
- `#preference` — [[preferences]]
- `#person` — [[people]]
- `#tech` — [[tech-stack]]

---

## How to Use

- Run `/memorise` (default: past 24h) to capture recent activity
- Run `/memorise 48h` for the past 48 hours
- Run `/memorise 7d` for the past 7 days
- Run `/memorise 2026-04-10` to capture since a specific date

_Memory is updated by Claude on demand. It is not automatic._
```

> **Note:** The `updated` field in frontmatter should be replaced with today's date when the template is first adopted. The `/memorise` skill updates this field automatically on each run.

- [ ] **Step 2: Commit**

```bash
git add memory/INDEX.md
git commit -m "feat: add memory/INDEX.md as Obsidian vault entry point"
```

---

## Task 4: Write Context Files

**Files:**
- Create: `memory/context/project.md`
- Create: `memory/context/industry.md`
- Create: `memory/context/tech-stack.md`
- Create: `memory/context/decisions.md`

- [ ] **Step 1: Create project.md**

Create `memory/context/project.md`:

```markdown
---
tags: [context, project]
updated: YYYY-MM-DD
related: ["[[INDEX]]", "[[tech-stack]]", "[[people]]"]
---

# Project Context

> [!note] Fill this in during the first `/memorise` run or manually at project start.

## What This Project Does

<!-- What problem does this project solve? Who uses it? -->
_Not yet captured._

## Goals

<!-- What are the primary objectives? -->
-

## Constraints

<!-- Technical, time, regulatory, or resource constraints -->
-

## Stakeholders

<!-- Who cares about this project? See also [[people]] -->
-

## Current Phase

<!-- e.g., MVP, scaling, maintenance, refactor -->
_Not yet captured._

## Open Questions

<!-- Things that are unresolved or need decisions -->
-
```

- [ ] **Step 2: Create industry.md**

Create `memory/context/industry.md`:

```markdown
---
tags: [context, domain]
updated: YYYY-MM-DD
related: ["[[INDEX]]", "[[project]]"]
---

# Industry & Domain Knowledge

> [!note] Knowledge captured from working on this project — terminology, business rules, domain patterns.

<!-- Entries are added by /memorise. Format:

## Term or Concept

**Source:** <where this was learned — commit, conversation, file>
**Date learned:** YYYY-MM-DD

<Explanation of what this means in this project's domain>

-->

_No domain knowledge captured yet. Run `/memorise` to begin._
```

- [ ] **Step 3: Create tech-stack.md**

Create `memory/context/tech-stack.md`:

```markdown
---
tags: [context, tech, pattern]
updated: YYYY-MM-DD
related: ["[[INDEX]]", "[[decisions]]"]
---

# Tech Stack & Conventions

> [!note] Languages, frameworks, tools, and coding conventions observed in this project.

## Languages & Runtimes

<!-- e.g., TypeScript 5.x, Python 3.12, Node 20 -->
_Not yet captured._

## Frameworks & Libraries

<!-- e.g., React 18, FastAPI, Prisma -->
_Not yet captured._

## Tooling

<!-- e.g., pnpm, ESLint, Prettier, pytest, Makefile targets -->
_Not yet captured._

## Conventions Observed

<!-- Patterns, naming styles, file organisation rules learned from the codebase -->

<!-- Format:
### Convention Name
**Observed in:** `path/to/file.ts`
<Description of the convention>
-->

_Not yet captured._

## Gotchas & Warnings

<!-- Things that are easy to get wrong in this codebase -->

> [!warning] _(none yet)_
```

- [ ] **Step 4: Create decisions.md**

Create `memory/context/decisions.md`:

```markdown
---
tags: [context, decision]
updated: YYYY-MM-DD
related: ["[[INDEX]]", "[[tech-stack]]"]
---

# Architectural & Design Decisions

> [!note] A log of decisions made during the project and the reasoning behind them.

<!-- Format for each entry:

## YYYY-MM-DD — Decision Title

> [!decision] One-line summary of what was decided

**Context:** What situation or problem prompted this decision?

**Options considered:**
- Option A — pros/cons
- Option B — pros/cons

**Decision:** What was chosen and why.

**Consequences:** What does this mean going forward? Any trade-offs accepted?

---
-->

_No decisions logged yet. Run `/memorise` to capture decisions from git history._
```

- [ ] **Step 5: Commit all context files**

```bash
git add memory/context/
git commit -m "feat: add memory context templates (project, industry, tech-stack, decisions)"
```

---

## Task 5: Write People and Preferences Files

**Files:**
- Create: `memory/people/people.md`
- Create: `memory/preferences/preferences.md`

- [ ] **Step 1: Create people.md**

Create `memory/people/people.md`:

```markdown
---
tags: [people, person]
updated: YYYY-MM-DD
related: ["[[INDEX]]", "[[project]]"]
---

# People

> [!note] Team members, stakeholders, and contributors encountered during this project.

<!-- Format for each person:

## Name (Handle or Role)

- **Role:** e.g., Lead Engineer, Product Owner, Client
- **Timezone / Location:** _(if known)_
- **Responsibilities:** What are they responsible for?
- **Notes:** Preferences, communication style, areas of expertise

---
-->

_No people logged yet._
```

- [ ] **Step 2: Create preferences.md**

Create `memory/preferences/preferences.md`:

```markdown
---
tags: [preferences, workflow]
updated: YYYY-MM-DD
related: ["[[INDEX]]", "[[tech-stack]]"]
---

# Coding & Workflow Preferences

> [!note] Preferences observed or stated during sessions — code style, tooling choices, workflow habits.

## Code Style

<!-- e.g., prefer functional over OOP, tabs vs spaces, line length -->
_Not yet captured._

## Workflow Preferences

<!-- e.g., prefers small PRs, runs tests before every commit, uses feature flags -->
_Not yet captured._

## Communication Preferences

<!-- e.g., prefers inline code comments over docs, wants commit messages to explain WHY -->
_Not yet captured._

## Things to Avoid

> [!warning] _(none yet)_

<!-- Patterns or approaches the team has explicitly rejected -->
```

- [ ] **Step 3: Commit**

```bash
git add memory/people/ memory/preferences/
git commit -m "feat: add memory people and preferences templates"
```

---

## Task 6: Write code-changes README

**Files:**
- Create: `memory/code-changes/README.md`

- [ ] **Step 1: Create README.md**

Create `memory/code-changes/README.md`:

```markdown
---
tags: [code-changes, schema]
updated: YYYY-MM-DD
---

# Code Changes — Schema Reference

Daily change logs live in this directory as `YYYY-MM-DD.md` files.
They are created automatically by the `/memorise` command.

---

## File Naming

```
YYYY-MM-DD.md
```

Each file covers one calendar day. If `/memorise` covers multiple days,
it creates or appends to each relevant day's file.

---

## Entry Schema

Each entry within a daily log follows this structure:

```markdown
## HH:MM — <commit-hash-7> <short description>

**Files changed:** `path/to/file.ts`, `path/to/other.ts`
**Commit:** `abc1234`
**Type:** feat | fix | refactor | chore | docs | test | style

### What changed
<1-3 sentences describing the change>

### Why
<Rationale from commit message or inferred from diff context>

### Learnings
<Any patterns, conventions, domain knowledge, or gotchas captured>

---
```

### Type Definitions

| Type | When to use |
|------|-------------|
| `feat` | New feature or capability added |
| `fix` | Bug or regression fixed |
| `refactor` | Code restructured without changing behaviour |
| `chore` | Build, config, dependency changes |
| `docs` | Documentation only |
| `test` | Test additions or changes |
| `style` | Formatting, naming, no logic change |

---

## Example Entry

```markdown
## 14:32 — a3f82bc Add user authentication middleware

**Files changed:** `src/middleware/auth.ts`, `src/routes/api.ts`
**Commit:** `a3f82bc`
**Type:** feat

### What changed
Added JWT validation middleware that sits in front of all `/api/*` routes.
Unauthenticated requests now receive a `401` with a `WWW-Authenticate` header.

### Why
The API was previously open — any client could call any endpoint.
This was the first step toward role-based access control (RBAC).

### Learnings
- This project uses `jose` (not `jsonwebtoken`) for JWT handling — different API
- Middleware is registered in `src/app.ts` via `app.use()`, not in individual route files
- The team tags security-related commits with `[security]` in the message

---
```
```

- [ ] **Step 2: Commit**

```bash
git add memory/code-changes/README.md
git commit -m "docs: add code-changes schema reference"
```

---

## Task 7: Write the /memorise Skill

**Files:**
- Create: `.claude/skills/memorise.md`

- [ ] **Step 1: Create memorise.md**

Create `.claude/skills/memorise.md`:

````markdown
---
name: memorise
description: >
  Mine git history and conversation context to update the project memory.
  Default timeframe: past 24 hours. Supports Xh (hours) and Xd (days) suffixes,
  or a specific date (YYYY-MM-DD).
trigger: /memorise
---

# /memorise Skill

Capture recent work into the project memory system.

## Invocation

```
/memorise           → past 24 hours
/memorise 48h       → past 48 hours
/memorise 7d        → past 7 days
/memorise 2026-04-10 → since a specific date (inclusive)
```

## Algorithm

Follow these steps in order. Do not skip steps.

### Step 1 — Parse Timeframe

Parse the argument passed to `/memorise`:
- No argument → `24h`
- `Xh` (e.g. `48h`) → X hours ago
- `Xd` (e.g. `7d`) → X × 24 hours ago
- `YYYY-MM-DD` → midnight of that date

Convert to a `git`-compatible `--since` value. Example:
- `24h` → `--since="24 hours ago"`
- `7d` → `--since="7 days ago"`
- `2026-04-10` → `--since="2026-04-10 00:00:00"`

### Step 2 — Check for Git Repository

```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

- If this returns `true`: proceed with git mining (Steps 3–5)
- If not a git repo: skip to Step 6 (conversation context only) and note this in the output

### Step 3 — List Commits in Timeframe

```bash
git log --since="<computed value>" --format="%H|%h|%ai|%s" --no-merges
```

This produces lines like:
```
a3f82bc1...|a3f82bc|2026-04-12 14:32:00 +0000|Add user authentication middleware
```

If no commits are found: output "No commits found in the past <timeframe>." and skip to Step 6.

### Step 4 — Read Diffs for Each Commit

For each commit hash from Step 3:

```bash
git show <hash> --stat --format="%B"
```

Extract:
- Files changed (from `--stat` output)
- Commit message body (the "why")
- Summary of what was touched

Do NOT read full diffs unless the commit stat shows fewer than 20 changed files. For large commits, work from the stat summary only.

### Step 5 — Build Change Entries

For each commit, construct a change entry using the schema from `memory/code-changes/README.md`:

```markdown
## HH:MM — <commit-hash-7> <commit subject>

**Files changed:** `path/to/file`, `path/to/other`
**Commit:** `<hash>`
**Type:** <inferred from commit prefix or message content>

### What changed
<1-3 sentences — what the diff or stat tells you was done>

### Why
<From commit message body, or inferred if the message is terse>

### Learnings
<Any patterns, domain terms, new tools, conventions observed>

---
```

Group entries by calendar date. If multiple commits share a date, they go in the same file.

### Step 6 — Update memory/code-changes/YYYY-MM-DD.md

For each date that has new entries:

1. Check if `memory/code-changes/YYYY-MM-DD.md` exists
2. If not: create it with this header:
   ```markdown
   ---
   tags: [code-changes]
   date: YYYY-MM-DD
   updated: YYYY-MM-DD
   ---

   # Code Changes — YYYY-MM-DD
   ```
3. Append new entries (do not duplicate existing entries — check if the commit hash already appears in the file)

### Step 7 — Update Context Files

After processing all commits, review the learnings you extracted and update context files where appropriate:

**`memory/context/decisions.md`** — Add an entry for any commit that:
- Introduced or removed a major dependency
- Changed an architectural pattern (e.g., switched from REST to GraphQL)
- Explicitly mentions a decision in the commit message ("decided to", "chose X over Y", "replaced")

**`memory/context/tech-stack.md`** — Add/update entries for any:
- New framework, library, or tool observed in changed files
- New convention observed (file naming, import style, error handling pattern)
- New tooling observed (new Makefile target, new CLI tool used)

**`memory/context/industry.md`** — Add entries for any:
- Domain-specific terms that appear in commit messages or file names
- Business rules encoded in the changes
- External systems or APIs referenced

### Step 8 — Update INDEX.md Recent Changes Table

Open `memory/INDEX.md` and update the "Recent Code Changes" table:

Replace the existing table content with the most recent 5 dated entries (newest first):

```markdown
| Date | Summary |
|------|---------|
| [[2026-04-13]] | Added auth middleware, fixed login redirect |
| [[2026-04-12]] | Refactored database layer to use connection pooling |
| ... | ... |
```

Also update the `updated` frontmatter field to today's date.

### Step 9 — Report

Output a brief summary in this format:

```
/memorise complete — <timeframe>

Commits processed: N
Files updated:
  - memory/code-changes/YYYY-MM-DD.md  (+N entries)
  - memory/context/decisions.md        (+N entries)
  - memory/context/tech-stack.md       (+N entries)
  - memory/INDEX.md                    (updated)

No git repo found: <only if Step 2 failed>
Skipped (already captured): <list any commit hashes already present>
```

## Error Handling

| Situation | Action |
|-----------|--------|
| No git repo | Capture from conversation context only; note in report |
| No commits in timeframe | Report "nothing new"; do not modify files |
| Commit already in file | Skip it; list in "Skipped" section of report |
| Memory file missing | Create it from the template in this file |
| Very large diff (>20 files) | Use `--stat` summary only; note in entry |
````

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/memorise.md
git commit -m "feat: add /memorise skill for on-demand memory capture"
```

---

## Task 8: Write the Adoption README

**Files:**
- Create: `README.md`

- [ ] **Step 1: Create README.md**

Create `README.md`:

```markdown
# Persistent Memory System

A portable, Obsidian-compatible memory system for Claude-assisted projects.
Copy this folder structure into any project so Claude can remember what it has done
and what it has learned about your project and industry.

---

## What This Does

- **Logs code changes** — what was done, why, and what was learned
- **Captures project context** — goals, constraints, stakeholders, tech stack
- **Records decisions** — architectural choices with reasoning
- **Tracks domain knowledge** — industry terms and business rules learned during work
- **Works in Obsidian** — YAML frontmatter, wikilinks, callouts, tag index

---

## Adopting This in Your Project

### 1. Copy the folders

```bash
cp -r memory/ /path/to/your/project/
cp CLAUDE.md /path/to/your/project/CLAUDE.md
mkdir -p /path/to/your/project/.claude/skills
cp .claude/skills/memorise.md /path/to/your/project/.claude/skills/
```

If your project already has a `CLAUDE.md`, append the contents of this one to it.

### 2. Initialise

Open Claude Code in your project and run:

```
/memorise
```

Claude will scan the past 24 hours of git history and populate the memory files.

### 3. Use It

```
/memorise          # capture past 24 hours (default)
/memorise 48h      # capture past 48 hours
/memorise 7d       # capture past 7 days
/memorise 2026-04-01  # capture since a specific date
```

---

## Directory Structure

```
memory/
├── INDEX.md                  ← Obsidian vault home page
├── code-changes/
│   ├── README.md             ← Entry schema reference
│   └── YYYY-MM-DD.md         ← Daily logs (created by /memorise)
├── context/
│   ├── project.md            ← Project goals and constraints
│   ├── industry.md           ← Domain knowledge learned
│   ├── tech-stack.md         ← Languages, frameworks, conventions
│   └── decisions.md          ← Architectural decision log
├── people/
│   └── people.md             ← Team and stakeholders
└── preferences/
    └── preferences.md        ← Coding and workflow preferences
```

---

## Opening in Obsidian

Point Obsidian's vault at either:
- The project root (if you want the whole project as a vault)
- The `memory/` subdirectory (for a focused memory-only vault)

All wikilinks, tags, and callouts work natively in Obsidian.

---

## Requirements

- Claude Code (any version with skills support)
- Git (for history mining — gracefully skipped if absent)
- Obsidian (optional, for visual navigation)

No npm, no Python, no external services.
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add adoption README for memory system template"
```

---

## Task 9: Initialise Git and Final Verification

- [ ] **Step 1: Verify complete structure**

```bash
find . -not -path './.git/*' | sort
```

Expected:
```
.
./CLAUDE.md
./.claude
./.claude/skills
./.claude/skills/memorise.md
./docs
./docs/superpowers
./docs/superpowers/plans
./docs/superpowers/plans/2026-04-13-memory-system.md
./docs/superpowers/specs
./docs/superpowers/specs/2026-04-13-memory-system-design.md
./memory
./memory/INDEX.md
./memory/code-changes
./memory/code-changes/.gitkeep
./memory/code-changes/README.md
./memory/context
./memory/context/decisions.md
./memory/context/industry.md
./memory/context/project.md
./memory/context/tech-stack.md
./memory/people
./memory/people/people.md
./memory/preferences
./memory/preferences/preferences.md
./README.md
```

- [ ] **Step 2: Verify CLAUDE.md is present and references the skill**

```bash
grep -c "memorise" CLAUDE.md
```

Expected: `1` or higher

- [ ] **Step 3: Verify skill file has correct trigger**

```bash
grep "trigger:" .claude/skills/memorise.md
```

Expected: `trigger: /memorise`

- [ ] **Step 4: Final commit**

```bash
git add -A
git status
# Confirm nothing untracked or modified
git log --oneline
```

Expected: 7–9 commits visible, all with descriptive messages.

---

## Self-Review Notes

- All spec requirements covered: portability ✓, Obsidian ✓, `/memorise` command ✓, timeframe argument ✓, git history mining ✓, context categories ✓
- No TBD or TODO placeholders in skill file — all steps are complete
- `memorise.md` skill uses exact same entry schema as `code-changes/README.md` — consistent
- Wikilinks in INDEX.md reference filenames without `.md` extension (Obsidian convention) ✓
