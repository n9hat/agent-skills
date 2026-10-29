#!/usr/bin/env bash
# Bridge pack extras: the AGENTS.md note and the Claude Code startup hook.
# Run by the hub's install.sh after it has copied the skills; not meant to be run alone.
# Usage: install.sh [--target DIR] [--no-hook]
#   --target DIR  project to install into (default: current directory)
#   --no-hook     skip the Claude Code SessionStart hook in .claude/settings.json
set -euo pipefail

PACK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES="$PACK/templates"
SETTINGS=".claude/settings.json"
NOTE_MARKER="<!-- bridge:begin -->"
NOTE_END="<!-- bridge:end -->"

TARGET="$PWD"
WITH_HOOK=1

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:?--target needs a directory}"; shift 2 ;;
    --no-hook) WITH_HOOK=0; shift ;;
    -h|--help) sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1 (see --help)" >&2; exit 2 ;;
  esac
done

[ -d "$TARGET" ] || { echo "Target is not a directory: $TARGET" >&2; exit 2; }
cd "$TARGET" || exit 2

# Replace an existing note in place, so a re-run after an upgrade brings in the current wording.
update_agents_note() {
  local note="$TEMPLATES/agents-note.md" tmp
  if ! grep -qF "$NOTE_END" AGENTS.md; then
    echo "AGENTS.md has '$NOTE_MARKER' but no '$NOTE_END'; left unchanged. Fix the note and re-run." >&2
    exit 1
  fi
  tmp="$(mktemp)"
  awk -v begin="$NOTE_MARKER" -v end="$NOTE_END" -v note="$note" '
    !skip && index($0, begin) { while ((getline line < note) > 0) print line; skip = 1 }
    !skip { print }
    skip && index($0, end) { skip = 0 }' AGENTS.md > "$tmp"
  if cmp -s "$tmp" AGENTS.md; then
    echo "AGENTS.md already has the current bridge note"
  else
    cat "$tmp" > AGENTS.md
    echo "Updated the bridge note in AGENTS.md"
  fi
  rm -f "$tmp"
}

add_agents_note() {
  if [ -f AGENTS.md ] && grep -qF "$NOTE_MARKER" AGENTS.md; then
    update_agents_note
    return
  fi
  if [ -s AGENTS.md ]; then echo >> AGENTS.md; fi
  cat "$TEMPLATES/agents-note.md" >> AGENTS.md
  echo "Added the bridge note to AGENTS.md"
}

add_claude_hook() {
  local hook="$TEMPLATES/claude-hook.json" tmp
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found, so $SETTINGS was not changed. Add this handler under hooks.SessionStart[].hooks yourself:" >&2
    cat "$hook" >&2
    return
  fi
  mkdir -p .claude
  if [ ! -s "$SETTINGS" ]; then echo '{}' > "$SETTINGS"; fi
  if ! jq -e 'type == "object"' "$SETTINGS" >/dev/null 2>&1; then
    echo "$SETTINGS is not a valid JSON object; left unchanged. Fix it and re-run." >&2
    exit 1
  fi
  tmp="$(mktemp)"
  jq --slurpfile h "$hook" '
    $h[0] as $handler
    | if any(.hooks.SessionStart[]?.hooks[]?; .command == $handler.command) then .
      else .hooks.SessionStart += [{hooks: [$handler]}] end' "$SETTINGS" > "$tmp"
  cat "$tmp" > "$SETTINGS"
  rm -f "$tmp"
  echo "Claude Code SessionStart hook is in $SETTINGS"
}

add_agents_note
if [ "$WITH_HOOK" -eq 1 ]; then add_claude_hook; fi
