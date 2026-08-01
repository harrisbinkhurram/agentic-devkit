# agentic-devkit

**Stop re-explaining yourself to Claude. Put your terminal setup, your AI skills, and what your
AI knows about you in git — identical on every machine.**

> The repo is called `agentic-devkit`. Some older paths and the variable `MY_WORKFLOW_DIR` still
> say `my_setup`. Same thing.

## In plain language

Claude Code is a smart assistant that starts every conversation as a stranger. It does not know
your projects, your shortcuts, your habits, or which machine it is sitting on. So you explain.
Then you explain again tomorrow, and again on your other laptop.

This repo is the fix. Think of it as **a memory and a toolbox that follow you around**:

- a **toolbox** of shell commands and AI skills, so "review this PR" or "clean up my branches"
  is one phrase instead of ten steps;
- a **memory** of who you are, what your machine is, and what your shorthand means, loaded
  automatically at the start of every conversation;
- all of it **in git**, so a new machine is one command and every change has an undo.

Nothing here is magic. It is plain files plus one trick: **symlinks**. A symlink is a signpost,
not a copy — `~/.claude/skills/some-skill` is a sign that says "the real file is in the repo".
Change the repo, the live skill changes. No reinstall, no copies drifting apart.

## Just ask Claude — paste this in

The fastest way to understand this repo is to let it explain itself. Open Claude Code **in this
repo** and paste:

```text
Read this repo's README.md, CLAUDE.md, and docs/managed-claude.md.

Then, before changing anything:
1. Explain in plain language what this repo is and what installing it would actually
   change on my machine. No jargon — assume I have never heard of a symlink.
2. Check what I already have: is my shell wired up, are skills and agents linked into
   ~/.claude, is my global ~/.claude/CLAUDE.md managed, do I have a private overlay
   repo and a private brain repo?
3. Based on what you found, tell me the single smallest next step for me, and what it
   would cost or risk.

Do not change anything until I say go.
```

It will look at your actual machine and answer for your situation. When you are ready, say
**"set up my Claude"** — that runs the `a_sk_setup_claude` skill, which installs, verifies every
link resolves, and tells you what it did.

Later, useful things to say: **"my Claude config is a mess"** (`a_sk_tame_claude` audits and
repairs it), or **"remember this"** (`a_sk_teach_claude` files what you just taught it in the
right place, permanently).

## Start here: fork it, do not clone it

**Fork on GitHub first, then clone your fork.**

This is a personal setup. The moment you use it you will want to change something: your paths,
your skills, your preferences. On a fork those are just commits on your own repo. On a plain
clone of someone else's repo you cannot push, so your changes pile up locally, and the first
`git pull` that touches the same lines becomes a conflict you did not ask for.

```bash
# 1. Fork on GitHub (button, top right)
# 2. Clone YOUR fork
git clone git@github.com:<you>/agentic-devkit.git ~/agentic-devkit
cd ~/agentic-devkit

# 3. Keep a link to the original so you can pull improvements later
git remote add upstream https://github.com/mahsanamin/agentic-devkit.git
```

## Install

```bash
./install.sh        # wires your shell + links every skill and agent into ~/.claude
source ~/.zshrc     # activate it in this terminal
```

That is the whole install. It is safe to re-run, it never overwrites your shell config, and it
adds exactly one line to your shell rc. Then **restart Claude Code** so it loads the new skills.

Check it worked:

```bash
a_c_workflow_doctor   # green ticks, or it tells you exactly what is wrong
```

## Keeping it up to date

**One command after every pull.** `install.sh` is the update command, not just the install
command — it re-links anything new and rebuilds your generated memory.

```bash
cd ~/agentic-devkit
git pull                # your fork
./install.sh            # re-link skills/agents + rebuild memory
                        # then restart Claude Code
```

If you forked and want improvements from the original:

```bash
git fetch upstream && git merge upstream/main
./install.sh
```

If you also have a private overlay (see below), update it the same way — `git pull` then
`./install.sh` inside that repo.

