# Bridge pack

The **cross-team bridge**: two small skills, `bridge-handoff` and `bridge-takeover`, that pass a branch's working context from one person (or machine) to the next through Git. Part of [Agent Skills](../../README.md).

---

## Why this exists

Teams rarely work the same way. One developer plans every change with a **plan-first skill pack**, another drives a **task graph of beads**, a third writes **specs before code**, a fourth keeps a **personal skill collection**, and someone else is simply **vibe-coding** with no framework at all. Each workflow leaves its own trail of jargon, files, and half-finished state: a plan file here, a bead tracker there, a specs folder, a chat history on one laptop.

That works until the work has to change hands. Then the next person faces questions that the code alone cannot answer:

- What was this branch actually trying to do?
- Which contracts (API specs, shared types) does it have to honour?
- What is finished, what is broken, and what was decided along the way?
- What is the next step, expressed in *my* way of working?

The bridge answers them with one plain-language file, committed to the branch, and two commands that the major AI coding tools can run. **Nobody has to change how they work.**

## How it works

```
  Person / machine A                      Git                      Person / machine B
 ───────────────────                ───────────────               ─────────────────────
  /bridge-handoff                                                  git pull
    reads git status, diffs,                                       /bridge-takeover
    contracts, build state                                           reads HANDOVER.md
    writes .bridge/HANDOVER.md  ──►  commit + push  ──►               checks it against the repo
                                                                     proposes the next 3 steps
                                                                     in B's own workflow
```

