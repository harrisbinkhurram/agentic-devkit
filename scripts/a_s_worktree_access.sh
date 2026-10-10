#!/usr/bin/env bash
# Keep new worktrees from prompting for file access.
#
# A session started in one checkout prompts for every read or edit in a worktree that lives
# outside it. Listing the machine's worktree root under permissions.additionalDirectories in the
# user's Claude settings covers every worktree created there later, because user settings apply
# without workspace trust and a directory entry covers its subfolders. The root differs per
# machine, so it is resolved here and never committed to a project.
#
#   a_s_worktree_access.sh check <worktree_path>   prints "covered <root>" (exit 0) or "missing <root>" (exit 10)
#   a_s_worktree_access.sh add <root>              adds <root> to permissions.additionalDirectories (idempotent)
#
# The caller asks the user before running "add". This script never asks and never adds on its own.
set -euo pipefail

SETTINGS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"

die() { echo "a_s_worktree_access.sh: $*" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || die "jq is required"

# The root that holds this repo's worktrees. The worktree helper lays them out as
# <repos>/WorkTrees/<repo>/<branch>, so the root is two levels up when that level is named
# WorkTrees; for any other layout, the worktree's parent folder is the safest guess.
resolve_root() {
  local wt parent grand
  wt=$(cd "$1" 2>/dev/null && pwd -P) || die "no such directory: $1"
  parent=$(dirname "$wt")
  grand=$(dirname "$parent")
  if [ "$(basename "$grand" | tr '[:upper:]' '[:lower:]')" = "worktrees" ]; then
    echo "$grand"
  else
    echo "$parent"
  fi
}

# Every directory already listed, with a leading ~/ expanded, one per line.
listed_dirs() {
  [ -f "$SETTINGS" ] || return 0
  jq -r '.permissions.additionalDirectories[]? // empty' "$SETTINGS" 2>/dev/null |
    sed "s|^~/|$HOME/|; s|/*$||"
}

is_covered() {
  local path="$1" dir
  while IFS= read -r dir; do
    [ -n "$dir" ] || continue
    case "$path/" in "$dir"/*) return 0 ;; esac
  done < <(listed_dirs)
  return 1
}

cmd_check() {
  [ $# -eq 1 ] || die "usage: a_s_worktree_access.sh check <worktree_path>"
  local wt root
  wt=$(cd "$1" 2>/dev/null && pwd -P) || die "no such directory: $1"
  root=$(resolve_root "$wt")
  if is_covered "$wt"; then
    echo "covered $root"
  else
    echo "missing $root"
    exit 10
  fi
}

cmd_add() {
  [ $# -eq 1 ] || die "usage: a_s_worktree_access.sh add <root>"
  local root tmp
  root=$(cd "$1" 2>/dev/null && pwd -P) || die "no such directory: $1"
  if is_covered "$root"; then
    echo "already listed: $root"
    return 0
  fi
  mkdir -p "$(dirname "$SETTINGS")"
  [ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
  jq empty "$SETTINGS" 2>/dev/null || die "$SETTINGS is not valid JSON; not touching it"
  cp -p "$SETTINGS" "$SETTINGS.before-worktree-access"
  tmp=$(mktemp "$SETTINGS.XXXXXX")
  jq --arg d "$root" '.permissions.additionalDirectories = ((.permissions.additionalDirectories // []) + [$d] | unique)' \
    "$SETTINGS" > "$tmp"
  mv "$tmp" "$SETTINGS"
  echo "added: $root (backup: $SETTINGS.before-worktree-access)"
}

case "${1:-}" in
  check) shift; cmd_check "$@" ;;
  add)   shift; cmd_add "$@" ;;
  *)     die "usage: a_s_worktree_access.sh check <worktree_path> | add <root>" ;;
esac
