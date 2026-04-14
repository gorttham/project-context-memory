Mine recent work into the project memory system.

Timeframe argument: $ARGUMENTS (default: 24h if empty)

Follow these steps exactly:

## Step 0 — First-Run Codebase Scan

Check whether this is the first time `/memorise` has been run in this project.

**Detection (two-layer):**

1. Check if `memory/.memory-version` exists.
   - If it exists: skip Step 0 entirely and proceed to Step 1.
2. If the sentinel is absent, check whether all context files contain only placeholder text:
   - Read `memory/context/tech-stack.md`, `memory/context/project.md`, `memory/context/industry.md`, `memory/context/decisions.md`
   - If ANY file contains content beyond `_Not yet captured._` stubs: skip Step 0 (project already has custom content).
   - If ALL files are placeholder-only: this is a first run — proceed with the scan below.

**Scan procedure:**

### 0a. Detect tech stack

Check for the following files in the project root (use the Read tool — do not run shell commands):

| File | What to extract |
|------|----------------|
| `package.json` | `name`, `description`, `dependencies` (fall back to `devDependencies` if empty) |
| `pyproject.toml` | project name, `[tool.poetry.dependencies]` or `[project.dependencies]` |
| `requirements.txt` | top 5 packages by line order |
| `go.mod` | module name, Go version |
| `Cargo.toml` | `[package]` name, `[dependencies]` |
| `Gemfile` | `gem` entries (top 5) |
| `pom.xml` | `<artifactId>`, `<groupId>`, key `<dependency>` entries |
| `build.gradle` | project name, `dependencies {}` block (top 5) |
| `*.csproj` | `<RootNamespace>`, `<PackageReference>` entries |

