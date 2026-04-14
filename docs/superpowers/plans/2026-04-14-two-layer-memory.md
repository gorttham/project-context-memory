# Two-Layer Memory Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single-file context system with a two-layer card index + monthly log architecture that stays fast and readable at 500+ entries.

**Architecture:** Each of the three high-volume context files (decisions, tech-stack, industry) splits into a compact card index (one line per entry, always small) and an append-only monthly detail log (read on demand). `/memorise` writes to both layers simultaneously. Neither layer is ever rewritten. Session start loads `INDEX.md` only; everything else is lazy-loaded on query.

**Tech Stack:** Bash (verify.sh, install.sh), Markdown (all memory files), Node.js (bin/create-memory-system.js). No new dependencies.

---

## File Map

| File | Action | What changes |
|---|---|---|
| `tests/verify.sh` | Modify | Replace old INDEX.md section checks; add log directory checks; add card index format checks |
| `memory/decisions-log/.gitkeep` | Create | New directory for monthly decision detail logs |
| `memory/tech-stack-log/.gitkeep` | Create | New directory for monthly tech-stack detail logs |
| `memory/industry-log/.gitkeep` | Create | New directory for monthly industry detail logs |
| `memory/context/decisions.md` | Rewrite | Full replacement: frontmatter + card index format |
| `memory/context/tech-stack.md` | Rewrite | Full replacement: frontmatter + card index format |
| `memory/context/industry.md` | Rewrite | Full replacement: frontmatter + card index format |
| `memory/INDEX.md` | Rewrite | Full replacement: compact navigation map |
| `.claude/commands/memorise.md` | Modify | Steps 7, 7b-vi, 7c — replace write instructions with two-layer flow |
| `template/CLAUDE.md` | Modify | Replace session-start section with lazy-load instructions |
| `README.md` | Modify | Update directory structure block; add Querying section |

---

### Task 1: Update verify.sh to assert the new structure

**Files:**
- Modify: `tests/verify.sh`

The test suite must be updated before anything else so we can verify each change as we make it.

- [ ] **Step 1: Update the required files list**

In `tests/verify.sh`, replace the `required_files` array block (lines 26–38) with:

```bash
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

required_dirs=(
  "memory/decisions-log"
  "memory/tech-stack-log"
  "memory/industry-log"
)
```

Then add the directory checks immediately after the files loop (after the first `echo ""`):

```bash
echo "[ Required Directories ]"

for d in "${required_dirs[@]}"; do
  if [ -d "$d" ]; then
    pass "$d"
  else
    fail "$d  ← MISSING"
  fi
done

echo ""
```

- [ ] **Step 2: Replace the INDEX.md structure checks**

Find section `# ── 5. INDEX.md has required sections and features` (around line 144) and replace the entire block through the closing `fi` with:

```bash
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
```

- [ ] **Step 3: Add card index format checks for context files**

Add a new section after the INDEX.md block (before the CHANGELOG check):

```bash
# ── 5b. Context card indexes — format check ───────────────────────────────
echo "[ Card Index Format ]"

for f in "memory/context/decisions.md" "memory/context/tech-stack.md" "memory/context/industry.md"; do
  if [ -f "$f" ]; then
    # Check that the file references the two-layer log directories
    base=$(basename "$f" .md)
    if grep -q "${base}-log/" "$f" || grep -q "→ ${base}-log" "$f"; then
      pass "$f  — contains log references (→ log/YYYY-MM)"
    else
      warn "$f  — no log references found (card index entries should link to log)"
    fi
  fi
done

echo ""
```

- [ ] **Step 4: Add memorise.md log directory checks**

In the `/memorise` Command section (around line 67), add two more checks inside the `if [ -f "$cmd" ]` block:

```bash
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
```

- [ ] **Step 5: Run verify.sh and confirm the new checks fail (expected)**

```bash
bash tests/verify.sh
```

