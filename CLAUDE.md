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
