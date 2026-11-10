# Setting this folder up in T3 Code

**Shortcut:** open a T3 Code thread in this folder and run `/t3-setup`. It
executes every step below that can be run from a terminal or via T3's MCP tools,
fills `.t3/local/env.md` from real output, and stops only at steps that are
UI-only or need facts only you know. The manual steps remain here as the
reference.

Do these in order the first time. Steps 1–2 are one-time per machine; steps 3–8
are one-time per project; step 9 is every driver session.

## 0. Prerequisites

- T3 Code installed and running: the desktop app, or `t3` (see the
  [T3 Code README](https://github.com/pingdotgg/t3code)). `t3 --help` works.
- The provider CLIs you intend to run as workers, installed and signed in —
  T3 controls them through their own CLIs. For the presets in
  `workers.example.json` that means at least one of:
  - Claude: `claude` + `claude auth login`
  - OpenCode: `opencode` + `opencode auth login`
  - (Codex, Cursor, Grok, etc. work the same way if you add presets for them.)
- `gh` installed and logged in: `gh auth status` shows the account the agents
  will commit as.
- This folder is a git repo with a GitHub remote and at least one commit.
- The toolchain your project needs (bun, docker…) installed on this machine.
  Worker worktrees inherit the host's PATH.

## 1. Confirm T3 is running and can see this folder

```sh
t3 --help        # or just open the T3 Code desktop/web app
```

T3 Code does not have a separate "runtime" to start the way Orca does; the app
(or `t3` service) *is* the runtime. Check that a new thread can be created in
this folder.

## 2. Confirm the worker providers can run child tasks

The driver dispatches workers with `delegate_task`, so the providers you chose
must be installed, authenticated, and able to run child tasks. From any T3
thread you can ask the agent to call `orchestrator_capabilities`; it lists each
provider with `canRunChildTask`. A provider with "Provider executable is not
installed" is not ready — install and sign in, then re-check.

## 3. Register this repo as a T3 project

In the T3 app: **Add Project** and pick this folder (or **Clone repository** and
paste the GitHub URL). If the agent is doing this step, it calls
`t3_project_create` with this folder as `workspaceRoot`.

The **worktree setup and archive scripts are already wired**: `t3.json` at the
repo root declares `scripts/t3-setup.sh` with `runOnWorktreeCreate: true` and
`scripts/t3-archive.sh` with `runOnSettle: true`. There is no hook UI and no
"wait-for-setup" policy to set — T3 runs the setup script as part of preparing
each new worktree, before the worker's first turn.

Check: run the setup script once by hand in this main checkout and read the
`.env.local` it writes.

```sh
bash scripts/t3-setup.sh
cat .env.local
```

Expected: `PORT_BASE`, `PORT_WEB`, `PORT_DB`, `COMPOSE_PROJECT_NAME`, and either
a successful dependency install or the line
`no recognised lockfile; skipping install`. If your project needs derived
values (a `DATABASE_URL` built from `PORT_DB`, say), add them in the block
marked `PROJECT-SPECIFIC` in `scripts/t3-setup.sh` now, then re-run. The script
is idempotent and keeps the same block.

## 4. Create the local directories

```sh
mkdir -p .t3/local/human .t3/local/state
cp .t3/env.example.md .t3/local/env.md
cp .t3/workers.example.json .t3/local/workers.json
```

Check: `git status` does **not** list anything under `.t3/local/`. If it does,
`.gitignore` did not take.

## 5. Fill `env.md` and `workers.json`

Edit `.t3/local/env.md` and fill:

- **GitHub** `<owner>/<repo>`
- **Shared account** `yes` if all agents commit through one GitHub login

Then open `.t3/local/workers.json` and set `roles.implementer` and
`roles.reviewer` to presets. Use different vendors if you can, and only presets
whose provider passed step 2. `/t3-workers` shows and switches them.

## 6. Describe the project to the workers

Open `.t3/project.md` and replace every `<...>`. This is the only place the
role prompts get project knowledge from, so be concrete: exact install and test
commands, which tools read `.env.local`, which test suites skip silently, which
files are generated, and what the project's characteristic silent failure looks
like.

Check: `grep -n '<' .t3/project.md` returns nothing but code fences and
markdown.

## 7. Write the design record and the issues

- **`DESIGN.md`** at the repo root. Architecture, contracts, and the reasoning
  behind each decision. Workers treat it as law and never edit it. The driver
  refuses to dispatch without one.
- **GitHub issues**, one per slice. `/t3-slice` files them in the right shape;
  the template is `.github/ISSUE_TEMPLATE/slice.md`. Each body needs:
  - a numbered list of **acceptance criteria** the reviewer can run;
  - a line `Blocked by #<n>, #<m>` (or `Blocked by: none`) — the driver builds
    the DAG from these lines and nothing else.
- Optionally a **PRD** file if the work is large enough to need one; reference
  it from `DESIGN.md`.

Check: `gh issue list --state open --json number,title,body` shows every slice
with a "Blocked by" line.

## 8. Commit the scaffold

First confirm the skills are visible to both agents: `.claude/skills` must be a
symlink to `../.agents/skills` and `ls .claude/skills/` must list the eight
`t3-*` skills. Codex reads repo-level `.agents/skills/` directly.

```sh
git add .gitignore .t3 .agents .claude/skills .github scripts t3.json DESIGN.md
git status                     # nothing under .t3/local/, no .env.local
git commit -m "Add T3 orchestration scaffold"
git push
```

## 9. Start a driver session

In T3, create a **new thread in this project's main checkout** (not a worktree).
Run `/t3-drive`, or paste the entire contents of `.t3/driver.md` as the first
message.

The driver will read `env.md` and `workers.json`, rebuild the DAG from the open
issues, and dispatch up to four ready slices with `delegate_task`. It writes gate
briefs to `.t3/local/human/` and its journal to `.t3/local/state/`.

Check: the first thing a healthy driver does is report the DAG it derived and
which issues it is about to dispatch. If it instead asks for the repo or
`DESIGN.md`, go back to the step that produces that.

## Every later session

- If the previous driver session was compacted or wiped, start a new thread and
  run `/t3-drive` again. Better: run `/t3-handoff` in the old thread first, so
  its intent is written down before you clear. It re-derives state from `gh`
  and `task_status`; the only thing it trusts from disk is `env.md`.
- If a provider runs out of quota mid-run, `/t3-workers <role> <preset>` and
  carry on. The driver reads the file before every dispatch.
- If a worker reports a port collision, the setup script did not run for its
  worktree: check the `t3.json` wiring and the worktree settings.
- Stale port claims live in `~/.cache/t3-portblocks/`. Each file is named by
  its base port and contains the worktree path that owns it. Delete any whose
  path no longer exists.

## What is committed, what is not

| Path                    | Committed | Why                                        |
| ----------------------- | --------- | ------------------------------------------ |
| `.t3/*.md`              | yes       | roles and rules; public-safe               |
| `.t3/project.md`        | yes       | the project's own facts; workers read it   |
| `scripts/t3-*.sh`       | yes       | per-worktree setup/archive scripts         |
| `t3.json`               | yes       | declares those scripts to T3               |
| `DESIGN.md`             | yes       | the contract workers build against         |
| `.agents/skills/`, `.claude/skills` | yes | slash-command wrappers around the prompts |
| `.t3/local/`            | **no**    | env.md, workers.json, gate briefs, journal |
| `.env.local`            | **no**    | per-worktree ports, written by the script  |