Expected output: several new FAILs for missing directories, missing INDEX.md sections, missing log references in memorise.md. The old checks may still pass. This confirms the tests are live.

- [ ] **Step 6: Commit**

```bash
git add tests/verify.sh
git commit -m "test: update verify.sh for two-layer memory architecture"
```

---

### Task 2: Create the log directories

**Files:**
- Create: `memory/decisions-log/.gitkeep`
- Create: `memory/tech-stack-log/.gitkeep`
- Create: `memory/industry-log/.gitkeep`

Git does not track empty directories. `.gitkeep` is the convention for committing an otherwise-empty directory.

- [ ] **Step 1: Create the three placeholder files**

Create `memory/decisions-log/.gitkeep` with empty content.
Create `memory/tech-stack-log/.gitkeep` with empty content.
Create `memory/industry-log/.gitkeep` with empty content.

- [ ] **Step 2: Run verify.sh — directory checks should now pass**

```bash
bash tests/verify.sh
```

Expected: `PASS  memory/decisions-log`, `PASS  memory/tech-stack-log`, `PASS  memory/industry-log`. Other new checks still fail — that's expected.

- [ ] **Step 3: Commit**

```bash
git add memory/decisions-log/.gitkeep memory/tech-stack-log/.gitkeep memory/industry-log/.gitkeep
git commit -m "feat: add log directory placeholders for two-layer memory"
```

---

### Task 3: Rewrite memory/context/decisions.md

**Files:**
- Rewrite: `memory/context/decisions.md`

The old format had heavy sections and a comment template. The new format is a card index: one line per decision, always compact.

- [ ] **Step 1: Write the new decisions.md**

Replace the entire file with:

```markdown
---
title: Decision Card Index
aliases:
  - Decisions
  - Decision Log
tags:
  - context
  - decisions
updated: 2026-04-14
---

# Decision Card Index

One line per decision. Full detail in `decisions-log/YYYY-MM.md`.
Format: `YYYY-MM-DD #tag [@author] — One sentence summary → decisions-log/YYYY-MM`

---

_No decisions logged yet. Run `/memorise` to capture decisions from git history._
```

- [ ] **Step 2: Run verify.sh — frontmatter checks should pass**

```bash
bash tests/verify.sh
```

Expected: `PASS memory/context/decisions.md — has frontmatter`, `PASS ... has 'title'`, `PASS ... has 'tags'`. The card index format check will warn (no entries yet, so no `→ decisions-log` references) — that is acceptable for an empty file.

- [ ] **Step 3: Commit**

```bash
git add memory/context/decisions.md
git commit -m "feat: convert decisions.md to card index format"
```

---

### Task 4: Rewrite memory/context/tech-stack.md

**Files:**
- Rewrite: `memory/context/tech-stack.md`

- [ ] **Step 1: Write the new tech-stack.md**

Replace the entire file with:

```markdown
---
title: Tech Stack Card Index
aliases:
  - Tech Stack
  - Stack
  - Conventions
tags:
  - context
  - tech
updated: 2026-04-14
---

# Tech Stack Card Index

One line per tool, convention, or pattern. Full detail in `tech-stack-log/YYYY-MM.md`.
Format: `YYYY-MM-DD #tag — One sentence summary → tech-stack-log/YYYY-MM`

---

_Not yet captured. Run `/memorise` to detect the tech stack from git history and project files._
```

- [ ] **Step 2: Run verify.sh**

```bash
bash tests/verify.sh
```

Expected: frontmatter checks pass for tech-stack.md.

- [ ] **Step 3: Commit**

```bash
git add memory/context/tech-stack.md
git commit -m "feat: convert tech-stack.md to card index format"
```

---

### Task 5: Rewrite memory/context/industry.md

**Files:**
- Rewrite: `memory/context/industry.md`

- [ ] **Step 1: Write the new industry.md**

Replace the entire file with:

```markdown
---
title: Industry Card Index
aliases:
  - Industry
  - Domain Knowledge
