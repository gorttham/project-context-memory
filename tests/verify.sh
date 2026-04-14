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
  "memory/CHANGELOG.md"
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

echo "[ Required Directories ]"

required_dirs=(
  "memory/decisions-log"
  "memory/tech-stack-log"
  "memory/industry-log"
)

for d in "${required_dirs[@]}"; do
  if [ -d "$d" ]; then
    pass "$d"
  else
    fail "$d  ← MISSING"
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
    pass "/memorise uses \$ARGUMENTS for timeframe"
  else
    fail "/memorise does not use \$ARGUMENTS — timeframe arg won't work"
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

  if grep -q "memory/CHANGELOG.md" "$cmd"; then
    pass "/memorise logs to memory/CHANGELOG.md"
  else
    fail "/memorise does not log to memory/CHANGELOG.md"
  fi

  if grep -q "decisions-log" "$cmd"; then
    pass "/memorise references decisions-log/ (two-layer write)"
  else
    fail "/memorise does not reference decisions-log/ — two-layer write not implemented"
  fi

  if grep -q "tech-stack-log" "$cmd"; then
    pass "/memorise references tech-stack-log/ (two-layer write)"
  else
    fail "/memorise does not reference tech-stack-log/ — two-layer write not implemented"
  fi
fi

echo ""

# ── 4. Obsidian frontmatter — required fields ─────────────────────────────
echo "[ Obsidian Properties ]"

obsidian_files=(
  "memory/INDEX.md"
  "memory/CHANGELOG.md"
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
      pass "$f  — has frontmatter"
    else
      fail "$f  — missing frontmatter (first line must be ---)"
    fi

    if grep -q "^title:" "$f"; then
      pass "$f  — has 'title' property"
    else
      fail "$f  — missing 'title' property (Obsidian uses this for display)"
    fi

    if grep -q "^aliases:" "$f"; then
      pass "$f  — has 'aliases' property"
    else
      warn "$f  — no 'aliases' (optional but improves wikilink resolution)"
    fi

    if grep -q "^tags:" "$f"; then
      pass "$f  — has 'tags' property"
    else
      fail "$f  — missing 'tags' property"
    fi
  fi
done

echo ""

# ── 5. INDEX.md structure ─────────────────────────────────────────────────
echo "[ INDEX.md Structure ]"

index="memory/INDEX.md"
if [ -f "$index" ]; then
  for section in "Context" "Logs" "Find something"; do
    if grep -q "## $section" "$index"; then
      pass "INDEX.md — '## $section' section present"
    else
      fail "INDEX.md — missing '## $section' section"
    fi
  done

  for link in "context/decisions" "context/tech-stack" "context/industry" "context/project" "decisions-log" "tech-stack-log" "industry-log" "code-changes"; do
    if grep -q "\[\[$link" "$index"; then
      pass "INDEX.md — links to [[$link]]"
    else
      fail "INDEX.md — missing [[$link]] wikilink"
    fi
  done
fi

echo ""

# ── 5b. Card index format ─────────────────────────────────────────────────
echo "[ Card Index Format ]"

for f in "memory/context/decisions.md" "memory/context/tech-stack.md" "memory/context/industry.md"; do
  if [ -f "$f" ]; then
    base=$(basename "$f" .md)
    if grep -q "${base}-log/" "$f" || grep -q "→ ${base}-log" "$f"; then
      pass "$f  — contains log references"
    else
      warn "$f  — no log references yet (expected until /memorise runs)"
    fi
  fi
done

echo ""

# ── 6. CHANGELOG.md has correct structure ─────────────────────────────────
echo "[ CHANGELOG.md Structure ]"

changelog="memory/CHANGELOG.md"
if [ -f "$changelog" ]; then
  if grep -q "memorise appends new entries above this line" "$changelog"; then
    pass "CHANGELOG.md — has append marker comment"
  else
    fail "CHANGELOG.md — missing append marker (needed for /memorise to locate insert point)"
  fi
fi

echo ""

# ── 7. code-changes/README.md has schema ──────────────────────────────────
echo "[ code-changes Schema ]"

schema="memory/code-changes/README.md"
if [ -f "$schema" ]; then
  for term in "What changed" "Why" "Learnings" "Type"; do
    if grep -q "$term" "$schema"; then
      pass "Schema — '$term' field documented"
    else
      fail "Schema — missing '$term' field"
    fi
  done
fi

echo ""

# ── 8. Optional: git repo present ─────────────────────────────────────────
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