1. **Hand off.** At the end of a session, run `/bridge-handoff` (or say "bridge handoff"). The agent inspects the branch and writes `.bridge/HANDOVER.md`: goal, contracts, files touched, honest build state, decisions, open questions, and next steps, in plain language with no workflow jargon.
2. **Commit and push** your work, then the handover in a commit of its own, on a [bridge branch](#bridge-branches).
3. **Take over.** The next person (or you, on another machine) pulls and runs `/bridge-takeover` (or says "bridge takeover"). The agent checks the handover against the current repo, flags anything that has drifted, and proposes the next three steps translated into that person's own workflow: beads for a task-graph workflow, a spec change for a spec-first one, a plain task list for a vibe-coder.

If there is no handover at all, for example because someone went off sick without warning, `/bridge-takeover` rebuilds the previous intent from recent commits, diffs, and references, and labels everything it inferred.

## Where a handover works

Git already carries the code. What it does not carry is the context: why you chose this approach, what you tried and rejected, what you were about to do next. That usually lives in your head, or in an AI chat history on one machine. `/bridge-handoff` writes it into `.bridge/HANDOVER.md`, and Git carries the file wherever the repository goes.

- **Across machines and people:** anyone who pulls the branch gets the handover, in any timezone.
- **Across sessions and tools:** a new session, on the same machine or another, finds the same file, whether it runs Claude Code, Codex, another tool, or no AI at all. The second session picks up the first one's decisions instead of undoing them.
- **Not across projects.** Each repository has its own bridge and its own handover. If a piece of work spans two repositories, for example an API and the app that calls it, write a handover in each and name the other repository under "Contracts".

The handover lives only on a bridge branch and never reaches your main branch, so old context cannot mislead anyone later (see [Bridge branches](#bridge-branches)).

## Supported scenarios

### 1. Timezone handoffs

*A developer in London finishes for the day; a colleague in Bengaluru, Singapore, or New York continues the same branch a few hours later.*

1. London runs `/bridge-handoff`, reviews the file, and pushes it with the day's work.
2. The next timezone pulls and runs `/bridge-takeover`. The agent reports what changed, whether the build still matches the handover's "Current state", and the next three steps.
3. Open questions in the handover go to the previous owner asynchronously, so nobody waits for a call across timezones.

Follow-the-sun works because the handover says *why*, not just *what*, so the next person does not redo or undo decisions made while they were asleep.

### 2. Emergency sick-leave takeovers

*A developer is suddenly off sick, mid-feature, with no handover written.*

1. A teammate checks out the branch and runs `/bridge-takeover`.
2. With no `.bridge/HANDOVER.md`, the agent reconstructs the intent from the last commits, their diffs, the branch name, issue or merge-request references, and TODOs in the changed files. Every inferred statement is labelled "inferred".
3. The agent checks the work against the shared contracts and proposes the next steps, plus the questions to ask the absent colleague once they are back.

Nothing is changed until the teammate agrees with the plan, so a takeover under pressure stays a deliberate decision.

**Only pushed work can be taken over.** Commits that were made but never pushed exist only on the absent developer's machine; neither the bridge nor Git can reach them. The [back-and-forth loop](#the-back-and-forth-loop) is the insurance: pushing work and a handover to the bridge branch at the end of every session means at most one session's work is ever at risk. If the machine is still reachable, for example a company laptop, someone with access can push the branch from it.

### 3. Single-developer multi-device switching

*You start at the office desktop and want to continue on the laptop at home, or on the couch.*

1. Before leaving, run `/bridge-handoff` and push.
2. On the other machine, pull and run `/bridge-takeover`. You get back where you were, what you had decided, and what you were about to do.
3. Repeat every day, in either direction, on the same bridge branch until the work is done.

Your AI chat history stays on the first machine; the handover travels with the code.

### 4. Mixed workflows on one team

*A branch started under one workflow is continued under another, for example from a bead tracker to a personal skill set, or from written specs to vibe-coding.*

The handover is written in plain language with file paths instead of workflow jargon, and `/bridge-takeover` restates the plan in the reader's own style. Neither person has to learn the other's tooling to continue the work.

### 5. Human vibe-coding alongside AI workflows

*A developer working without any framework, with or without an AI assistant, hands over to (or takes over from) someone using a structured workflow.*

`.bridge/HANDOVER.md` is ordinary Markdown. A human can write or read it without any AI tool, and an agent on the other side can still verify it against the repository.

## What's inside

| Skill | Command | Say | What it does |
|---|---|---|---|
| [`bridge-handoff`](skills/bridge-handoff/SKILL.md) | `/bridge-handoff` | "bridge handoff" | Writes `.bridge/HANDOVER.md` from the branch's current state |
| [`bridge-takeover`](skills/bridge-takeover/SKILL.md) | `/bridge-takeover` | "bridge takeover" | Reads the handover (or rebuilds intent from Git) and proposes the next steps |

The names carry a `bridge-` prefix on purpose: they do not collide with other popular skills named `handoff`. The bridge is for handing work to another person or machine through Git.

## Tool support

The skills follow the open `SKILL.md` format. The installer places them where each tool looks for them, and adds a startup reminder so the next session notices a waiting handover.

| Tool | Reads the skills from | Run it with | Startup reminder |
|---|---|---|---|
| Claude Code | `.claude/skills/` | `/bridge-handoff`, `/bridge-takeover`, or the words | `SessionStart` hook in `.claude/settings.json` |
| OpenAI Codex | `.agents/skills/` | `$bridge-handoff`, `$bridge-takeover`, or the words | `AGENTS.md` note |
| GitHub Copilot | `.agents/skills/` or `.claude/skills/` | ask for "bridge handoff" / "bridge takeover" | `AGENTS.md` note |
| Gemini CLI | `.agents/skills/` | ask for it by name; Gemini asks before activating a skill | `AGENTS.md` note (see below) |
| Grok Build | `.grok/skills/` | ask for it by name | `AGENTS.md` note; copy the skills manually (see below) |

Any tool can also be told in words: "run a bridge takeover". Skills are matched on their description.

**Gemini CLI** reads `GEMINI.md` by default. To make it read `AGENTS.md` too, add this to `.gemini/settings.json`:

```json
{ "context": { "fileName": ["AGENTS.md", "GEMINI.md"] } }
```

**Grok Build** reads skills from `.grok/skills/`, which the installer does not write. Copy them there if you use Grok:

```bash
mkdir -p .grok/skills && cp -R .agents/skills/bridge-* .grok/skills/
```

## Installation

Clone the hub once, then install the pack from inside the project you want to equip (all options are in the [hub README](../../README.md#installation)):

```bash
git clone https://github.com/n9hat/agent-skills.git ~/agent-skills

cd /path/to/your/project
bash ~/agent-skills/install.sh bridge          # needs bash and jq
# or
node ~/agent-skills/install.js bridge          # needs Node.js 16.7 or later; works on Windows
```

Add `--no-hook` to skip the Claude Code hook in `.claude/settings.json`.

Installing the bridge:

1. copies both skills into `.agents/skills/` and `.claude/skills/`;
2. appends a short bridge note to `AGENTS.md` (creating it if needed) that tells every agent to run `bridge-takeover` when a handover is waiting;
3. merges a `SessionStart` hook into `.claude/settings.json` that prints a reminder when `.bridge/HANDOVER.md` exists, keeping all existing settings and hooks.

It is safe to run again: skills are refreshed in place, and the note and hook are never added twice. If `.claude/settings.json` is not valid JSON, the installer stops without touching it. If `jq` is missing, `install.sh` prints the hook for you to add by hand instead of editing the file.

Commit the installed files so everyone who clones the project gets the bridge. Agents load skills when a session starts, so start a new session in the project after installing; one that was already open will not see the commands. Open the project folder itself: a session opened at a parent folder, such as `~/projects/`, does not see the bridge.

## The handover file

`.bridge/HANDOVER.md` lives in the project, outside any tool's own folder, so no single tool owns it. **Commit it; do not ignore it.** Committing it is how it reaches the next machine or person.

```markdown
# Bridge Handover

- Branch: <branch> · Last commit: <short sha> <subject> · Pushed: <yes | no>
- Written by: <name> · <date, time and timezone>
- Scenario: <timezone handoff | sick-leave cover | device switch | other>
- Tools used: <for example "Claude Code + a task-graph workflow", "Codex + specs", "none">

## 1. Goal and boundaries
## 2. Code footprint
## 3. Decisions and open questions
## 4. Next steps
```

The full template is in [`skills/bridge-handoff/SKILL.md`](skills/bridge-handoff/SKILL.md).

## Bridge branches

Do the work on a **bridge branch**, `bridge/<topic>` (for example `bridge/login-form`), and treat it as a scratchpad that travels between people and machines. The handover file stays on that branch; only the finished work reaches your main branch.

### The back-and-forth loop

```
main ──●──────────────────────────────────────────●   clean merge
        \                                         ↑
 bridge/<topic>                                   │ promote (method A)
          work ─ work ─ [bridge] ─ work ─ [bridge] ─ work
                          │ push     ↑    │ push
                          └─ pull ───┘    └─ pull ─► …
                         other machine / person
```

1. Start once: `git switch -c bridge/<topic> origin/main`.
2. **End of a session:** commit your work as usual, run `/bridge-handoff`, then commit the handover **on its own** (`git commit -m "bridge: handoff" -- .bridge/HANDOVER.md`) and push.
3. **Next session, anywhere:** `git pull`, run `/bridge-takeover`, and carry on.
4. Repeat for as many days as the work takes. The handover is replaced each time, so there is only ever one copy.

Two rules keep the noise out of your main branch: **handover commits touch only `.bridge/`**, and **work commits never touch `.bridge/`**.

### Merging the finished work

A merge request (MR) or pull request always shows everything that differs between the two branches, so it cannot leave out a single file. Instead, merge from a branch that never contained the handover, or squash it away.

**A. Promote to a clean branch (recommended).** Copy only the net change, without `.bridge/`, onto a fresh branch from main:

```bash
git fetch origin
git switch -c feature/<topic> origin/main
git diff --binary origin/main...bridge/<topic> -- . ':(exclude).bridge' | git apply --index
bash tests/run.sh                      # or your project's checks
git commit -m "<what the work does>"
git push -u origin feature/<topic>     # open the MR from this branch
```

The three dots mean "what the bridge branch changed since it left main", so work merged into main in the meantime is not undone. The bridge branch's commit-by-commit history never reaches main; only the clean result does.

**B. Squash merge.** If you prefer to open the MR straight from the bridge branch, remove the handover first, then merge with **Squash**:

```bash
git rm -r .bridge && git commit -m "bridge: remove handover" && git push
```

Main gets a single commit without `.bridge/`. Edit the squash message so it does not list the `bridge:` commits.

**Afterwards (both methods):** delete the bridge branch locally and on the remote, and start a new `bridge/<topic>` branch from main for the next piece of work:

```bash
git branch -D bridge/<topic> && git push origin --delete bridge/<topic>
```

Do not keep working on a promoted bridge branch: its next promotion would repeat changes that main already has.

**Optional safety net.** A CI check that fails any MR into main that still carries a handover, for example on GitHub Actions:

```yaml
# .github/workflows/no-bridge.yml
name: no-bridge
on:
  pull_request:
    branches: [main]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: test ! -e .bridge/HANDOVER.md || { echo "Remove .bridge/ before merging (see README, Bridge branches)"; exit 1; }
```

### Public repositories

In a public repository, a pushed bridge branch is public, and its commits can stay reachable on the host for a while after you delete it.

- Never write internal-only context into a handover, even on a private repository you may open up later.
- Delete bridge branches as soon as their work is promoted.
- Before making a private repository public, check that no handover survives: `git log --all --oneline -- .bridge` should print nothing. For zero risk, publish from a fresh repository built from a clean copy of your main branch.

## Ground rules

Both skills enforce the same three rules, whichever workflow produced the code:

- **Contracts first.** Shared API specs and interface or type files win over logic on a feature branch.
- **Never push a broken shared module.** If shared code fails, keep the fix or a stand-in (test double) inside your own area until it is resolved.
- **Tool-neutral.** Work is judged by whether it builds and passes its tests, not by which tool or method produced it.

Neither skill commits, pushes, or changes code on its own; the person stays in control.

## Known limitations

- The bridge is installed per project, not per user. That is deliberate: the skills travel with the clone, so whoever takes over has them without installing anything. Open the project folder itself, not a parent folder.
- **Coming soon, in part:** a personal install (`--user`) that makes the commands available in every project you open, without installing the bridge into each one. Handovers will still be per repository, as described in [Where a handover works](#where-a-handover-works).
- The startup reminder is a native hook only in Claude Code. The other tools rely on the `AGENTS.md` note, which they read as instructions rather than as an automatic trigger.
- The hook command uses POSIX shell syntax. On Windows, Claude Code needs Git Bash available to run it.
- Each tool decides for itself when a skill matches what you typed. If a phrase does not pick the skill, use the explicit command.

## Pack layout

```
skills/
  bridge-handoff/SKILL.md      # writes .bridge/HANDOVER.md
  bridge-takeover/SKILL.md     # reads it, or rebuilds intent from Git
install.sh                     # pack extras (bash + jq), run by the hub installer
install.js                     # pack extras (Node.js, same behaviour)
templates/
  agents-note.md               # note appended to AGENTS.md
  claude-hook.json             # Claude Code SessionStart hook handler
tests/
  run.sh                       # tests for this pack
```

## Testing

```bash
bash packs/bridge/tests/run.sh      # from the hub root; needs bash, node and jq
```

The suite installs the pack through both hub installers into fresh, existing, and broken projects, checks that a re-run adds nothing twice and that `--target` and `--no-hook` reach the pack, and confirms that the handover template lives only in `bridge-handoff`. It stops early if `node` or `jq` is missing.

## Works alongside

The bridge is meant to sit next to whatever workflow a team already uses, for example [pstack](https://github.com/cursor/plugins/tree/main/pstack/skills), the [Agentic Coding Flywheel](https://github.com/Dicklesworthstone/agentic_coding_flywheel_setup), [Spec Kit](https://github.com/github/spec-kit), [Matt Pocock's skills](https://github.com/mattpocock/skills), or none at all. It does not replace any of them.

## License

[MIT](../../LICENSE) © 2026 Narayana Bhat
