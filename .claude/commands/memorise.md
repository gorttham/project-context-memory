Mine recent work into the project memory system.

Timeframe argument: $ARGUMENTS (default: 24h if empty)

Follow these steps exactly:

## Step 1 — Parse Timeframe

Use the value of $ARGUMENTS:
- Empty → treat as `24h`
- `Xh` (e.g. `48h`) → X hours ago
- `Xd` (e.g. `7d`) → X days ago
- `YYYY-MM-DD` → since midnight of that date

Convert to git `--since` format:
- `24h` → `--since="24 hours ago"`
- `7d` → `--since="7 days ago"`
- `2026-04-10` → `--since="2026-04-10 00:00:00"`

## Step 2 — Check for Git Repository

Run:
```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

- Returns `true` → proceed with Steps 3–5
- Not a git repo → skip to Step 6, note this in final report

## Step 3 — List Commits in Timeframe

Run:
```bash
git log --since="<computed value>" --format="%H|%h|%ai|%s" --no-merges
```

If no commits found: report "No commits found in the past <timeframe>." and skip to Step 6.

## Step 4 — Read Each Commit

For each commit hash:
```bash
git show <hash> --stat --format="%B"
```

Extract: files changed, commit message body, what was touched.
For commits with >20 files changed, use the stat summary only (do not read full diff).

## Step 5 — Build Change Entries

For each commit, build this entry:

```markdown
## HH:MM — <hash-7> <commit subject>

**Files changed:** `path/to/file`, `path/to/other`
**Commit:** `<hash>`
**Type:** feat | fix | refactor | chore | docs | test | style

### What changed
<1-3 sentences on what was done>

### Why
<From the commit message body, or inferred if terse>

### Learnings
<Patterns, domain terms, conventions, or tools observed>

---
```

Group entries by calendar date.

## Step 6 — Write to memory/code-changes/YYYY-MM-DD.md

For each date with new entries:

1. If `memory/code-changes/YYYY-MM-DD.md` does not exist, create it:

```markdown
---
tags: [code-changes]
date: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Code Changes — YYYY-MM-DD
```

2. Append the new entries.
3. Skip any commit hash already present in the file (no duplicates).

## Step 7 — Update Context Files

Review the learnings from all entries and update where relevant:

- **memory/context/decisions.md** — any commit that introduced/removed a major dependency, changed architecture, or used words like "decided", "chose", "replaced"
- **memory/context/tech-stack.md** — any new tool, library, framework, naming convention, or file pattern observed
- **memory/context/industry.md** — any domain-specific term, business rule, or external API referenced

## Step 8 — Update memory/INDEX.md

Update the "Recent Code Changes" table with the 5 most recent dated entries (newest first):

```markdown
| Date | Summary |
|------|---------|
| [[YYYY-MM-DD]] | <one-line summary of changes that day> |
```

Update the `updated` frontmatter field to today's date.

## Step 9 — Update memory/CHANGELOG.md

Prepend a new entry to `memory/CHANGELOG.md` immediately above the `<!-- /memorise appends new entries above this line -->` comment:

```markdown
## YYYY-MM-DD HH:MM — `/memorise <argument>`

**Timeframe:** <parsed timeframe, e.g. "last 24 hours">
**Commits processed:** N
**Files updated:**
- `memory/code-changes/YYYY-MM-DD.md` — +N entries
- `memory/context/decisions.md` — +N entries  _(omit if none)_
- `memory/context/tech-stack.md` — +N entries  _(omit if none)_
- `memory/context/industry.md` — +N entries  _(omit if none)_
- `memory/INDEX.md` — updated

**Skipped (already captured):** <commit hashes, or "none">
**Note:** <"No git repo — conversation context only" if applicable, otherwise omit>

---
```

Also update the `updated` frontmatter field in `memory/CHANGELOG.md` to today's date.

## Step 10 — Report

Output:

```
/memorise complete — <timeframe>

Commits processed: N
Files updated:
  - memory/code-changes/YYYY-MM-DD.md  (+N entries)
  - memory/context/decisions.md        (+N entries)
  - memory/context/tech-stack.md       (+N entries)
  - memory/INDEX.md                    (updated)
  - memory/CHANGELOG.md                (logged)

Skipped (already captured): <hashes if any>
No git repo: <note if applicable>
```

## Error Handling

| Situation | Action |
|-----------|--------|
| No git repo | Capture from conversation context only |
| No commits in timeframe | Report "nothing new"; do not modify files |
| Commit already in file | Skip; list in Skipped section |
| Memory file missing | Create from the template above |
| Diff >20 files | Use stat summary only |
