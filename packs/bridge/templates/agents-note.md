<!-- bridge:begin -->
## Cross-team bridge

- If `.bridge/HANDOVER.md` exists, run the **bridge-takeover** skill before any other work.
- When the user says they are stopping, handing over, or switching machines on a `bridge/<topic>` branch, offer to run the **bridge-handoff** skill. It writes `.bridge/HANDOVER.md` and gives the commit steps; commit or push only if the user asks.
- When the work on a bridge branch is finished, suggest promoting it with `promote.sh` from the bridge-takeover skill, so `.bridge/` never reaches the main branch.
<!-- bridge:end -->
