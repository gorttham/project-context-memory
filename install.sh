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
# Flags:
#   --update   Refresh only .claude/commands/memorise.md and tests/verify.sh.
#              Never touches memory/ or CLAUDE.md. Prompts before overwriting
#              locally-modified files.
#
# The script NEVER overwrites existing files (except with --update).
# It appends to CLAUDE.md and skips any file that already exists.

set -e

# ── Parse flags ───────────────────────────────────────────────────────────────

UPDATE_MODE=false
POSITIONAL=()
for arg in "$@"; do
  case "$arg" in
    --update) UPDATE_MODE=true ;;
    *) POSITIONAL+=("$arg") ;;
  esac
done
set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}"

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
red="\033[31m"
bold="\033[1m"
reset="\033[0m"

echo ""
echo -e "${bold}Memory System Installer${reset}"
echo "Installing into: $TARGET"
echo ""

# ── UPDATE MODE ───────────────────────────────────────────────────────────────
# --update: refresh memorise.md and verify.sh only. Never touches memory/ or CLAUDE.md.
# Detects local modifications before overwriting.

if [ "$UPDATE_MODE" = true ]; then
  echo -e "${bold}Update mode${reset} — refreshing memorise.md and verify.sh only."
  echo ""

  _update_file() {
    local src="$1"
    local dst="$2"
    local label="$3"

    if [ ! -f "$dst" ]; then
      cp "$src" "$dst"
      chmod +x "$dst" 2>/dev/null || true
      echo -e "${green}  COPY${reset}  $label (new)"
      return
    fi

    # Compare checksums
    src_sum=$(sha256sum "$src" 2>/dev/null | awk '{print $1}' || shasum -a 256 "$src" 2>/dev/null | awk '{print $1}')
    dst_sum=$(sha256sum "$dst" 2>/dev/null | awk '{print $1}' || shasum -a 256 "$dst" 2>/dev/null | awk '{print $1}')

    if [ "$src_sum" = "$dst_sum" ]; then
      echo -e "${yellow}  SKIP${reset}  $label — already up to date"
      return
    fi

    # File differs — show truncated diff and prompt
    echo -e "${yellow}  DIFF${reset}  $label — local modifications detected"
    echo ""
    echo "  First 20 lines of diff (full diff → /tmp/memory-update-diff.txt):"
    diff "$dst" "$src" > /tmp/memory-update-diff.txt 2>/dev/null || true
    head -20 /tmp/memory-update-diff.txt | sed 's/^/    /'
    echo ""
    printf "  Overwrite %s? [y/N] " "$label"
    read -r answer </dev/tty
    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
      cp "$src" "$dst"
      chmod +x "$dst" 2>/dev/null || true
      echo -e "${green}  UPDATED${reset}  $label"
    else
      echo -e "${yellow}  KEPT${reset}  $label — not overwritten"
    fi
  }

  _update_file "$SCRIPT_DIR/.claude/commands/memorise.md" "$TARGET/.claude/commands/memorise.md" ".claude/commands/memorise.md"
  echo ""
  _update_file "$SCRIPT_DIR/tests/verify.sh" "$TARGET/tests/verify.sh" "tests/verify.sh"

  echo ""
  echo -e "${bold}Update complete.${reset}"
  echo ""
  exit 0
fi

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
VERIFY_COPIED=false

if [ -f "$test_dst" ]; then
  echo -e "${yellow}  SKIP${reset}  tests/verify.sh already exists — not overwritten"
else
  cp "$test_src" "$test_dst"
  chmod +x "$test_dst"
  VERIFY_COPIED=true
  echo -e "${green}  COPY${reset}  tests/verify.sh"
fi

# ── 4. Append to CLAUDE.md (never overwrite) ─────────────────────────────────

echo ""
echo "[ CLAUDE.md ]"

claude_dst="$TARGET/CLAUDE.md"
claude_template="$SCRIPT_DIR/template/CLAUDE.md"
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
    cat "$claude_template"
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

if [ "$VERIFY_COPIED" = true ]; then
  bash tests/verify.sh
else
  # tests/verify.sh already existed — run from the template source to avoid
  # executing the project's own verify.sh instead of the memory one
  bash "$SCRIPT_DIR/tests/verify.sh"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo -e "${bold}Installation complete.${reset}"
echo ""
echo "Next steps:"
echo "  1. Open Claude Code in $TARGET"
echo "  2. Run: /memorise"
echo "     — Claude will scan your git history and populate the memory files."
echo "     — If you see 'no commits found', that's fine — your memory files are"
echo "       ready and Claude will fill them in as the project grows."
echo "     — For best results, run /memorise at the end of each working session."
echo ""
echo "  3. Obsidian (optional):"
echo "     — Open Obsidian and create a new vault pointing to: $TARGET/memory/"
echo "     — Or point it at $TARGET if you want the whole project as a vault."
echo "     — All wikilinks, callouts, and tags work natively."
echo ""
echo "  To remove the memory system later, see the README."
echo ""
