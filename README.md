# Persistent Memory System

Give Claude a memory that outlasts sessions — and grows smarter the longer you use it.

---

## The Problem

Every time you open a new Claude Code session, Claude starts fresh. It doesn't know your codebase conventions, the decisions you made last sprint, or the business rules your team has built up over months. You end up re-explaining the same context, over and over.

This system fixes that. It stores project knowledge as plain markdown files in your repo — readable by Claude at session start, browsable in Obsidian, trackable in git, shareable with your team.

---

## How It Works

### Where information comes from

**1. Your git history** — When you run `/memorise`, Claude reads your recent commits, extracts what changed and why, and writes structured entries to `memory/code-changes/`. It also updates `memory/context/` with any decisions, new tools, or domain terms it spots in commit messages and diffs.

**2. Your conversation** — At the same time, `/memorise` reviews what was discussed in the current session and captures anything that doesn't show up in git: business rules you explained, tradeoffs you talked through, gotchas you surfaced. The conversation is already in Claude's context — no notes needed during the session.

> **Important:** conversation capture only works if you run `/memorise` before closing the terminal. Once a session ends, the conversation is gone. Git history is always available regardless — so if you forget to run `/memorise`, the code changes are still captured next time you run it. Only the spoken context from that session is lost.

**3. Your codebase** — On the very first `/memorise` run, Claude scans your project root (package.json, go.mod, pyproject.toml, etc.) and README to pre-populate `tech-stack.md` and `project.md`. You get a head start instead of blank files.

### What gets stored

```
memory/
├── INDEX.md                  ← Obsidian vault home, links to everything
├── code-changes/
│   └── YYYY-MM-DD.md         ← Daily log: what changed, why, what was learned
├── context/
│   ├── project.md            ← Project goals and constraints
│   ├── industry.md           ← Domain knowledge and business rules
│   ├── tech-stack.md         ← Languages, frameworks, conventions
│   └── decisions.md          ← Architectural decisions with reasoning
├── people/
│   └── people.md             ← Team and stakeholders
└── preferences/
    └── preferences.md        ← Coding and workflow preferences
```

All files are plain markdown. No database, no external services — just files you can read, edit, and commit.

### How Claude uses it

At the start of every session, Claude reads `memory/INDEX.md`, `memory/context/project.md`, `memory/context/tech-stack.md`, and the most recent code-changes log. That's how it restores context without you having to explain anything.

> **How is this different from Claude's built-in memory?**
> Claude Code's built-in memory stores personal preferences across all your projects — it's per-user, not shareable. This system is *project-level*: it captures decisions, domain knowledge, and code history tied to a specific repo, committed to git so your whole team benefits.

---

## Install

Navigate to your project root, then run:

```bash
npx github:gorttham/project-context-memory
```

The installer adds the memory files and the `/memorise` command to your project. It never overwrites files that already exist, and it appends to your `CLAUDE.md` rather than replacing it.

> **Requires Node.js 16+.** Works on macOS, Linux, and Windows natively.

### Alternative: curl (no Node.js required)

```bash
# Clone the template somewhere outside your project
git clone https://github.com/gorttham/project-context-memory.git ~/memory-template

# Navigate to your project root
cd /path/to/your/project

# Run the installer
bash ~/memory-template/install.sh .
```

> macOS and Linux only. Windows requires WSL or Git Bash.

---

## Usage

```
/memorise          # capture the past 24 hours (default)
/memorise 48h      # capture the past 48 hours
/memorise 7d       # capture the past 7 days
/memorise 2026-04-01  # capture since a specific date
```

Run it before closing your terminal — that's when both sources are available. Claude will mine your git history and review the current conversation, then update the memory files. If you only have git commits (no conversation to capture), that's still useful — just run it next session.

---

## Verifying the Installation

```bash
bash tests/verify.sh
```

37 checks: required files present, CLAUDE.md correctly configured, valid Obsidian frontmatter, entry schema in place, git repo detected.

---

## Opening in Obsidian

Point Obsidian's vault at either:
- `memory/` — focused, memory-only vault
- Your project root — whole project as a vault

All wikilinks, callouts, and tags work natively.

---

## Updating

When a new version releases:

```bash
npx github:gorttham/project-context-memory --update
```

Refreshes only `.claude/commands/memorise.md` and `tests/verify.sh`. Never touches your `memory/` files. If you've customised `memorise.md` locally, it will show you a diff before asking whether to overwrite.

### Re-running the codebase scan

To re-detect your tech stack after a major change:

```bash
rm memory/.memory-version
```

The next `/memorise` run will re-scan and re-populate `tech-stack.md` and `project.md`.

---

## Removing

```bash
rm -rf memory/
rm .claude/commands/memorise.md
rm tests/verify.sh
# Open CLAUDE.md and delete from "## Memory System" to the end of that section
```

---

## Requirements

- Claude Code (any version with slash command support)
- Node.js 16+ (for the npx installer — not needed after install)
- Git (for history mining — gracefully skipped if absent)
- Obsidian (optional, for visual navigation)
