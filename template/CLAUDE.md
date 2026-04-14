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

### On /memorise Invocation

The `/memorise` command is defined in `.claude/commands/memorise.md`.
When invoked, follow the instructions exactly. `/memorise` handles all capture
retrospectively — reviewing git history and the current conversation to extract
decisions, domain knowledge, and conventions. No tracking is needed during the session.

### Memory File Conventions

- All files use YAML frontmatter (`tags`, `updated`, `related`)
- Cross-reference with `[[wikilinks]]` between memory files
- Use callout blocks for highlights:
  - `> [!note]` — general notes
  - `> [!warning]` — things to be careful about
  - `> [!tip]` — useful patterns or shortcuts
  - `> [!decision]` — architectural/design decisions
- Tag vocabulary: `#decision`, `#pattern`, `#domain`, `#preference`, `#person`, `#tech`
