#!/usr/bin/env node
// Bridge pack extras: the AGENTS.md note and the Claude Code startup hook.
// Run by the hub's install.js after it has copied the skills; not meant to be run alone.
// Usage: node install.js [--target DIR] [--no-hook]
//   --target DIR  project to install into (default: current directory)
//   --no-hook     skip the Claude Code SessionStart hook in .claude/settings.json
// Same behaviour as install.sh, for machines without bash or jq (needs Node 16.7+).
'use strict';

const fs = require('fs');
const path = require('path');

const TEMPLATES = path.join(__dirname, 'templates');
const SETTINGS = path.join('.claude', 'settings.json');
const NOTE_MARKER = '<!-- bridge:begin -->';
const NOTE_END = '<!-- bridge:end -->';

function fail(message, code) {
  console.error(message);
  process.exit(code);
}

function parseArgs(argv) {
  const opts = { target: process.cwd(), withHook: true };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--target') {
      if (!argv[i + 1]) fail('--target needs a directory', 2);
      opts.target = argv[++i];
    } else if (arg === '--no-hook') {
      opts.withHook = false;
    } else if (arg === '-h' || arg === '--help') {
      console.log('Usage: node install.js [--target DIR] [--no-hook]');
      process.exit(0);
    } else {
      fail(`Unknown option: ${arg} (see --help)`, 2);
    }
  }
  return opts;
}

// Replace an existing note in place, so a re-run after an upgrade brings in the current wording.
function updateAgentsNote(file, existing, note) {
  if (existing.split(NOTE_MARKER).length > 2) {
    fail(`AGENTS.md has more than one '${NOTE_MARKER}'; left unchanged. Keep one bridge note and re-run.`, 1);
  }
  const begin = existing.lastIndexOf('\n', existing.indexOf(NOTE_MARKER)) + 1;
  const endMarker = existing.indexOf(NOTE_END, begin);
  if (endMarker < 0) {
    fail(`AGENTS.md has '${NOTE_MARKER}' but no '${NOTE_END}'; left unchanged. Fix the note and re-run.`, 1);
  }
  const lineEnd = existing.indexOf('\n', endMarker);
  const end = lineEnd < 0 ? existing.length : lineEnd + 1;
  const updated = existing.slice(0, begin) + note + existing.slice(end);
  if (updated === existing) {
    console.log('AGENTS.md already has the current bridge note');
    return;
  }
  fs.writeFileSync(file, updated);
  console.log('Updated the bridge note in AGENTS.md');
}

function addAgentsNote() {
  const file = 'AGENTS.md';
  const existing = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
  const note = fs.readFileSync(path.join(TEMPLATES, 'agents-note.md'), 'utf8');
  if (existing.includes(NOTE_MARKER)) {
    updateAgentsNote(file, existing, note);
    return;
  }
  fs.appendFileSync(file, (existing.length > 0 ? '\n' : '') + note);
  console.log('Added the bridge note to AGENTS.md');
}

function addClaudeHook() {
  const handler = JSON.parse(fs.readFileSync(path.join(TEMPLATES, 'claude-hook.json'), 'utf8'));
  let settings = {};
  if (fs.existsSync(SETTINGS) && fs.statSync(SETTINGS).size > 0) {
    try {
      settings = JSON.parse(fs.readFileSync(SETTINGS, 'utf8'));
    } catch (err) {
      fail(`${SETTINGS} is not valid JSON (${err.message}); left unchanged. Fix it and re-run.`, 1);
    }
    if (settings === null || typeof settings !== 'object' || Array.isArray(settings)) {
      fail(`${SETTINGS} is not a JSON object; left unchanged. Fix it and re-run.`, 1);
    }
  }

  settings.hooks = settings.hooks || {};
  const groups = (settings.hooks.SessionStart = settings.hooks.SessionStart || []);
  const present = groups.some((g) => (g.hooks || []).some((h) => h.command === handler.command));
  if (!present) groups.push({ hooks: [handler] });

  fs.mkdirSync(path.dirname(SETTINGS), { recursive: true });
  fs.writeFileSync(SETTINGS, JSON.stringify(settings, null, 2) + '\n');
  console.log(`Claude Code SessionStart hook is in ${SETTINGS}`);
}

const opts = parseArgs(process.argv.slice(2));
if (!fs.existsSync(opts.target) || !fs.statSync(opts.target).isDirectory()) {
  fail(`Target is not a directory: ${opts.target}`, 2);
}
process.chdir(opts.target);

addAgentsNote();
if (opts.withHook) addClaudeHook();