tags:
  - context
  - domain
updated: 2026-04-14
---

# Industry Card Index

One line per domain term, business rule, or external system. Full detail in `industry-log/YYYY-MM.md`.
Format: `YYYY-MM-DD #tag — One sentence summary → industry-log/YYYY-MM`

---

_No domain knowledge captured yet. Run `/memorise` to begin._
```

- [ ] **Step 2: Run verify.sh**

```bash
bash tests/verify.sh
```

Expected: frontmatter checks pass for industry.md.

- [ ] **Step 3: Commit**

```bash
git add memory/context/industry.md
git commit -m "feat: convert industry.md to card index format"
```

---

### Task 6: Rewrite memory/INDEX.md

**Files:**
- Rewrite: `memory/INDEX.md`

The old INDEX.md had a Mermaid diagram, a full Sections table, Tag Index, and How to Use block. The new format is a compact navigation map — no summaries, no diagrams. Claude reads it once at session start and knows where everything lives.

- [ ] **Step 1: Write the new INDEX.md**

Replace the entire file with:

```markdown
---
title: Memory Index
aliases:
  - Home
  - Index
tags:
  - index
updated: 2026-04-14
---

# Memory Index

## Context
- [[context/decisions]] — decision card index + log refs
- [[context/tech-stack]] — stack + conventions card index + log refs
- [[context/industry]] — domain terms + business rules card index + log refs
- [[context/project]] — goals, constraints, stakeholders

## Logs (read on demand)
- [[decisions-log/]] — full decision entries by month
- [[tech-stack-log/]] — full stack entries by month
- [[industry-log/]] — full domain entries by month
- [[code-changes/]] — daily code change logs

## Find something
- Decisions & conflicts → `context/decisions.md`
- Tech conventions → `context/tech-stack.md`
- Domain terms → `context/industry.md`
- Project goals → `context/project.md`
- What changed recently → `code-changes/YYYY-MM-DD.md`

---

## Recent Code Changes

%%Updated automatically by /memorise — do not edit this section manually%%

| Date | Summary |
|------|---------|
| _(none yet)_ | Run `/memorise` to begin capturing |
```

- [ ] **Step 2: Run verify.sh**

```bash
bash tests/verify.sh
```

Expected: all new INDEX.md section checks pass (`## Context`, `## Logs`, `## Find something`). All new wikilink checks pass (`[[context/decisions]]`, `[[context/tech-stack]]`, etc.). The old `## Sections`, `## Tag Index`, `## How to Use`, `## Vault Map` checks will now FAIL — these were removed in Task 1 Step 2 when you replaced those checks, so this is expected.

Also expected: `PASS memory/INDEX.md — has frontmatter`, `PASS ... has 'title'`, `PASS ... has 'tags'`.

- [ ] **Step 3: Commit**

```bash
git add memory/INDEX.md
git commit -m "feat: replace INDEX.md with compact navigation map"
```

---

### Task 7: Update .claude/commands/memorise.md write flow

**Files:**
- Modify: `.claude/commands/memorise.md`

Three sections need updating:
- **Step 7** — currently says "update context files from git" with no write format. Replace with classification + two-layer write instructions.
- **Step 7b-vi** — currently writes old entry format to context files directly. Replace with two-layer write.
- **Step 7c** — currently has no explicit write instructions. Add two-layer write.

- [ ] **Step 1: Replace Step 7**

Find the section `## Step 7 — Update Context Files from Git` and replace through the three bullet points with:

