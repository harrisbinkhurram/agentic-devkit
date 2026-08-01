## This machine is managed

Every file under `~/.claude/skills/` and `~/.claude/agents/` is a **symlink into a git repo**.
Edit the repo and commit there. Never edit through a link, and never drop a real file into
`~/.claude/` — a real file there is unmanaged, invisible to every other machine, and lost on a
rebuild.

This rules file is **generated**. The region between the `agentic-devkit: managed memory`
markers is composed from source files by `a_c_claude_memory build`. Editing inside the region
works until the next build, then it is gone. Edit the source listed at the top of the region,
then run `a_c_claude_memory build`. Anything outside the markers is hand-written and is never
touched by the tooling.

### Identity — always say which machine you are on

The machine's name and role are in the **Machine** section below. Say that name whenever the
host is even slightly in question: asked who or where you are, asked what you can see, starting
work that touches machine-specific state (paths, keys, launchd jobs, containers, mounted
volumes), or reporting that something was installed or changed here. More than one machine runs
this setup; a session that does not name its host cannot be placed.

### Glossary first — resolve the shorthand before acting

The **Glossary** section below maps the user's shorthand to the concrete thing: which repo,
which skill, which command, which path. When a request uses a term that appears there, follow
the glossary instead of guessing or searching. If a term is clearly glossary material and is
missing, say so and offer to add it — the glossary is meant to grow.

### Naming — one scheme

| Marker | Kind |
|---|---|
| `a_sk_*` | on-demand skill |
| `a_r_*` / `a_r_l_*` | routine (scheduled/unattended; `l_` = local-only) |
| `a_sag_*` | subagent |
| `a_c_*` | user-facing command |
| `a_s_*` | helper script |
| `a_g_*` | git command |

The full glossary of markers lives in the devkit's `CLAUDE.md`. Do not invent a second scheme.

### Knowledge placement — where a new fact goes

Project-specific guidance belongs **in that project's repo** (`CLAUDE.md`, `.claude/agents/`,
`.claude/skills/`) so it travels with the checkout. Never write it to
`~/.claude/projects/<project>/memory/` — that is one machine only and divorces the decision from
the code it governs.

Anything cross-project, most specific wins:

| What it is | Where it goes |
|---|---|
| A fact about a project, person, or past decision | the brain |
| A term whose meaning implies an action | the glossary |
| A reusable procedure | a skill or agent in a devkit repo |
| A one-line always-on rule | a rules source file, then rebuild |
| Anything else | nowhere. Session-only, let it go. |

`a_sk_teach_claude` makes this call and writes the result in the right place. Prefer it over
deciding by hand.
