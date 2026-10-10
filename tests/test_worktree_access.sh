#!/usr/bin/env bash
# Behaviour fixture for a_s_worktree_access.sh, which keeps new worktrees from prompting for
# file access. Run: bash tests/test_worktree_access.sh
A="$(cd "$(dirname "$0")/.." && pwd)/scripts/a_s_worktree_access.sh"
S=$(mktemp -d "${TMPDIR:-/tmp}/wt-access.XXXXXX")
mkdir -p "$S/cfg" "$S/repos/WorkTrees/proj/feature-x" "$S/other/wt"
fail=0
expect() { if [ "$1" = "$2" ]; then echo "ok   $3"; else echo "FAIL $3: got [$1] want [$2]"; fail=1; fi; }
run() { CLAUDE_CONFIG_DIR="$S/cfg" bash "$A" "$@"; }
R=$(cd "$S" && pwd -P)

out=$(run check "$S/repos/WorkTrees/proj/feature-x"); rc=$?
expect "$out|$rc" "missing $R/repos/WorkTrees|10" "no settings file: missing, root two levels up"
run add "$S/repos/WorkTrees" >/dev/null
out=$(run add "$S/repos/WorkTrees")
expect "$out" "already listed: $R/repos/WorkTrees" "second add is a no-op"
expect "$(jq -r '.permissions.additionalDirectories|length' "$S/cfg/settings.json")" "1" "one entry only"
out=$(run check "$S/repos/WorkTrees/proj/feature-x"); rc=$?
expect "$out|$rc" "covered $R/repos/WorkTrees|0" "covered after add"
out=$(run check "$S/other/wt"); rc=$?
expect "$out|$rc" "missing $R/other|10" "non-WorkTrees layout falls back to parent"

echo '{"permissions":{"allow":["X"],"additionalDirectories":["~/zzz"]},"model":"m"}' > "$S/cfg/settings.json"
run add "$S/repos/WorkTrees" >/dev/null
expect "$(jq -c '[.model,.permissions.allow,(.permissions.additionalDirectories|length)]' "$S/cfg/settings.json")" '["m",["X"],2]' "other keys and entries kept"
expect "$(test -f "$S/cfg/settings.json.before-worktree-access" && echo yes)" "yes" "backup written"

echo 'not json' > "$S/cfg/settings.json"
run add "$S/repos/WorkTrees" >/dev/null 2>&1; rc=$?
expect "$rc|$(cat "$S/cfg/settings.json")" "2|not json" "invalid JSON is refused and left alone"

echo "test folder: $S"
exit $fail
