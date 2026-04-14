#!/usr/bin/env node
/**
 * create-memory-system
 *
 * Installs the persistent memory system into the current project.
 * Run from your project root: npx github:gorttham/project-context-memory
 *
 * Cross-platform: works on macOS, Linux, and Windows native.
 * No external dependencies beyond Node.js.
 *
 * NOTE: This file mirrors install.sh (the bash installer).
 * When changing the install flow, update BOTH files.
 */

'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// ── Colours (disabled on Windows cmd.exe without ANSI support) ────────────────

const isColour = (process.stdout.isTTY && process.platform !== 'win32')
  || (process.env.FORCE_COLOR && process.env.FORCE_COLOR !== '0');

const c = {
  green:  isColour ? '\x1b[32m' : '',
  yellow: isColour ? '\x1b[33m' : '',
  red:    isColour ? '\x1b[31m' : '',
  bold:   isColour ? '\x1b[1m'  : '',
  reset:  isColour ? '\x1b[0m'  : '',
};

// ── Paths ─────────────────────────────────────────────────────────────────────

const TEMPLATE_DIR  = path.join(__dirname, '..');   // package root
const TARGET        = process.cwd();
const UPDATE_MODE   = process.argv.includes('--update');

if (path.resolve(TARGET) === path.resolve(TEMPLATE_DIR)) {
  console.error('ERROR: Run this from your project root, not from the package directory.');
  process.exit(1);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function log(colour, tag, message) {
  console.log(`  ${colour}${tag}${c.reset}  ${message}`);
}

/**
 * Recursively copy src directory into dst directory.
 * Skips files that already exist at the destination.
 * Returns { copied, skipped } counts.
 */
function copyDirSafe(src, dst) {
  let copied = 0, skipped = 0;
  fs.mkdirSync(dst, { recursive: true });

  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const srcPath = path.join(src, entry.name);
    const dstPath = path.join(dst, entry.name);

    if (entry.isDirectory()) {
      const r = copyDirSafe(srcPath, dstPath);
      copied  += r.copied;
      skipped += r.skipped;
    } else {
      if (fs.existsSync(dstPath)) {
        skipped++;
      } else {
        fs.copyFileSync(srcPath, dstPath);
        copied++;
      }
    }
  }
  return { copied, skipped };
}

/**
 * Copy a single file, skipping if destination already exists.
 * Returns true if copied, false if skipped.
 */
function copyFileSafe(src, dst) {
  fs.mkdirSync(path.dirname(dst), { recursive: true });
  if (fs.existsSync(dst)) return false;
  fs.copyFileSync(src, dst);
  return true;
}

/**
 * Append template CLAUDE.md content to the target CLAUDE.md.
 * Skips if '## Memory System' marker already present.
 */
function appendClaudeMd(templateClaudeMd, targetClaudeMd) {
  const MARKER = '## Memory System';
  const templateContent = fs.readFileSync(templateClaudeMd, 'utf8');

  if (fs.existsSync(targetClaudeMd)) {
    const existing = fs.readFileSync(targetClaudeMd, 'utf8');
    if (existing.includes(MARKER)) {
      return 'skipped';
    }
    fs.appendFileSync(targetClaudeMd, '\n---\n\n' + templateContent);
    return 'appended';
  } else {
    fs.writeFileSync(targetClaudeMd, templateContent);
    return 'created';
  }
}

// ── sha256 of a file ─────────────────────────────────────────────────────────

function fileHash(filePath) {
  try {
    return crypto.createHash('sha256').update(fs.readFileSync(filePath)).digest('hex');
  } catch (_) {
    return null;
  }
}

// ── Update mode ───────────────────────────────────────────────────────────────

if (UPDATE_MODE) {
  console.log('');
  console.log(`${c.bold}Memory System — Update mode${c.reset}`);
  console.log('Refreshing memorise.md and verify.sh only.');
  console.log('');

  function updateFile(src, dst, label) {
    if (!fs.existsSync(dst)) {
      fs.mkdirSync(path.dirname(dst), { recursive: true });
      fs.copyFileSync(src, dst);
      try { fs.chmodSync(dst, 0o755); } catch (_) {}
      log(c.green, 'COPY', `${label} (new)`);
      return;
    }

    const srcHash = fileHash(src);
    const dstHash = fileHash(dst);

    if (srcHash === dstHash) {
      log(c.yellow, 'SKIP', `${label} — already up to date`);
      return;
    }

    // Show truncated diff and prompt
    log(c.yellow, 'DIFF', `${label} — local modifications detected`);
    const { execSync } = require('child_process');
    let diffOutput = '';
    try {
      execSync(`diff "${dst}" "${src}"`, { encoding: 'utf8' });
    } catch (e) {
      diffOutput = e.stdout || '';
    }
    const lines = diffOutput.split('\n').slice(0, 20).join('\n');
    console.log('\n  First 20 lines of diff:\n');
    console.log(lines.split('\n').map(l => '    ' + l).join('\n'));

    const tmpDiff = path.join(require('os').tmpdir(), 'memory-update-diff.txt');
    fs.writeFileSync(tmpDiff, diffOutput);
    console.log(`\n  Full diff written to: ${tmpDiff}\n`);

    // Prompt (sync readline on TTY)
    process.stdout.write(`  Overwrite ${label}? [y/N] `);
    const buf = Buffer.alloc(10);
    let answer = '';
    try {
      const fd = fs.openSync('/dev/tty', 'r');
      const n = fs.readSync(fd, buf, 0, 10);
      fs.closeSync(fd);
      answer = buf.slice(0, n).toString().trim();
    } catch (_) {
      // Windows or non-TTY: skip prompt, keep existing
      console.log('(non-interactive — keeping existing file)');
    }

    if (answer.toLowerCase() === 'y') {
      fs.copyFileSync(src, dst);
      try { fs.chmodSync(dst, 0o755); } catch (_) {}
      log(c.green, 'UPDATED', label);
    } else {
      log(c.yellow, 'KEPT', `${label} — not overwritten`);
    }
  }

  updateFile(
    path.join(TEMPLATE_DIR, '.claude', 'commands', 'memorise.md'),
    path.join(TARGET, '.claude', 'commands', 'memorise.md'),
    '.claude/commands/memorise.md'
  );
  console.log('');
  updateFile(
    path.join(TEMPLATE_DIR, 'tests', 'verify.sh'),
    path.join(TARGET, 'tests', 'verify.sh'),
    'tests/verify.sh'
  );

  console.log('');
  console.log(`${c.bold}Update complete.${c.reset}`);
  console.log('');
  process.exit(0);
}

