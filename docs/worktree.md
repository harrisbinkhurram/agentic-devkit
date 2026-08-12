# Worktree helpers (`a_g_worktree_*`)

Git worktrees let you have several branches checked out at once, in separate directories, off one
clone. These helpers wrap that with auto-cd, a consistent directory layout, and removal that
refuses to throw away work you have not pushed.

The rule this exists to support: **start a task in a worktree, never branch in the main
checkout.** The main clone stays on its default branch and clean.

```
repos/
├── my-project/                  # the main clone. Stays clean.
└── WorkTrees/
    └── my-project/
        ├── feature-auth/        # branch feature/auth
        ├── bugfix-login/        # branch bugfix/login
        └── PROJ-123-retry/      # branch PROJ-123-retry
```

Slashes in a branch name become dashes in the directory name, so nothing nests.

## Commands

| Command | What it does |
|---|---|
| `a_g_worktree_init <branch> [-b <base>]` | Create a worktree and cd into it. New branch, or check out an existing one. Without `-b` it offers a base-branch picker. |
| `a_g_worktree_list` | List this repo's worktrees with their branch and state |
| `a_g_worktree_switch <name>` | cd to an existing worktree (slash or dash form both work) |
| `a_g_worktree_main` | cd back to the main clone |
| `a_g_worktree_review <pr\|branch>` | Make a throwaway worktree to review someone's branch or PR |
| `a_g_worktree_update` | Fetch the default branch and rebase onto it, auto-stashing uncommitted changes first |
| `a_g_worktree_remove <name> [-v\|-f]` | Remove a worktree. Warns on unpushed commits. `-v` verifies it was merged first; `-f` skips every check. |
| `a_g_worktree_conclude <name>` | `remove --verify`, for a worktree whose work has landed |
| `a_g_worktree_doctor` | Diagnose a broken or confusing worktree state |
| `a_g_worktree_prune` | Clear stale worktree registrations left behind by deleted directories |

Related, in `sourced/git.sh` and `scripts/`: `a_g_push`, `a_g_ship`, `a_g_main`, `a_g_reset`,
`a_g_branch_cleanup`, `a_g_branch_delete`.

## Where they come from

These are **shell functions** in [`sourced/worktree.sh`](../sourced/worktree.sh), auto-sourced by
`generic.profile`. They have to be functions rather than scripts because a script runs in a
subshell and cannot change the directory of the shell that called it. That is what gives you the
auto-cd.

Two of them (`a_g_worktree_init`, `a_g_worktree_remove`) also exist as standalone scripts in
`scripts/`, for use from a non-interactive context such as Claude Code's Bash tool where the
profile is not sourced:

```bash
bash scripts/a_g_worktree_init PROJ-123-retry
```

That form does **not** cd. Read the worktree path it prints and use that path in every following
command.

## Examples

```bash
a_g_worktree_init feature/auth-improvements      # new branch, base picked interactively
a_g_worktree_init feature/new-api -b develop     # new branch off develop, no picker
a_g_worktree_init PROJ-123-retry                 # ticket-named, the usual case

a_g_worktree_list
a_g_worktree_switch feature-auth-improvements    # dash form
a_g_worktree_switch feature/auth-improvements    # slash form, same worktree

a_g_worktree_update                              # rebase this worktree onto latest main

a_g_worktree_remove feature/auth-improvements    # warns if anything is unpushed
a_g_worktree_remove feature/auth -v              # only if merged (squash-merge aware)
a_g_worktree_remove feature/auth -f              # force, no checks
```

## What stops you losing work

- **Unpushed-commit warning** before any removal.
- **Merge verification** under `-v`, which detects squash merges too, not just fast-forwards.
- **Ticket verification**: pulls ticket keys out of the commits and checks whether they appear in
  the default branch.
- **Protected branches**: never removes `main`, `master`, `staging`, `develop`, `prod`, or
  `production`.
- **Auto-stash** before `a_g_worktree_update` rebases.

## Troubleshooting

**Auto-cd does not happen.** You are running the script, not the function. Open a new shell (or
`source ~/.zshrc`) so `generic.profile` loads the functions. From a non-interactive tool, auto-cd
is not possible: use the path the script prints.

**"Worktree not found".** The command prints the available worktrees. Use one of those names;
both the slash and dash forms are accepted.

**A worktree directory was deleted by hand.** Git still has it registered. Run
`a_g_worktree_prune`, then `a_g_worktree_doctor` if anything still looks wrong.

## Unity projects: worktrees show up in Unity Hub

A git worktree of a Unity repo is a complete Unity project — it has `Assets/`, `Packages/` and
`ProjectSettings/`. Unity Hub will happily open it, but it never discovers the folder on its own;
normally you have to click **Add project from disk** for every worktree.

`a_g_worktree_init` now does that step for you. After the worktree is created it calls
[`scripts/a_s_unity_hub`](../scripts/a_s_unity_hub), which registers the project in Unity Hub's
list. `a_g_worktree_remove` takes the entry back out. Both are no-ops on repos that are not Unity
projects, so nothing changes for everyone else.

The helper is also usable directly:

```bash
a_s_unity_hub add    ~/repos/WorkTrees/g-family_sort/carsort-glass-cover
a_s_unity_hub remove ~/repos/WorkTrees/g-family_sort/carsort-glass-cover
a_s_unity_hub sync                               # sweep this workspace's WorkTrees dir
a_s_unity_hub sync   ~/repos/WorkTrees --prune   # ...and drop entries whose folder is gone
a_s_unity_hub list
```

With no root, `sync` uses the `WorkTrees` directory belonging to the repo you are standing in —
the sibling of its main checkout, which is where `a_g_worktree_init` puts worktrees. That works
from inside a worktree too. Run it after anything that creates worktrees behind the helpers' back,
such as `ar-taskflow` or `ar-taskflow-resume`.

### Things worth knowing

Unity Hub has no CLI for adding a project — its `--headless` interface only covers editors and
install paths — so the helper edits the Hub's own project list at
`~/Library/Application Support/UnityHub/projects-v1.json`, atomically, keeping a `.bak`.

**The Hub reads that file only at launch** and rewrites it from memory afterwards. So a project
added while the Hub is running appears the next time you open the Hub. Pass `--restart` to quit
and reopen it right away; the quit happens *before* the write, because the Hub flushes its
in-memory list on the way out and would otherwise overwrite the change.

**The Hub names a project after its folder**, and re-derives that name at every launch for any
entry it did not rename itself — an injected display name does not survive. That is fine in
practice: a worktree folder is already the branch name with slashes turned into dashes, so
`carsort/feature/glass-cover` shows up as `carsort-feature-glass-cover`. If you want a different
name, rename the project inside the Hub. That sticks, and the helper never overwrites a title,
favourite flag or build target you set there.

For a worktree, the Unity cloud and organization fields are inherited from the main checkout's
entry, so the Hub links the worktree to the same Unity project rather than treating it as a new one.

## Cleaning up in bulk

`a_r_l_worktree_cleaner` sweeps a whole repo: it removes only the provably-done worktrees (branch
merged, PR merged, or remote branch gone with nothing unpushed), prunes stale registrations, and
leaves anything with real work alone. See [`../skills/README.md`](../skills/README.md).