```markdown
## Step 7 — Classify and Write from Git Observations

Review all learnings from Step 5 commit entries. For each observation, classify it
into one or more of the three buckets and apply the threshold before writing.

**Threshold tests (skip entries that fail):**
- **decisions:** "Would a new developer need to know this choice to understand why the
  codebase is the way it is?" Only: architectural choices, things ruled out, reversals,
  business rules, meaningful tradeoffs. Skip: bug fixes, version bumps, style choices.
- **tech-stack:** "Would a developer unfamiliar with this project misconfigure or misuse
  this without knowing?" Only: new tools/frameworks, project-wide conventions, tooling
  constraints, deviations from framework defaults. Skip: standard library use, obvious code.
- **industry:** "Would a developer new to this domain misunderstand how the system works
  without this?" Only: project-specific terms, business rules, external integrations.
  Skip: general concepts, public API docs, plain-English terms.

**For each qualifying decisions entry:**

1. Run `git config user.name` to get author name.
2. Determine tags: `#architecture`, `#tooling`, `#auth`, `#api`, `#data`, etc.
3. Append one-liner to `memory/context/decisions.md`:
   `YYYY-MM-DD #tag [@author] — One sentence → decisions-log/YYYY-MM`
4. Open `memory/decisions-log/YYYY-MM.md`. Create with this frontmatter if it does not exist:
   ```
   ---
   title: Decisions Log — YYYY-MM
   tags: [decisions-log]
   month: YYYY-MM
   updated: YYYY-MM-DD
   ---

   # Decisions Log — YYYY-MM
   ```
   Append this entry at the bottom — never modify existing entries:
   ```
   ## YYYY-MM-DD — Decision Title #tag
   **Author:** name
   **Source:** commit <hash>
   **Decision:** What was decided.
   **Context:** What situation prompted this.
   **Options considered:**
   - Option A — pros / cons
   - Option B — pros / cons
   **Reason:** Why this option was chosen.
   **Consequences:** What this means going forward.

   ---
   ```

**For each qualifying tech-stack entry:**

1. Determine tags: `#language`, `#framework`, `#convention`, `#tooling`, etc.
2. Append one-liner to `memory/context/tech-stack.md`:
   `YYYY-MM-DD #tag — One sentence → tech-stack-log/YYYY-MM`
3. Open `memory/tech-stack-log/YYYY-MM.md`. Create with this frontmatter if it does not exist:
   ```
   ---
   title: Tech Stack Log — YYYY-MM
   tags: [tech-stack-log]
   month: YYYY-MM
   updated: YYYY-MM-DD
   ---

   # Tech Stack Log — YYYY-MM
   ```
   Append at the bottom:
   ```
   ## YYYY-MM-DD — Entry Title #tag
   **Source:** commit <hash>
   **Observed:** What was seen and where.
   **Note:** Anything worth knowing for future reference.

   ---
   ```

**For each qualifying industry entry:**

1. Determine tags: `#domain`, `#api`, `#business-rule`, `#integration`, etc.
2. Append one-liner to `memory/context/industry.md`:
   `YYYY-MM-DD #tag — One sentence → industry-log/YYYY-MM`
3. Open `memory/industry-log/YYYY-MM.md`. Create with this frontmatter if it does not exist:
   ```
   ---
   title: Industry Log — YYYY-MM
   tags: [industry-log]
   month: YYYY-MM
   updated: YYYY-MM-DD
   ---

   # Industry Log — YYYY-MM
   ```
   Append at the bottom:
   ```
   ## YYYY-MM-DD — Term or Concept #tag
   **Source:** commit <hash>
   **Observed:** What was seen and where.
   **Note:** Plain-language explanation of what this means in this project's domain.

   ---
   ```
```

- [ ] **Step 2: Replace Step 7b-vi**

Find `### 7b-vi. Write to context files` and replace the entire section (through "If nothing meaningful was found...") with:

```markdown
### 7b-vi. Write to context files (two-layer)

Apply the same classification and threshold rules from Step 7.

For each qualifying decisions entry from session messages:

1. Run `git config user.name` for author.
2. Append one-liner to `memory/context/decisions.md`:
   `YYYY-MM-DD #tag [@author] — One sentence → decisions-log/YYYY-MM`
