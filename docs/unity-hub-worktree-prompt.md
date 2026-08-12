# Handoff prompt: make worktrees appear in Unity Hub

Give the block below to a teammate. They paste it into Claude Code, in any terminal, from inside
one of their Unity repos. It is written so Claude asks them about their own setup first, instead of
assuming this machine's paths or skill names.

---

```text
I work on a Unity project and I use git worktrees. Every time I make a new worktree, Unity Hub
does not know about it, so I have to open the Hub and click "Add project from disk" by hand.

Build me a small tool that does this step for me, plus a way to run it as part of my normal
worktree workflow.

Before you write anything, ask me these three questions and wait for my answers:

1. Where do my worktrees live on disk? Give me an example path.
2. What creates them? A shell helper, a skill such as ar-taskflow or ar-taskflow-resume, or plain
   "git worktree add"? If I use ar-taskflow, read its config and its scripts yourself and tell me
   what you found instead of asking me to describe it.
3. Do I want the tool to hook into the worktree command automatically, or do I want to run it by
   hand after creating a worktree?

Then build it. What it needs to do:

  add <path>      register one Unity project folder in Unity Hub
  remove <path>   take it back out
  sync [<root>]   scan a worktrees root, register every Unity project under it, and with --prune
                  also drop entries whose folder no longer exists
  list            show what Unity Hub currently has

Facts I already checked, so you do not need to rediscover them. Please verify anything you depend
on, but start from here:

- Unity Hub has no command line option for adding a project. Its --headless interface only covers
  editors and install paths. So the tool has to edit the Hub's own project list, which on macOS is
  a single JSON file at "~/Library/Application Support/UnityHub/projects-v1.json". The shape is
  {"schema_version":"v1","data":{"<absolute project path>":{...}}}. Copy the field layout from an
  entry the Hub already wrote. Write the file atomically and keep a backup copy.
- A git worktree of a Unity repo is a complete Unity project. It has Assets, Packages and
  ProjectSettings, so the Hub can open it directly. Nothing needs to be copied or generated.
- Read the editor version and changeset from "<project>/ProjectSettings/ProjectVersion.txt", from
  the m_EditorVersion and m_EditorVersionWithRevision lines.
- Unity Hub reads that JSON file only when it launches, and it rewrites the file from memory while
  it runs. So a change made while the Hub is open shows up the next time the Hub is started. If the
  tool offers a --restart option, it must quit the Hub BEFORE writing and reopen it after. Quitting
  after the write can lose the change, because the Hub writes its in memory list on the way out.
- Unity Hub names a project after its folder, and it works that name out again at every launch for
  any entry it did not rename itself. So do not try to inject a nicer display name, it will not
  survive. A worktree folder name is usually already the branch name with slashes turned into
  dashes, which reads fine. If I want a custom name I will rename the project inside the Hub, and
  the tool must never overwrite a name, favourite flag or build target that I set there. In
  general: when an entry already exists, its existing values win.
- For a worktree, copy the Unity cloud and organization fields (things like cloudProjectId,
  organizationId, localProjectId, projectName) from the main checkout's entry in the same file.
  That makes the Hub treat the worktree as the same Unity project instead of a new one. You can
  find the main checkout with "git -C <worktree> rev-parse --git-common-dir" and taking its parent
  directory.

Requirements:

- If a path is not a Unity project, meaning it has no ProjectSettings/ProjectVersion.txt, skip it
  quietly with no error. That way the tool can be called for every worktree without checking the
  project type first.
- Running it twice in a row must be safe and must change nothing the second time.
- Never touch Unity Hub entries that sit outside the worktrees root I gave you.
- Follow whatever conventions my setup already uses for script names, locations and help output.
  Look at my existing scripts first and match them.

Test it before you tell me it works. Do not test against my real Unity Hub file. Make a throwaway
git repo with a fake ProjectSettings/ProjectVersion.txt and point the tool at a fake HOME, then
check: a Unity worktree gets an entry, a non Unity worktree gets none and no error, removing the
worktree removes the entry, and running sync twice leaves the file unchanged. After that, run it
once against my real setup and show me the resulting list.

Finally, write a short section in my project or tooling docs explaining how to use it and the two
Unity Hub behaviours above that surprise people: the list is only read at launch, and injected
display names do not stick.
```

---

## What it looks like on this machine

For reference, the version built here is [`../scripts/a_s_unity_hub`](../scripts/a_s_unity_hub),
hooked into `a_g_worktree_init` and `a_g_worktree_remove`. See
[`worktree.md`](worktree.md#unity-projects-worktrees-show-up-in-unity-hub).

A teammate whose worktrees are created by `ar-taskflow` rather than `a_g_worktree_init` will get a
different hook point, which is why the prompt asks rather than assumes.
