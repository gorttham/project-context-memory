#!/usr/bin/env bash
# verify.sh — Run this from your project root to check the memory system is installed correctly.
# Usage: bash tests/verify.sh

PASS=0
FAIL=0
WARN=0

green="\033[32m"
red="\033[31m"
yellow="\033[33m"
reset="\033[0m"

pass() { echo -e "${green}  PASS${reset}  $1"; ((PASS++)); }
fail() { echo -e "${red}  FAIL${reset}  $1"; ((FAIL++)); }
warn() { echo -e "${yellow}  WARN${reset}  $1"; ((WARN++)); }

echo ""
echo "Memory System — Verification"
echo "============================="
echo ""

# ── 1. Required files exist ────────────────────────────────────────────────
echo "[ Required Files ]"

required_files=(
  "CLAUDE.md"
  ".claude/commands/memorise.md"
  "memory/INDEX.md"
  "memory/code-changes/README.md"
  "memory/context/project.md"
  "memory/context/industry.md"
  "memory/context/tech-stack.md"
  "memory/context/decisions.md"
  "memory/people/people.md"
  "memory/preferences/preferences.md"
)

for f in "${required_files[@]}"; do
  if [ -f "$f" ]; then
    pass "$f"
  else
    fail "$f  ← MISSING"
  fi
done

echo ""

# ── 2. CLAUDE.md references memorise ──────────────────────────────────────
echo "[ CLAUDE.md Content ]"

if grep -q "memorise" CLAUDE.md 2>/dev/null; then
  pass "CLAUDE.md references /memorise"
else
  fail "CLAUDE.md does not mention /memorise"
fi

if grep -q "memory/INDEX.md" CLAUDE.md 2>/dev/null; then
  pass "CLAUDE.md instructs reading memory/INDEX.md at session start"
else
  fail "CLAUDE.md does not instruct reading memory/INDEX.md"
fi

echo ""

# ── 3. Slash command is correctly formatted ────────────────────────────────
echo "[ /memorise Command ]"

cmd=".claude/commands/memorise.md"
if [ -f "$cmd" ]; then
  if grep -q '\$ARGUMENTS' "$cmd"; then
    pass "/memorise command uses \$ARGUMENTS for timeframe"
  else
    fail "/memorise command does not use \$ARGUMENTS — timeframe arg won't work"
  fi

  if grep -q "memory/code-changes" "$cmd"; then
    pass "/memorise writes to memory/code-changes/"
  else
    fail "/memorise does not reference memory/code-changes/"
  fi

  if grep -q "memory/INDEX.md" "$cmd"; then
    pass "/memorise updates memory/INDEX.md"
  else
    fail "/memorise does not update memory/INDEX.md"
  fi
fi

echo ""

# ── 4. Obsidian frontmatter present in key files ──────────────────────────
echo "[ Obsidian Compatibility ]"

obsidian_files=(
  "memory/INDEX.md"
  "memory/context/project.md"
  "memory/context/decisions.md"
  "memory/context/tech-stack.md"
  "memory/context/industry.md"
  "memory/people/people.md"
  "memory/preferences/preferences.md"
)

for f in "${obsidian_files[@]}"; do
  if [ -f "$f" ]; then
    first_line=$(head -1 "$f")
    if [ "$first_line" = "---" ]; then
      pass "$f  has YAML frontmatter"
    else
      fail "$f  missing YAML frontmatter (first line should be ---)"
    fi
  fi
done

echo ""

# ── 5. INDEX.md has required sections ─────────────────────────────────────
echo "[ INDEX.md Structure ]"

index="memory/INDEX.md"
if [ -f "$index" ]; then
  for section in "Sections" "Recent Code Changes" "Tag Index" "How to Use"; do
    if grep -q "## $section" "$index"; then
      pass "INDEX.md has '## $section' section"
    else
      fail "INDEX.md missing '## $section' section"
    fi
  done

  for link in "project" "industry" "tech-stack" "decisions" "people" "preferences"; do
    if grep -q "\[\[$link\]\]" "$index"; then
      pass "INDEX.md links to [[$link]]"
    else
      fail "INDEX.md missing [[$link]] wikilink"
    fi
  done
fi

echo ""

# ── 6. code-changes/README.md has schema ──────────────────────────────────
echo "[ code-changes Schema ]"

schema="memory/code-changes/README.md"
if [ -f "$schema" ]; then
  for term in "What changed" "Why" "Learnings" "Type"; do
    if grep -q "$term" "$schema"; then
      pass "Schema documents '$term' field"
    else
      fail "Schema missing '$term' field"
    fi
  done
fi

echo ""

# ── 7. Optional: git repo present ─────────────────────────────────────────
echo "[ Git Repository (optional) ]"

if git rev-parse --is-inside-work-tree &>/dev/null; then
  pass "Git repository detected — /memorise will mine commit history"
else
  warn "No git repository — /memorise will capture from conversation context only"
fi

echo ""

# ── Summary ────────────────────────────────────────────────────────────────
echo "============================="
echo -e "Results: ${green}${PASS} passed${reset}  ${red}${FAIL} failed${reset}  ${yellow}${WARN} warnings${reset}"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "Fix the FAILs above before running /memorise."
  exit 1
else
  echo "All checks passed. Run /memorise in Claude Code to begin capturing memory."
  exit 0
fi