3. Open `memory/decisions-log/YYYY-MM.md` (create with frontmatter if absent).
   Append:
   ```
   ## YYYY-MM-DD — Decision Title #tag
   **Author:** name
   **Source:** session <first-8-chars-of-uuid>
   **Decision:** What was decided.
   **Context:** What situation prompted this.
   **Options considered:**
   - Option A — pros / cons
   - Option B — pros / cons
   **Reason:** Why this option was chosen, in the user's own words where possible.
   **Consequences:** What this means going forward.

   ---
   ```

For each qualifying tech-stack entry:

1. Append one-liner to `memory/context/tech-stack.md`:
   `YYYY-MM-DD #tag — One sentence → tech-stack-log/YYYY-MM`
2. Open `memory/tech-stack-log/YYYY-MM.md` (create with frontmatter if absent).
   Append:
   ```
   ## YYYY-MM-DD — Entry Title #tag
   **Source:** session <first-8-chars-of-uuid>
   **Observed:** What was seen and where.
   **Note:** Anything worth knowing for future reference.

   ---
   ```

For each qualifying industry entry:

1. Append one-liner to `memory/context/industry.md`:
   `YYYY-MM-DD #tag — One sentence → industry-log/YYYY-MM`
2. Open `memory/industry-log/YYYY-MM.md` (create with frontmatter if absent).
   Append:
   ```
   ## YYYY-MM-DD — Term or Concept #tag
   **Source:** session <first-8-chars-of-uuid>
   **Observed:** What was surfaced in conversation.
   **Note:** Plain-language explanation in this project's domain context.

   ---
   ```

If nothing meaningful was found across all sessions, skip and note
"no session captures" in the report.
```

- [ ] **Step 3: Update Step 7c**

Find `## Step 7c — Capture from Current Conversation` and replace the write instruction at the end (from "Write entries tagged..." to end of section) with:

```markdown
Apply the same classification and threshold rules from Step 7. Use the same two-layer
write format as Step 7b-vi, but tag source as `source: conversation` (no session UUID —
current session is not yet in the JSONL files).

If nothing meaningful was said beyond the code work, skip this step entirely and
note "no conversation captures" in the report.
```

- [ ] **Step 4: Run verify.sh — memorise.md checks should now pass**

```bash
bash tests/verify.sh
```

Expected: `PASS /memorise references decisions-log/`, `PASS /memorise references tech-stack-log/`.

- [ ] **Step 5: Commit**

```bash
git add .claude/commands/memorise.md
git commit -m "feat: update memorise.md Steps 7/7b/7c for two-layer write flow"
```

---

### Task 8: Update template/CLAUDE.md

**Files:**
- Modify: `template/CLAUDE.md`

The session-start section currently instructs loading INDEX.md, project.md, tech-stack.md, and the most recent code-changes file. The new behaviour is: INDEX.md only at start, everything else on demand.

- [ ] **Step 1: Replace the session-start section**

Find the section `### At Session Start — Read These Files` through the `If any file is missing or empty, skip it and continue.` line and replace with:

```markdown
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
```

- [ ] **Step 2: Verify the file looks correct**

Read `template/CLAUDE.md` and confirm:
- No mention of loading project.md, tech-stack.md speculatively at session start
- The query lookup table is present
- The `/memorise` section is unchanged

- [ ] **Step 3: Commit**

```bash
git add template/CLAUDE.md
git commit -m "feat: update template CLAUDE.md for lazy-load session behaviour"
```

---

### Task 9: Update README.md

**Files:**
- Modify: `README.md`

Two changes: update the directory structure block to show the new log directories; add a "Querying the memory" section under "How It Works".

- [ ] **Step 1: Update the directory structure block**

Find the ` ```memory/``` ` code block (under "What gets stored") and replace it with:

