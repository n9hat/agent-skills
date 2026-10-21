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

function addAgentsNote() {
  const file = 'AGENTS.md';
  const existing = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
  if (existing.includes(NOTE_MARKER)) {
    console.log('AGENTS.md already has the bridge note');
    return;
  }
  const note = fs.readFileSync(path.join(TEMPLATES, 'agents-note.md'), 'utf8');
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