**When in doubt, `a_c_workflow_doctor`.** It reports broken links, unmanaged files, whether your
machine has an identity, and whether your memory has drifted from its sources. Anything it warns
about tells you the command to fix it.

Two rules that keep updates painless:

- **Edit the repo, never the symlink.** Editing through a link does reach the repo file, but the
  change sits there uncommitted and easy to lose.
- **Never copy a skill into `~/.claude/`.** A copy is a second version that will drift.
  Everything in `~/.claude/skills` and `~/.claude/agents` should be a link.

## What you get

**Terminal and git workflow** — git worktree management, squash-merge-aware branch cleanup,
one-shot commit and push, process and port killers, macOS helpers. All on your PATH.

**AI skills** — Claude Code skills for the repetitive parts: commit, open a PR, review a PR,
raise test coverage, turn a rough idea into a clean automation prompt.

**AI subagents** — 40+ specialists (code review, debugging, refactoring, testing, incident
triage, and a full autonomous build pipeline). Each adapts to whatever project it runs in.

**A managed memory** — your global `~/.claude/CLAUDE.md` becomes a *generated* file, composed
from sources in git instead of hand-typed and stranded on one laptop. See below.

## The part that makes a machine "agentic"

Most setups manage what Claude can *do*. This one also manages what Claude *knows*, in three
layers:

| Layer | Repo | What it holds |
|---|---|---|
| **Core** | this repo (public) | generic skills, agents, shell wiring |
| **Overlay** | your private repo | personal-only skills, **your machine's identity**, **your glossary** |
| **Brain** | your private repo | durable knowledge: projects, decisions, people, setups |

Only the core is required. Add the others when you feel the need.

`a_c_claude_memory` composes your global rules file from those sources:

```bash
a_c_claude_memory status   # what sources exist, is the file in sync?
a_c_claude_memory diff     # exactly what a rebuild would change
a_c_claude_memory build    # write it
```

Everything it writes sits between markers, and **anything you hand-wrote outside them is never
touched**. Two blocks are worth calling out:

- **Machine identity** — your machine gets a name, a stated role, and limits on what it may do
  unattended. Claude can then say which machine it is on instead of guessing.
- **The glossary** — your shorthand mapped to the concrete thing. "review my PRs" resolves to a
  specific skill; "the stack" resolves to your actual containers. It grows from corrections:
  every time the wrong tool got picked, that is a missing row.

The full model, including the private brain and the self-learning loop, is in
[`docs/managed-claude.md`](docs/managed-claude.md).

## How it fits together

```
~/.zshrc
  └─ ~/my_settings/configs.profile     sets MY_WORKFLOW_DIR (points at this repo)
       └─ shell/generic.profile        loads sourced/*.sh, puts scripts/ on PATH

~/.claude/skills/*   ->  symlinks into  this-repo/skills/
~/.claude/agents/*   ->  symlinks into  this-repo/agents/
~/.claude/CLAUDE.md  ->  generated from  this-repo/memory/ + your overlay's machine/
```

One variable, `MY_WORKFLOW_DIR`, is the root. Everything derives from it.

## Where to read next

| File | What it covers |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | The full model and the naming convention |
| [`docs/managed-claude.md`](docs/managed-claude.md) | Managed vs unmanaged, the layers, generated memory, machine identity, the glossary, the private brain |
| [`skills/README.md`](skills/README.md) | The skill catalog |
| [`agents/README.md`](agents/README.md) | The subagent catalog |
| [`docs/worktree.md`](docs/worktree.md) | Worktree helpers |
| [`docs/task.md`](docs/task.md) | The ticket-to-worktree task workflow |
| [`docs/claude-sessions.md`](docs/claude-sessions.md) | The live sessions dashboard |
| [`docs/mac.md`](docs/mac.md) | macOS odds and ends |

## Never commit these

All gitignored by default: `~/my_settings/configs.profile`, `~/.aws_keys`, `~/.my_secrets`, any
`shell/<org>.<machine>.profile`, `.claude/settings.local.json`, and `tools/*/config.env`.
