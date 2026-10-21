---
name: bridge-handoff
description: Write .bridge/HANDOVER.md so another person, or you on another machine, can continue this branch with any AI tool or none. Use only for a "bridge handoff" or /bridge-handoff, not a generic handoff or chat summary.
---

# Bridge Handoff

Record where this branch stands, in plain language, so whoever continues it, with whatever tool or workflow, can carry on without asking you.

## Steps

1. **Inspect the branch.** Run `git status`, `git diff` (staged and unstaged), `git log --oneline -10`, and `git status -sb` for the branch and whether it is ahead of its upstream. Record the push state as it really is.
2. **Find the contracts.** API specs, shared types or interfaces, schemas, plans, ADRs. Reference them by path; do not copy them.
3. **State the truth about the build.** Run the project's quick, known checks and record the result, or write "not run".
4. **Write `.bridge/HANDOVER.md`** from the template below, replacing any previous version.
   - Plain language. Explain any workflow jargon (beads, tickets, spec IDs, phases) or point to the file instead.
   - Record decisions with their reason, open questions, and anything that so far exists only in your head.
   - Leave out secrets and personal data.
5. **Hand it back to the user.** Show the file. Uncommitted work goes in its own commit(s) first; the handover then gets a commit that touches only `.bridge/`, so it can be left out when the work moves to the main branch:
   `git add .bridge/HANDOVER.md && git commit -m "bridge: handoff" && git push`.
   Do not commit or push yourself unless the user asks.
6. **Warn about broken shared code** in "Current state" and in your reply.

## Rules

- **Contracts first.** Shared API specs and interface or type files win over logic on the feature branch.
- **Never push a broken shared module.** If shared code fails, keep the fix or a stand-in (test double) inside your own area until it is resolved.
- **Tool-neutral.** Judge the work by whether it builds and passes its tests, not by which tool or method produced it.

## Template

<!-- bridge-template:start -->
```markdown
# Bridge Handover

- Branch: <branch> · Last commit: <short sha> <subject> · Pushed: <yes | no>
- Written by: <name> · <date, time and timezone>
- Scenario: <timezone handoff | sick-leave cover | device switch | other>
- Tools used: <for example "Claude Code + a task-graph workflow", "Codex + specs", "none">

## 1. Goal and boundaries
- Objective: <what this branch is for>
- Contracts: <paths to API specs, shared types, schemas, plans>
- Out of scope: <what not to touch>

## 2. Code footprint
- Created: <paths>
- Modified shared modules: <paths>
- Current state: <for example "builds; integration tests 4 and 5 fail">

## 3. Decisions and open questions
- Decided: <decision> (reason: <why>)
- Open: <question> (who can answer: <name>)

## 4. Next steps
1. <smallest next task>
2. <next task>
3. <next task>
```
<!-- bridge-template:end -->