// ── Install ───────────────────────────────────────────────────────────────────

console.log('');
console.log(`${c.bold}Memory System Installer${c.reset}`);
console.log(`Installing into: ${TARGET}`);
console.log('');

// 1. memory/
console.log('[ memory/ ]');
const memorySrc = path.join(TEMPLATE_DIR, 'memory');
const memoryDst = path.join(TARGET, 'memory');

if (fs.existsSync(memoryDst)) {
  log(c.yellow, 'SKIP', 'memory/ already exists — not overwritten');
} else {
  const { copied } = copyDirSafe(memorySrc, memoryDst);
  log(c.green, 'COPY', `memory/  →  ${memoryDst}/ (${copied} files)`);
}

// 2. .claude/commands/memorise.md
console.log('');
console.log('[ .claude/commands/ ]');
const cmdSrc = path.join(TEMPLATE_DIR, '.claude', 'commands', 'memorise.md');
const cmdDst = path.join(TARGET, '.claude', 'commands', 'memorise.md');

if (copyFileSafe(cmdSrc, cmdDst)) {
  log(c.green, 'COPY', '.claude/commands/memorise.md');
} else {
  log(c.yellow, 'SKIP', '.claude/commands/memorise.md already exists — not overwritten');
}

// 3. tests/verify.sh
console.log('');
console.log('[ tests/ ]');
const testSrc = path.join(TEMPLATE_DIR, 'tests', 'verify.sh');
const testDst = path.join(TARGET, 'tests', 'verify.sh');
let verifyCopied = false;

if (copyFileSafe(testSrc, testDst)) {
  // Make executable on Unix
  try { fs.chmodSync(testDst, 0o755); } catch (_) {}
  verifyCopied = true;
  log(c.green, 'COPY', 'tests/verify.sh');
} else {
  log(c.yellow, 'SKIP', 'tests/verify.sh already exists — not overwritten');
}

// 4. CLAUDE.md (append, never overwrite)
console.log('');
console.log('[ CLAUDE.md ]');
const claudeSrc = path.join(TEMPLATE_DIR, 'template', 'CLAUDE.md');
const claudeDst = path.join(TARGET, 'CLAUDE.md');

const claudeResult = appendClaudeMd(claudeSrc, claudeDst);
if (claudeResult === 'skipped') {
  log(c.yellow, 'SKIP', "CLAUDE.md already contains '## Memory System' — not duplicated");
} else if (claudeResult === 'appended') {
  log(c.green, 'APPEND', 'Memory System section added to CLAUDE.md');
} else {
  log(c.green, 'CREATE', 'CLAUDE.md created');
}

// 5. Verify (Unix only — skip on Windows native)
console.log('');
console.log('[ Verification ]');
console.log('');

if (process.platform === 'win32') {
  console.log('  Verification script requires bash — skipping on Windows native.');
  console.log('  Run from Git Bash or WSL: bash tests/verify.sh');
} else {
  const { spawnSync } = require('child_process');
  const verifyScript = verifyCopied ? testDst : path.join(TEMPLATE_DIR, 'tests', 'verify.sh');
  const result = spawnSync('bash', [verifyScript], {
    cwd: TARGET,
    stdio: 'inherit',
  });
  if (result.status !== 0) {
    console.log('');
    console.log(`${c.yellow}  Verification reported issues — see output above.${c.reset}`);
  }
}

// ── Done ──────────────────────────────────────────────────────────────────────

console.log('');
console.log(`${c.bold}Installation complete.${c.reset}`);
console.log('');
console.log('Next steps:');
console.log('  1. Open Claude Code in this directory');
console.log('  2. Run: /memorise');
console.log('     — Claude will scan your codebase and git history to populate the memory files.');
console.log('     — If you see \'no commits found\', that\'s fine — your memory files are');
console.log('       ready and Claude will fill them in as the project grows.');
console.log('     — For best results, run /memorise at the end of each working session.');
console.log('');
console.log('  3. Obsidian (optional):');
console.log(`     — Open Obsidian and create a new vault pointing to: ${path.join(TARGET, 'memory')}`);
console.log(`     — Or point it at ${TARGET} if you want the whole project as a vault.`);
console.log('     — All wikilinks, callouts, and tags work natively.');
console.log('');
console.log('  To update the memory system later:');
console.log('     npx github:gorttham/project-context-memory --update');
console.log('');
console.log('  To remove the memory system:');
console.log('     See the README for removal instructions.');
console.log('');
