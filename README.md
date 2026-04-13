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

The `.claude/skills/memorise.md` file powers the `/memorise` command.
The `CLAUDE.md` file tells Claude to read memory at the start of every session.

---

## Opening in Obsidian

Point Obsidian's vault at either:
- The project root (if you want the whole project as a vault)
- The `memory/` subdirectory (for a focused memory-only vault)

All wikilinks, tags, and callouts work natively in Obsidian.

---

## How /memorise Works

1. Parses your timeframe argument (default: past 24h)
2. Runs `git log --since="..."` to list commits and changed files
3. Reads each commit's stat and message
4. Writes structured entries to `memory/code-changes/YYYY-MM-DD.md`
5. Updates `memory/context/` files with decisions, tech patterns, domain knowledge
6. Refreshes `memory/INDEX.md` with recent change summaries

If there's no git repo, it captures from the conversation context instead.

---

## Requirements

- Claude Code (any version with skills support)
- Git (for history mining — gracefully skipped if absent)
- Obsidian (optional, for visual navigation)

No npm, no Python, no external services.