Read whichever files are present. Stop after the first match per ecosystem (don't double-count `package.json` + `pyproject.toml` as two separate stacks unless both are genuinely present).

### 0b. Extract README description

Try `README.md` first, then `README.rst`, then `README.txt`, then `README`.

- Read the file.
- Find the first H2 heading (`## ` in markdown, or a line of `=====` underline in RST).
- Take everything before that heading as the project description.
- If no H2 exists: take the first 10 lines.
- If the first H2 appears within the first 3 lines (no description before it): take 10 lines after the H2.
- If no README exists: leave the description blank.

### 0c. Write to memory files

**Update `memory/context/tech-stack.md`:**

Replace `_Not yet captured._` in the relevant sections:
- **Languages & Runtimes**: primary language + version if detectable
- **Frameworks & Libraries**: top dependencies from detected package file
- **Dependencies**: key entries with what they're used for (infer from package name if not documented)

Do not overwrite existing content — only replace placeholder stubs.

**Update `memory/context/project.md`:**

Replace `_Not yet captured._` in:
- **What This Project Does**: project description extracted from README (or package.json `description` field)

If `package.json` has a `name` field, use it to set the project name in the H1 heading or a note at the top.

### 0d. Write sentinel

After the scan completes (even if some files had no content to extract), write:

```
memory/.memory-version
```

Contents: the single line `v1.0` (or the version from `memory/.memory-version` in the template if present — this lets future updates detect version drift).

**Recovery note (for the developer):** If the scan ran but produced incorrect results, delete `memory/.memory-version` and run `/memorise` again to re-trigger the scan.

---

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

## Step 7 — Update Context Files from Git

Review the learnings from all commit entries and update where relevant:

- **memory/context/decisions.md** — any commit that introduced/removed a major dependency, changed architecture, or used words like "decided", "chose", "replaced"
- **memory/context/tech-stack.md** — any new tool, library, framework, naming convention, or file pattern observed
- **memory/context/industry.md** — any domain-specific term, business rule, or external API referenced

## Step 7b — Capture from Previous Sessions (JSONL)

Claude Code saves every conversation to disk. This step reads those files to capture
domain knowledge from sessions where `/memorise` was not run before closing — so
nothing is lost even if the terminal was closed unexpectedly.

### 7b-i. Find the session directory

Run:
```bash
git rev-parse --show-toplevel 2>/dev/null || pwd
```

Take the output path and compute the Claude project directory name:
- Replace every `:` with `-`
- Replace every `\` and `/` with `-`
- Remove any leading `-`

Examples:
- `C:\Users\Gordon\Desktop\myapp` → `C--Users-Gordon-Desktop-myapp`
- `/Users/gordon/projects/myapp` → `Users-gordon-projects-myapp`

Look for this directory under `~/.claude/projects/`. If it does not exist, skip this
step entirely.

### 7b-ii. Load the already-processed session list

Read `memory/.memorise-sessions` if it exists. This file contains one session UUID
per line — sessions already captured in a previous `/memorise` run. Skip any JSONL
file whose filename (without `.jsonl`) appears in this list.

### 7b-iii. Find JSONL files within the timeframe

List all `*.jsonl` files in the session directory. Filter to files whose last-modified
time falls within the `/memorise` timeframe (same window used for git log in Step 3).

```bash
find ~/.claude/projects/<hash> -name "*.jsonl" -newer /tmp/memorise-since-ref
```

To create the reference file for `-newer`:
```bash
touch -t <YYYYMMDDHHMI> /tmp/memorise-since-ref
```

Skip files already in the processed list from 7b-ii.

### 7b-iv. Extract human messages

For each qualifying JSONL file, read it line by line. Parse each line as JSON.
Keep only lines where:
- `"type": "user"` AND
- `message.content` is a plain string (not an array — arrays contain tool results
  and file pastes, not natural language) AND
- `message.content` length is at least 30 characters (skip short replies like
  "yes", "ok", "do it", "push it")

Collect all matching `message.content` strings from all qualifying files, grouped
by session (filename = session UUID).

### 7b-v. Extract knowledge

Review the collected messages for knowledge that does not appear in git commits.
Look for:

- **Decisions:** explicit choice language — "we decided", "let's use X",
  "switching to Y", "don't do Z because", "the rule is", "we agreed"
- **Domain knowledge:** explanations of business concepts, industry terms, how
  the system works ("in our system, X means...", "users do Y when Z")
- **Constraints:** things ruled out, tradeoffs accepted, hard limits mentioned
- **Gotchas:** edge cases surfaced, things that surprised you, "watch out for"

**What to skip:** general coding questions, one-word acknowledgements, anything
already captured from git commits in Step 7, anything already in the memory files.

### 7b-vi. Write to context files

Append new entries to the relevant context file:

```markdown
### YYYY-MM-DD — <short title> #decision
**Source:** session <first-8-chars-of-session-uuid>
**Decision:** <what was decided>
**Reason:** <why, in the user's own words if possible>
```

Use `source: session <uuid-prefix>` so entries are traceable back to the raw JSONL
if needed. Write to `decisions.md`, `industry.md`, or `tech-stack.md` as appropriate.

If nothing meaningful was found across all sessions, skip and note
"no session captures" in the report.

### 7b-vii. Mark sessions as processed

Append each successfully-processed session UUID (one per line) to
`memory/.memorise-sessions`. Create the file if it does not exist.

This prevents double-capture on future `/memorise` runs.

## Step 7c — Capture from Current Conversation

Review the current conversation (everything exchanged in this session) for knowledge
not already captured in Steps 7 or 7b. Apply the same extraction criteria as Step
7b-v above.

Write entries tagged `source: conversation` (no session UUID — current session is
not yet in the JSONL files).

If nothing meaningful was said beyond the code work, skip this step entirely and
note "no conversation captures" in the report.

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
**Sessions scanned:** N  _(omit if none found)_
**Session captures:** N  _(omit if none)_
**Conversation captures:** N  _(omit if none)_
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
| No git repo | Skip Steps 2–7, proceed with session capture (7b) and conversation capture (7c) |
| No Claude session directory found | Skip Step 7b, continue with 7c |
| No commits in timeframe | Report "nothing new"; do not modify files |
| Commit already in file | Skip; list in Skipped section |
| Memory file missing | Create from the template above |
| Diff >20 files | Use stat summary only |
