# Agent Skills

Skills for AI coding agents that keep work moving when it changes hands: between people, timezones, machines, AI tools, and ways of working.

Teams rarely work the same way. These skills do not ask anyone to switch framework or tooling: **everyone keeps their own way of working**, and the work still moves between them. Each skill uses the open `SKILL.md` format, so it runs in Claude Code, Codex, Copilot, Gemini CLI, and other tools that read it.

## Packs

Skills ship in **packs**: small, self-contained sets of skills that belong together.

| Pack | Skills | What it does |
|---|---|---|
| [`bridge`](packs/bridge/README.md) | `bridge-handoff`, `bridge-takeover` | Passes a branch's working context to another person, timezone, or machine through Git, with any AI tool or none |

## Installation

Clone this repository once, then install the packs you want from inside the project you want to equip.

```bash
git clone https://github.com/n9hat/agent-skills.git ~/agent-skills

cd /path/to/your/project
bash ~/agent-skills/install.sh bridge          # needs bash (and jq for some packs)
# or
node ~/agent-skills/install.js bridge          # needs Node.js 16.7 or later; works on Windows
```

| Option | Effect |
|---|---|
| `PACK...` | Install these packs |
| `--all` | Install every pack found |
| `--list` | List the packs found, then exit |
| `--packs-dir DIR` | Also look for packs in `DIR`; repeat it for several directories |
| `--target DIR` | Install into `DIR` instead of the current directory |
| `--no-hook` | Skip startup hooks that a pack would add |

The installer copies each pack's skills into `.agents/skills/` (read by Codex, Copilot, and Gemini CLI) and `.claude/skills/` (read by Claude Code), then runs the pack's own installer, if it has one, for anything else the pack needs. It is safe to run again. Every pack name is checked before anything is written.

Commit the installed files so everyone who clones the project gets the skills. Agents load skills when a session starts, so start a new session after installing.

**Skills are installed per project.** A tool finds them through the folder a session is opened in, so open the project folder itself. A session opened at a parent folder, such as `~/projects/`, does not see the skills of the projects inside it. A personal install (`--user`) that works in every project is coming soon.

### Packs from other repositories

`--packs-dir` installs packs that live somewhere else, for example a private repository you share only with a team or course:

```bash
git clone git@github.com:<you>/<private-skills>.git ~/private-skills
bash ~/agent-skills/install.sh --packs-dir ~/private-skills/packs <pack>
```

The other repository only needs the same `packs/<name>/skills/<skill>/SKILL.md` layout. If two directories contain a pack with the same name, the first one wins, and this repository's `packs/` always comes first.

## Repository layout

```
install.sh                       # hub installer (bash)
install.js                       # hub installer (Node.js, same behaviour)
packs/
  bridge/
    README.md                    # what the pack does and how to use it
    install.sh, install.js       # pack extras: AGENTS.md note, Claude Code hook
    templates/                   # files the pack extras write
    skills/
      bridge-handoff/SKILL.md
      bridge-takeover/SKILL.md
    tests/run.sh                 # tests for this pack
tests/
  installer.sh                   # tests for the hub installers
  run-all.sh                     # runs every test above
```

## Adding a pack

1. Create `packs/<pack>/skills/<skill>/SKILL.md` for each skill, with `name: <skill>` (matching the folder) and a precise `description` that says when to use it.
2. Add `packs/<pack>/README.md`.
3. If the pack needs more than its skills (a note in `AGENTS.md`, a hook), add **both** `install.sh` and `install.js` to the pack. They receive `--target DIR` and, if the user passed it, `--no-hook`.
4. Add `packs/<pack>/tests/run.sh` and make `bash tests/run-all.sh` pass.
5. Add the pack to the table above.

A pack can also carry its own `LICENSE` if its terms differ from this repository's.

## Testing

```bash
bash tests/run-all.sh      # needs bash, node and jq
```

## License

[MIT](LICENSE) © 2026 Narayana Bhat
