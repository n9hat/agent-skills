#!/usr/bin/env node
// Install skill packs into a project.
// Usage: node install.js [options] PACK...  |  node install.js --all  |  node install.js --list
//   PACK             name of a pack in packs/ or in a --packs-dir
//   --all            install every pack found
//   --list           list the packs found, then exit
//   --packs-dir DIR  also look for packs in DIR (repeatable), e.g. a private repo
//   --target DIR     project to install into (default: current directory)
//   --no-hook        skip startup hooks (passed on to each pack's own installer)
// Same behaviour as install.sh, for machines without bash (needs Node 16.7+).
'use strict';

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const HUB = __dirname;
const SKILL_DIRS = [path.join('.agents', 'skills'), path.join('.claude', 'skills')];

function fail(message, code) {
  console.error(message);
  process.exit(code);
}

function isDir(p) {
  return fs.existsSync(p) && fs.statSync(p).isDirectory();
}

function parseArgs(argv) {
  const opts = { packDirs: [path.join(HUB, 'packs')], target: process.cwd(), all: false, list: false, packs: [], pass: [] };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--packs-dir') {
      if (!argv[i + 1] || !isDir(argv[i + 1])) fail('--packs-dir needs an existing directory', 2);
      opts.packDirs.push(path.resolve(argv[++i]));
    } else if (arg === '--target') {
      if (!argv[i + 1]) fail('--target needs a directory', 2);
      opts.target = argv[++i];
    } else if (arg === '--no-hook') {
      opts.pass.push('--no-hook');
    } else if (arg === '--all') {
      opts.all = true;
    } else if (arg === '--list') {
      opts.list = true;
    } else if (arg === '-h' || arg === '--help') {
      console.log('Usage: node install.js [--packs-dir DIR] [--target DIR] [--no-hook] PACK... | --all | --list');
      process.exit(0);
    } else if (arg.startsWith('-')) {
      fail(`Unknown option: ${arg} (see --help)`, 2);
    } else {
      opts.packs.push(arg);
    }
  }
  return opts;
}

// Map of pack name to directory; the first directory wins on a name clash.
function findPacks(packDirs) {
  const packs = new Map();
  for (const dir of packDirs) {
    for (const name of fs.readdirSync(dir).sort()) {
      const pack = path.join(dir, name);
      if (!packs.has(name) && isDir(path.join(pack, 'skills'))) packs.set(name, pack);
    }
  }
  return packs;
}

function installPack(name, pack, target, pass) {
  const hasJs = fs.existsSync(path.join(pack, 'install.js'));
  if (!hasJs && fs.existsSync(path.join(pack, 'install.sh'))) {
    fail(`Pack ${name} has only a bash installer; run install.sh instead.`, 1);
  }
  const skillsDir = path.join(pack, 'skills');
  for (const skill of fs.readdirSync(skillsDir).sort()) {
    if (!fs.existsSync(path.join(skillsDir, skill, 'SKILL.md'))) continue;
    for (const dir of SKILL_DIRS) {
      const dest = path.join(dir, skill);
      fs.cpSync(path.join(skillsDir, skill), path.join(target, dest), { recursive: true });
      console.log(`Installed ${dest}`);
    }
  }
  if (hasJs) {
    try {
      execFileSync(process.execPath, [path.join(pack, 'install.js'), '--target', target, ...pass], { stdio: 'inherit' });
    } catch (err) {
      process.exit(err.status || 1);
    }
  }
}

const opts = parseArgs(process.argv.slice(2));
const packs = findPacks(opts.packDirs);

if (opts.list) {
  for (const [name, pack] of packs) console.log(`${name}\t${pack}`);
  process.exit(0);
}

const names = opts.all ? [...packs.keys()] : opts.packs;
if (names.length === 0) fail('Name at least one pack, or use --all (see --list)', 2);
for (const name of names) {
  if (!packs.has(name)) fail(`Unknown pack: ${name} (see --list)`, 2);
}
if (!isDir(opts.target)) fail(`Target is not a directory: ${opts.target}`, 2);
const target = path.resolve(opts.target);

for (const name of names) installPack(name, packs.get(name), target, opts.pass);
console.log('Done. Commit the new files so everyone who clones the project gets these skills.');
