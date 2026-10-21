#!/usr/bin/env bash
# Install skill packs into a project.
# Usage: install.sh [options] PACK...   |   install.sh --all   |   install.sh --list
#   PACK             name of a pack in packs/ or in a --packs-dir
#   --all            install every pack found
#   --list           list the packs found, then exit
#   --packs-dir DIR  also look for packs in DIR (repeatable), e.g. a private repo
#   --target DIR     project to install into (default: current directory)
#   --no-hook        skip startup hooks (passed on to each pack's own installer)
set -euo pipefail

HUB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIRS=("$HUB/packs")
SKILL_DIRS=(.agents/skills .claude/skills)

TARGET="$PWD"
ALL=0
LIST=0
PACKS=()
PASS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --packs-dir)
      [ -d "${2:-}" ] || { echo "--packs-dir needs an existing directory" >&2; exit 2; }
      PACK_DIRS+=("$(cd "$2" && pwd)"); shift 2 ;;
    --target) TARGET="${2:?--target needs a directory}"; shift 2 ;;
    --no-hook) PASS+=(--no-hook); shift ;;
    --all) ALL=1; shift ;;
    --list) LIST=1; shift ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "Unknown option: $1 (see --help)" >&2; exit 2 ;;
    *) PACKS+=("$1"); shift ;;
  esac
done

# Print "name<TAB>dir" for every pack; the first directory wins on a name clash.
find_packs() {
  local seen=" " dir pack name
  for dir in "${PACK_DIRS[@]}"; do
    for pack in "$dir"/*/; do
      [ -d "$pack/skills" ] || continue
      pack="${pack%/}"; name="${pack##*/}"
      case "$seen" in *" $name "*) continue ;; esac
      seen="$seen$name "
      printf '%s\t%s\n' "$name" "$pack"
    done
  done
}

if [ "$LIST" -eq 1 ]; then find_packs; exit 0; fi

if [ "$ALL" -eq 1 ]; then
  PACKS=()
  while IFS=$'\t' read -r name _; do PACKS+=("$name"); done < <(find_packs)
fi
[ "${#PACKS[@]}" -gt 0 ] || { echo "Name at least one pack, or use --all (see --list)" >&2; exit 2; }

[ -d "$TARGET" ] || { echo "Target is not a directory: $TARGET" >&2; exit 2; }
TARGET="$(cd "$TARGET" && pwd)"

pack_dir() {
  find_packs | awk -F'\t' -v n="$1" '$1 == n { print $2; exit }'
}

install_pack() {
  local name="$1" pack skill dir
  pack="$(pack_dir "$name")"
  [ -n "$pack" ] || { echo "Unknown pack: $name (see --list)" >&2; exit 2; }
  if [ -f "$pack/install.js" ] && [ ! -f "$pack/install.sh" ]; then
    echo "Pack $name has only a Node installer; run install.js instead." >&2; exit 1
  fi
  for skill in "$pack"/skills/*/; do
    skill="${skill%/}"
    [ -f "$skill/SKILL.md" ] || continue
    for dir in "${SKILL_DIRS[@]}"; do
      mkdir -p "$TARGET/$dir/${skill##*/}"
      cp -R "$skill/." "$TARGET/$dir/${skill##*/}/"
      echo "Installed $dir/${skill##*/}"
    done
  done
  if [ -f "$pack/install.sh" ]; then
    bash "$pack/install.sh" --target "$TARGET" ${PASS[@]+"${PASS[@]}"}
  fi
}

for name in "${PACKS[@]}"; do
  [ -n "$(pack_dir "$name")" ] || { echo "Unknown pack: $name (see --list)" >&2; exit 2; }
done
for name in "${PACKS[@]}"; do install_pack "$name"; done
echo "Done. Commit the new files so everyone who clones the project gets these skills."
