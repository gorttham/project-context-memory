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

The `/memorise` command is defined in `.claude/commands/memorise.md`.
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

## Skill routing

When the user's request matches an available skill, ALWAYS invoke it using the Skill
tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.
The skill has specialized workflows that produce better results than ad-hoc answers.

Key routing rules:
- Product ideas, "is this worth building", brainstorming → invoke office-hours
- Bugs, errors, "why is this broken", 500 errors → invoke investigate
- Ship, deploy, push, create PR → invoke ship
- QA, test the site, find bugs → invoke qa
- Code review, check my diff → invoke review
- Update docs after shipping → invoke document-release
- Weekly retro → invoke retro
- Design system, brand → invoke design-consultation
- Visual audit, design polish → invoke design-review
- Architecture review → invoke plan-eng-review
- Save progress, checkpoint, resume → invoke checkpoint
- Code quality, health check → invoke health
