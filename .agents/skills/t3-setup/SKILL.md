---
name: t3-setup
description: Guided first-time setup of this repo for T3 orchestration. Walks .t3/SETUP.md step by step, runs every command it can, fills .t3/local/env.md from real output, and stops only for UI-only steps and facts only the human knows. Use when opening this folder in T3 for the first time, when /t3-drive reports setup is incomplete, or when a provider or the repo has changed.
disable-model-invocation: true
---

# T3 setup, guided

You are setting this repo up for the driver / implementer / reviewer protocol in
`.t3/`. `.t3/SETUP.md` is the authoritative checklist; this skill executes it.
Read `SETUP.md` first, then work through the steps below. **Detect before you
do**: every step starts with a check, and a step whose check already passes is
reported as done and skipped. Re-running this skill must be safe.

## Rules

- Run commands yourself. Do not tell the human to run something you can run.
- Stop and ask only for: UI-only steps (registering the project in the T3 app),
  and facts only the human knows (GitHub owner/repo if no remote, worker
  provider/model choices, whether the GitHub account is shared).
- Never write a credential anywhere. Never edit `.t3/*.md` except `project.md`
  placeholders when the human gives you the content.
- Report each step as `done`, `skipped (already done)`, or `needs you: <what>`.

## Steps

**0. Prerequisites.** Check `t3 --help` (or that the T3 app is running),
`gh auth status`, `git rev-parse --is-inside-work-tree`,
`git remote get-url origin`. If not a repo, `git init -b main`. If no remote,
ask for `<owner>/<repo>` and offer to run `gh repo create ... --private --source
. --push`. Do not create the remote without confirmation: it is outward-facing.

**1. Runtime.** Confirm a new thread can be created in this folder. T3 has no
separate runtime to start; the app (or `t3` service) is it.

**2. Providers.** Call `orchestrator_capabilities` and list each provider's
`canRunChildTask` and constraints. For any provider the human wants as a worker
that reports "executable is not installed", give the exact install + login
command (`claude auth login`, `opencode auth login`, `codex login`, …) and wait;
you cannot log a provider in for them.

**3. Register the project.** If the agent is doing this, call
`t3_project_create` with this folder as `workspaceRoot`. Otherwise it is a UI
step ("Add Project" and pick this folder). Confirm `t3.json` declares the setup
script (`runOnWorktreeCreate: true`) and archive script (`runOnSettle: true`),
then run `bash scripts/t3-setup.sh` here and show the resulting `.env.local`. If
the project needs derived values, ask and add them in the `PROJECT-SPECIFIC`
block of the script, then re-run.

**4. Local dirs.** `mkdir -p .t3/local/human .t3/local/state`; copy
`env.example.md` to `local/env.md` and `workers.example.json` to
`local/workers.json` if absent. Confirm `git status --porcelain .t3/local` is
empty.

**5. env.md and workers.json.** Fill every field in `.t3/local/env.md` from the
captured values; ask for shared-account only. Then open `local/workers.json`,
show the presets, ask which preset each role uses (cross-check step 2), and
write `roles`.

**6. project.md.** `grep -n '<' .t3/project.md`. For each remaining placeholder
section, look at the repo first (lockfiles, compose files, test config, README)
and propose content; ask only what the code cannot tell you, especially "What
this project fails at". Write the answers in.

**7. Design record and issues.** If `DESIGN.md` is missing, write a skeleton
with these headings and one line under each saying what belongs there:
`Purpose`, `Architecture`, `Contracts` (interfaces other slices inherit),
`Decisions` (numbered, each with reasoning), `Non-goals`, `Open questions`.
Then tell the human to fill it and to create slices with `/t3-slice`. Check
`gh issue list --state open --json number,body`; report how many issues carry a
`Blocked by` line.

**8. Skills visible to workers.** Confirm `.claude/skills` is a symlink to
`../.agents/skills` and lists the eight `t3-*` skills. If Codex is one of the
worker providers, note that Codex reads repo-level `.agents/skills/`; suggest
the human confirm once from a Codex thread in a worktree.

**9. Commit.** `git add .gitignore .t3 .agents .claude/skills scripts t3.json
DESIGN.md .github`; show `git status`; confirm nothing under `.t3/local/` or
`.env.local` is staged. Commit with a message like `Add T3 orchestration
scaffold`. Ask before pushing.

## Finish

Print a table of the steps and their status, then the one line the human does
next: open a T3 thread in this main checkout and run `/t3-drive`.
