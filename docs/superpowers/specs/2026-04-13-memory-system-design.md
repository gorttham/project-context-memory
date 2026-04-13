# Memory System Design

**Date:** 2026-04-13
**Status:** Approved
**Author:** Claude Sonnet 4.6

---

## Overview

A portable, Obsidian-compatible persistent memory system that any Claude-assisted project can adopt by copying a folder structure. Memory is populated on demand via the `/memorise` slash command, which mines git history and conversation context to log code changes and capture project/industry learnings.

---

## Goals

- Log what has been done to the code (changes, decisions, rationale)
- Capture project and industry context learned during sessions
- Be fully readable in Obsidian (YAML frontmatter, wikilinks, callouts)
- Be activatable on demand via `/memorise [Xh|Xd]` (default: 24h)
- Require zero external dependencies — pure markdown files

---

## Non-Goals

- Real-time automatic capture (requires explicit `/memorise` invocation)
- Storing secrets, credentials, or sensitive data
- Replacing git history (complements it, does not duplicate it)

---

## File Structure

```
<project-root>/
├── CLAUDE.md                        # Claude session instructions
└── memory/
    ├── INDEX.md                     # Obsidian vault entry point
    ├── code-changes/
    │   ├── README.md                # Schema for change log entries
    │   └── YYYY-MM-DD.md            # Auto-generated daily logs
    ├── context/
    │   ├── project.md               # Project goals, constraints, stakeholders
    │   ├── industry.md              # Domain/industry knowledge learned
    │   ├── tech-stack.md            # Languages, frameworks, conventions
    │   └── decisions.md             # Architectural and design decisions
    ├── people/
    │   └── people.md                # Team members, stakeholders, contributors
    └── preferences/
        └── preferences.md           # Coding style and workflow preferences
```

The `.claude/skills/memorise.md` file (placed at the project root under `.claude/`) defines the `/memorise` command and is loaded by Claude Code's skill system.

---

## CLAUDE.md Behaviour

At session start, Claude reads the following in order:
1. `memory/INDEX.md` — to get the lay of the land
2. `memory/context/project.md` — to understand what the project is
3. `memory/context/tech-stack.md` — to understand conventions
4. `memory/code-changes/` (most recent file) — to pick up where things left off

At session end (or when `/memorise` is invoked), Claude updates the relevant files.

---

## /memorise Command

### Invocation

```
/memorise          # default: past 24 hours
/memorise 48h      # past 48 hours
/memorise 7d       # past 7 days
/memorise 2026-04-10  # since a specific date
```

### Algorithm

1. **Parse timeframe** from argument (default `24h`)
2. **Mine git history**: `git log --since="X" --stat` to list commits and changed files
3. **Read diffs**: `git diff HEAD~N HEAD` for each relevant commit
4. **Extract structured data**:
   - What files changed and why (from commit messages)
   - Patterns and conventions observed
   - Decisions made (refactors, architectural choices)
   - Domain/industry terms encountered
5. **Update memory files**:
   - Append to `memory/code-changes/YYYY-MM-DD.md`
   - Update `memory/context/decisions.md` with any decision entries
   - Update `memory/context/tech-stack.md` with new patterns/tools
   - Update `memory/context/industry.md` with domain knowledge
   - Refresh `memory/INDEX.md` wikilinks
6. **Report**: Brief summary of what was captured

### Output Entry Schema (code-changes)

Each entry in `code-changes/YYYY-MM-DD.md` follows this structure:

```markdown
## HH:MM — <commit-hash-short> <short description>

**Files changed:** `path/to/file.ts`, `path/to/other.ts`
**Type:** feat | fix | refactor | chore | docs

### What changed
<1-3 sentences on what was done>

### Why
<Rationale from commit message or inferred context>

### Learnings
<Any patterns, conventions, or domain knowledge captured>

---
```

---

## Obsidian Compatibility

All files use:

- **YAML frontmatter**: `tags`, `updated`, `related` fields
- **Wikilinks**: `[[file-name]]` cross-references between memory files
- **Callout blocks**: `> [!note]`, `> [!warning]`, `> [!tip]` for highlights
- **Dataview-ready tags**: consistent tag taxonomy (e.g., `#decision`, `#pattern`, `#domain`)

`INDEX.md` acts as the vault home page with:
- Tag cloud
- Links to all sections
- Recent changes list (auto-updated by `/memorise`)

---

## Error Handling

- If no git repo exists: skip git mining, capture from conversation context only
- If no changes in timeframe: report "nothing new to capture" and exit cleanly
- If a memory file doesn't exist yet: create it from the template

---

## Portability

To adopt this system in any project:
1. Copy `memory/` folder to project root
2. Copy (or merge) `CLAUDE.md` into the project's existing `CLAUDE.md`
3. Copy `.claude/skills/memorise.md` to the project's `.claude/skills/`
4. Run `/memorise` to begin capturing

No npm install, no Python env, no external services required.

---

## Future Considerations (out of scope for v1)

- Auto-capture hook on Claude session end (requires hook infrastructure)
- Semantic search across memory files
- Cross-project memory linking
