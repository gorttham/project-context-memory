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

> **How is this different from Claude's built-in memory?**
> Claude Code's auto-memory stores user-level preferences and conversation history — it's personal, not shareable. This system is *project-level*: it logs code changes tied to git commits, captures architectural decisions, and lives in your repo so your whole team benefits. Both systems complement each other.

---

## Adopting This in Your Project

Navigate to your project root, then run:

```bash
npx github:gorttham/project-context-memory
```

That's it. The installer:
- Copies `memory/` into your project (skips if already present)
- Copies `.claude/commands/memorise.md` (skips if already present)
- **Appends** the memory instructions to your existing `CLAUDE.md` — never overwrites
- Copies `tests/verify.sh` so you can check the install
- Runs all 37 verification checks automatically

> **Requirements:** Node.js 16+ (for npx). On Windows, this works natively — no WSL needed.

### Use It

```
/memorise          # capture past 24 hours (default)
/memorise 48h      # capture past 48 hours
/memorise 7d       # capture past 7 days
/memorise 2026-04-01  # capture since a specific date
```

On first run, `/memorise` scans your project root to detect the tech stack and project description, so `memory/context/tech-stack.md` and `memory/context/project.md` are pre-populated — never blank.

### Alternative: curl (no Node.js required)

For teams without Node.js (Go, Ruby, Python-only shops), or if you prefer to avoid npm:

```bash
# 1. Clone the template somewhere outside your project
git clone https://github.com/gorttham/project-context-memory.git ~/memory-template

# 2. Navigate to your project root
cd /path/to/your/project

# 3. Run the installer
bash ~/memory-template/install.sh .
```

> **macOS/Linux only.** Windows users need WSL or Git Bash for the shell installer.

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

The `.claude/commands/memorise.md` file powers the `/memorise` command.
The `CLAUDE.md` file tells Claude to read memory at the start of every session.

---

## Verifying the Installation

After copying the template into a project, run the verification script to confirm everything is correctly installed:

```bash
bash tests/verify.sh
```

This checks:
- All required files are present
- `CLAUDE.md` references the memory system and `/memorise`
- The `/memorise` command accepts `$ARGUMENTS` for timeframe
- Every memory file has valid Obsidian YAML frontmatter
- `INDEX.md` has all required sections and wikilinks
- `code-changes/README.md` has the full entry schema
- Whether a git repo is present (optional but recommended)

**37 checks, all green = ready to use.**

Copy the `tests/` folder alongside the rest of the template when adopting into a new project.

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

## Updating the Template

When a new version releases with improvements to `/memorise` or the verification checks:

```bash
npx github:gorttham/project-context-memory --update
```

This refreshes only `.claude/commands/memorise.md` and `tests/verify.sh`. It never touches your `memory/` files or `CLAUDE.md`. If you've made local changes to `memorise.md`, it will show you a diff before asking whether to overwrite.

### Resetting the first-run scan

If you want to re-run the codebase auto-detection (e.g. after a major stack change):

```bash
rm memory/.memory-version
```

The next `/memorise` run will re-scan your project root and re-populate `tech-stack.md` and `project.md`.

### Alternative: manual update (curl install)

```bash
cd ~/memory-template
git pull
bash ~/memory-template/install.sh --update /path/to/your/project
```

---

## Removing the Memory System

To fully remove this from a project:

```bash
# Remove the memory files
rm -rf memory/

# Remove the memorise command
rm .claude/commands/memorise.md

# Remove the verification script (if you installed it)
rm tests/verify.sh

# Remove the memory block from CLAUDE.md
# Open CLAUDE.md and delete everything from "## Memory System" to the end
# (or the next section if you added your own content after it)
```

---

## Requirements

- Claude Code (any version with slash command support)
- Git (for history mining — gracefully skipped if absent)
- Obsidian (optional, for visual navigation)

No npm, no Python, no external services.
