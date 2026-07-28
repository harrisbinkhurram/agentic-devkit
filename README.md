# agentic-devkit

**Your terminal setup and your AI coding agents, in one git repo, identical on every machine.**

> The repo is called `agentic-devkit`. Some older paths and the local checkout may still say
> `my_setup`. Same thing.

## What problem does this solve?

You collect shell shortcuts, git helpers, Claude Code skills, and custom agents. They end up as
loose files in `~/.claude/` and your shell config. Then:

- You improve something on your laptop. Your desktop never gets it.
- Six months later you cannot tell which of those files still work.
- A new machine means hunting down all the pieces again.
- None of it is in git, so there is no history and no undo.

## What does this do about it?

It puts everything in one git repo, then **symlinks** the AI parts into `~/.claude/`.

A symlink is a pointer, not a copy. So `~/.claude/skills/my-skill` is not a file, it is a
signpost that says "the real file is in the repo". That one detail is what makes the rest work:

- **Edit once, live everywhere.** Change a file in the repo and the live skill changes. No
  reinstall, no copying.
- **`git pull` updates your whole setup.**
- **One command sets up a new machine.**

## Start here: fork it, do not clone it

**Fork the repo on GitHub first, then clone your fork.** This is the low-friction path and the
one to take.

This is a personal setup. The moment you use it you will want to change something: your paths,
your skills, your preferences. On a fork those are just commits on your own repo. On a plain
clone of someone else's repo you cannot push, so your changes pile up locally, and the first
`git pull` that touches the same lines turns into a conflict you did not ask for.

```bash
# 1. Fork on GitHub (button, top right)
# 2. Clone YOUR fork
git clone git@github.com:<you>/agentic-devkit.git ~/agentic-devkit
cd ~/agentic-devkit

# 3. Optional: keep a link to the original so you can pull improvements later
git remote add upstream https://github.com/mahsanamin/agentic-devkit.git
```

Later, to pick up changes from upstream:

```bash
git fetch upstream && git merge upstream/main
```

## Install

```bash
./install.sh        # wires your shell + links every skill and agent into ~/.claude
source ~/.zshrc     # activate it in this terminal
```

That is the whole install. It is safe to re-run: it never overwrites your config, and it adds
exactly one line to your shell rc.

Then **restart Claude Code** so it loads the new skills and agents.

Prefer to be guided rather than run a script blind? Open Claude Code in the repo and say
**"set up my Claude"**. The `a_sk_setup_claude` skill checks the state of your machine first,
runs the right thing, verifies every link actually resolves, and tells Claude what it now has.

After any `git pull`, re-run `./install.sh` to pick up new skills and agents.

## What you get

**Terminal and git workflow** - git worktree management, squash-merge-aware branch cleanup,
one-shot commit and push, process and port killers, macOS helpers. All on your PATH.

**AI skills** - Claude Code skills for the repetitive parts: commit, open a PR, review a PR,
raise test coverage, turn a rough idea into a clean automation prompt.

**AI subagents** - 40+ specialized agents (code review, debugging, refactoring, testing,
incident triage, and a full autonomous build pipeline). Each one adapts to whatever project it
runs in.

**Tools to manage the setup itself** - three skills that install it, clean up a messy `~/.claude`,
and record what Claude learns so it stops forgetting. See
[`docs/managed-claude.md`](docs/managed-claude.md).

## How it fits together

```
~/.zshrc
  └─ ~/my_settings/configs.profile        sets MY_WORKFLOW_DIR (points at this repo)
       └─ shell/generic.profile           loads sourced/*.sh, puts scripts/ on PATH

~/.claude/skills/*   ->  symlinks into  this-repo/skills/
~/.claude/agents/*   ->  symlinks into  this-repo/agents/
```

One variable, `MY_WORKFLOW_DIR`, is the root. Everything derives from it.

## Two things worth knowing

**Edit the repo, never the symlink.** Editing through a link does reach the repo file, but the
change sits there uncommitted and easy to lose. Open the repo.

**Never copy a skill into `~/.claude/`.** A copy is a second version that will drift from the
repo. Everything in `~/.claude/skills` and `~/.claude/agents` should be a link.

## Where to read next

| File | What it covers |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | The full model and the naming convention |
| [`docs/managed-claude.md`](docs/managed-claude.md) | Managed vs unmanaged, the four layers, the private brain, the self-learning loop |
| [`skills/README.md`](skills/README.md) | The skill catalog |
| [`agents/README.md`](agents/README.md) | The subagent catalog |
| [`docs/worktree.md`](docs/worktree.md) | Worktree helpers |
| [`docs/task.md`](docs/task.md) | The ticket-to-worktree task workflow |
| [`docs/claude-sessions.md`](docs/claude-sessions.md) | The live sessions dashboard |
| [`docs/mac.md`](docs/mac.md) | macOS odds and ends |

## Never commit these

All gitignored by default: `~/my_settings/configs.profile`, `~/.aws_keys`, `~/.my_secrets`, any
`shell/<org>.<machine>.profile`, `.claude/settings.local.json`, and `tools/*/config.env`.
