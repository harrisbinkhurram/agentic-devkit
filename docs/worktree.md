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

## Cleaning up in bulk

`a_r_l_worktree_cleaner` sweeps a whole repo: it removes only the provably-done worktrees (branch
merged, PR merged, or remote branch gone with nothing unpushed), prunes stale registrations, and
leaves anything with real work alone. See [`../skills/README.md`](../skills/README.md).
