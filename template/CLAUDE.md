# Claude Session Instructions

## Memory System

This project uses a persistent memory system in the `memory/` directory.

### At Session Start

Read `memory/INDEX.md` only. Do not pre-load other files speculatively.

### Answering questions about the project

Load memory files on demand when the conversation makes them relevant:

| Developer asks | Claude reads |
|---|---|
| "Any conflicts with adding X?" | `memory/context/decisions.md` → relevant `memory/decisions-log/YYYY-MM.md` |
| "What's our approach to Y?" | `memory/context/decisions.md` + `memory/context/tech-stack.md` |
| "What does 'Z' mean in our system?" | `memory/context/industry.md` → relevant `memory/industry-log/YYYY-MM.md` |
| "What are the project constraints?" | `memory/context/project.md` |
| "What changed last week?" | recent `memory/code-changes/YYYY-MM-DD.md` |

When reading context files, scan the card index (one-liners) first. Only open the
monthly log file if a matching card entry exists and you need the full detail.

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
