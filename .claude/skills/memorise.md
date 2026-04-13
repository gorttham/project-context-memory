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

Convert to a `git`-compatible `--since` value:
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

Do NOT read full diffs unless the commit stat shows fewer than 20 changed files.
For large commits, work from the stat summary only.

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

3. Append new entries (do not duplicate — check if the commit hash already appears in the file)

### Step 7 — Update Context Files

After processing all commits, review the learnings extracted and update context files where appropriate:

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

Open `memory/INDEX.md` and update the "Recent Code Changes" table.

Replace the existing table content with the most recent 5 dated entries (newest first):

```markdown
| Date | Summary |
|------|---------|
| [[2026-04-13]] | Added auth middleware, fixed login redirect |
| [[2026-04-12]] | Refactored database layer to use connection pooling |
```

Also update the `updated` frontmatter field to today's date.

### Step 9 — Report

Output a brief summary:

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

---

## Error Handling

| Situation | Action |
|-----------|--------|
| No git repo | Capture from conversation context only; note in report |
| No commits in timeframe | Report "nothing new"; do not modify files |
| Commit already in file | Skip it; list in "Skipped" section of report |
| Memory file missing | Create it from the template above |
| Very large diff (>20 files) | Use `--stat` summary only; note in entry |