```
memory/
├── INDEX.md                  ← Navigation map, loaded at session start
├── code-changes/
│   └── YYYY-MM-DD.md         ← Daily log: what changed, why, what was learned
├── context/
│   ├── project.md            ← Project goals and constraints
│   ├── industry.md           ← Card index: domain terms, one line each
│   ├── tech-stack.md         ← Card index: tools and conventions, one line each
│   └── decisions.md          ← Card index: architectural decisions, one line each
├── decisions-log/
│   └── YYYY-MM.md            ← Full decision detail, partitioned by month
├── tech-stack-log/
│   └── YYYY-MM.md            ← Full tech-stack detail, partitioned by month
├── industry-log/
│   └── YYYY-MM.md            ← Full domain detail, partitioned by month
├── people/
│   └── people.md             ← Team and stakeholders
└── preferences/
    └── preferences.md        ← Coding and workflow preferences
```

- [ ] **Step 2: Update "How Claude uses it"**

Find the paragraph starting `At the start of every session, Claude reads memory/INDEX.md...` and replace it with:

```markdown
At the start of every session, Claude reads `memory/INDEX.md` only — a compact navigation map that fits in a few hundred tokens. Context files are loaded on demand when a question makes them relevant. Nothing is pre-loaded speculatively.
```

- [ ] **Step 3: Add "Querying the memory" section**

After the "How Claude uses it" paragraph, add:

```markdown
### Querying the memory

Ask Claude in plain language:

- "Any conflicts with adding Redis caching?"
- "Have we made decisions about authentication before?"
- "What does 'idempotency key' mean in our system?"

Claude reads the relevant card index, scans the one-liners, and pulls full detail from
the monthly log only for entries that match. No manual searching — just ask.
```

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: update README with two-layer directory structure and query section"
```

---

### Task 10: Final verification and push

- [ ] **Step 1: Run full verify.sh and confirm all checks pass**

```bash
bash tests/verify.sh
```

Expected output: all checks PASS (or WARN for optional fields). Zero FAILs.

If any FAIL remains, read the error, identify which task's step it corresponds to, and fix before continuing.

- [ ] **Step 2: Confirm new directories are tracked by git**

```bash
git ls-files memory/decisions-log memory/tech-stack-log memory/industry-log
```

Expected:
```
memory/decisions-log/.gitkeep
memory/tech-stack-log/.gitkeep
memory/industry-log/.gitkeep
```

- [ ] **Step 3: Push to GitHub**

```bash
git push
```

---

## Self-Review Against Spec

**Spec coverage check:**

| Spec requirement | Covered by task |
|---|---|
| Card index format: one line per entry | Tasks 3, 4, 5 |
| Monthly log directories created | Task 2 |
| INDEX.md compact navigation map | Task 6 |
| Session start: INDEX.md only | Tasks 8, 9 |
| Developer query flow documented | Tasks 8, 9 |
| `/memorise` writes to both layers | Task 7 |
| Decision threshold enforced in write flow | Task 7, Step 1 |
| Tech-stack threshold enforced | Task 7, Step 1 |
| Industry threshold enforced | Task 7, Step 1 |
| Source attribution (`commit`, `session`, `conversation`) | Task 7, Steps 1–3 |
| Author field on decisions only | Task 7, Steps 1–2 |
| Monthly logs append-only, never modified | Task 7 (documented in write instructions) |
| verify.sh updated for new structure | Task 1 |
| template/CLAUDE.md updated | Task 8 |
| README updated | Task 9 |
| Migration: no data loss (current files are placeholders) | Tasks 3–5 (rewrites confirmed safe) |

**Placeholder scan:** No TBD, TODO, or "similar to Task N" references present. All write instructions contain complete markdown templates.

**Type consistency:** No function names or types — this is all markdown content. File paths are consistent throughout: `memory/context/decisions.md`, `memory/decisions-log/YYYY-MM.md`, etc.
