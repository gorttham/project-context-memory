#!/usr/bin/env bash
# install.sh — Add the persistent memory system to an existing project.
#
# Usage (run from anywhere, pass your project root as the argument):
#
#   bash install.sh /path/to/your/project
#
# Or from inside your project:
#
#   bash /path/to/project-context-memory/install.sh .
#
# The script NEVER overwrites existing files. It appends to CLAUDE.md
# and skips any file that already exists.

set -e

# ── Resolve paths ────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-.}"
TARGET="$(cd "$TARGET" && pwd)"

if [ "$TARGET" = "$SCRIPT_DIR" ]; then
  echo "ERROR: Target is the same as the memory-system repo itself."
  echo "Pass your project directory as the argument: bash install.sh /path/to/your/project"
  exit 1
fi

green="\033[32m"
yellow="\033[33m"
bold="\033[1m"
reset="\033[0m"

echo ""
echo -e "${bold}Memory System Installer${reset}"
echo "Installing into: $TARGET"
echo ""

# ── 1. Copy memory/ directory ─────────────────────────────────────────────────

echo "[ memory/ ]"

if [ -d "$TARGET/memory" ]; then
  echo -e "${yellow}  SKIP${reset}  memory/ already exists — not overwritten"
else
  cp -r "$SCRIPT_DIR/memory" "$TARGET/memory"
  echo -e "${green}  COPY${reset}  memory/  →  $TARGET/memory/"
fi

# ── 2. Copy .claude/commands/memorise.md ─────────────────────────────────────

echo ""
echo "[ .claude/commands/ ]"

mkdir -p "$TARGET/.claude/commands"

cmd_src="$SCRIPT_DIR/.claude/commands/memorise.md"
cmd_dst="$TARGET/.claude/commands/memorise.md"

if [ -f "$cmd_dst" ]; then
  echo -e "${yellow}  SKIP${reset}  .claude/commands/memorise.md already exists — not overwritten"
else
  cp "$cmd_src" "$cmd_dst"
  echo -e "${green}  COPY${reset}  .claude/commands/memorise.md"
fi

# ── 3. Copy tests/verify.sh ───────────────────────────────────────────────────

echo ""
echo "[ tests/ ]"

mkdir -p "$TARGET/tests"

test_src="$SCRIPT_DIR/tests/verify.sh"
test_dst="$TARGET/tests/verify.sh"

if [ -f "$test_dst" ]; then
  echo -e "${yellow}  SKIP${reset}  tests/verify.sh already exists — not overwritten"
else
  cp "$test_src" "$test_dst"
  chmod +x "$test_dst"
  echo -e "${green}  COPY${reset}  tests/verify.sh"
fi

# ── 4. Append to CLAUDE.md (never overwrite) ─────────────────────────────────

echo ""
echo "[ CLAUDE.md ]"

claude_dst="$TARGET/CLAUDE.md"
memory_block_marker="## Memory System"

if [ -f "$claude_dst" ] && grep -q "$memory_block_marker" "$claude_dst"; then
  echo -e "${yellow}  SKIP${reset}  CLAUDE.md already contains '## Memory System' — not duplicated"
else
  {
    if [ -f "$claude_dst" ]; then
      echo ""
      echo "---"
      echo ""
    fi
    cat "$SCRIPT_DIR/CLAUDE.md"
  } >> "$claude_dst"

  if [ -f "$claude_dst" ] && grep -q "$memory_block_marker" "$claude_dst"; then
    echo -e "${green}  APPEND${reset}  Memory System section added to CLAUDE.md"
  else
    echo -e "${green}  CREATE${reset}  CLAUDE.md created"
  fi
fi

# ── 5. Verify installation ────────────────────────────────────────────────────

echo ""
echo "[ Verification ]"
echo ""

cd "$TARGET"
bash tests/verify.sh

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo -e "${bold}Installation complete.${reset}"
echo ""
echo "Next steps:"
echo "  1. Open Claude Code in $TARGET"
echo "  2. Run: /memorise"
echo "  3. Optionally point Obsidian at $TARGET/memory/"
echo ""
