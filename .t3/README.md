# T3 orchestration for this repo

Agent orchestration lives here: a **driver** walks an issue DAG and dispatches
**implementers** and **reviewers** into isolated worktrees, using T3 Code's MCP
tools (`delegate_task`, `watch_pull_request`, …) instead of a CLI. The prompts
are the contract between those roles. They are project-agnostic; everything
specific to this codebase goes in `project.md`.

This is a direct port of the `.orca/` orchestration scaffold: same roles, same
DAG-from-issues model, same fresh-worktree review, same gate discipline. The one
structural difference is **how a worker is started and settled** — an MCP tool
call that wakes the driver on completion, rather than an `orca` CLI
task/worker/gate lifecycle.

```
.t3/
  README.md          ← you are here
  SETUP.md           step-by-step: wiring this folder up in T3
  driver.md          role, limits, protocol, escalation policy (MCP-based)
  implementer.md     worker prompt: build one slice
  reviewer.md        worker prompt: verify one PR, fresh worktree
  project.md         what THIS project is and how it fails — fill in before use
  env.example.md     template for the machine-specific bindings
  workers.example.json  template for per-role provider/model presets
  ../.agents/skills/ slash-command wrappers (see "Skills" below)
  local/             GITIGNORED — never committed
    env.md             filled-in copy of env.example.md
    workers.json       which provider/model each role runs; edit between waves
    human/             for the operator: gate briefs, decisions
    state/             for the next driver: DRIVER-STATE.md, HANDOFF.md
```

## The split, and why it is where it is

Everything in `.t3/` except `local/` is committed and public-safe: it describes
roles and rules, not this machine and not one person's run.

`local/` holds the two things that must not be:

- **`env.md`** — the GitHub repo and the shared-account flag. Not secret, but
  meaningless to anyone who forks this. (Unlike Orca there is no repo UUID or
  Run id: a T3 driver thread is already bound to its project.)
- **`human/` and `state/`** — what the driver writes *for you* (gate briefs) and
  *for the next driver* (journal, handoff). Throwaway; they accumulate fast.

## Where the project-specific knowledge goes

The three role prompts never name a framework, a test runner, or a port. They
tell workers to read `.t3/project.md`, which is where you record:

- what the project is, in one paragraph;
- how to install, run, and test it in a fresh worktree;
- the environment facts that bite (which files load which env, which suites
  skip silently, which generated files must not be hand-edited);
- the project's characteristic failure modes — the bugs a reviewer should push
  on hardest.

Keep `project.md` current. It is the one file where a stale line costs a whole
review round.

## Setup

See `SETUP.md`. The short version: register the repo in T3 (the `t3.json` at the
repo root already declares the per-worktree setup and archive scripts), fill
`local/env.md`, `local/workers.json` and `project.md`, then paste `driver.md`
into a T3 thread in the main checkout (or run `/t3-drive`).

## Skills

The prompts above are the source of truth. The skills under `.agents/skills/`
(symlinked from `.claude/skills/` so Claude and Codex both see them) wrap those
prompts as slash commands; none of them restates a rule.

| Skill           | Run it in                        | What it does                                                    |
| --------------- | -------------------------------- | --------------------------------------------------------------- |
| `/t3-setup`     | any thread, main checkout        | executes `SETUP.md`, fills `local/env.md`, stops at UI steps    |
| `/t3-drive`     | a T3 thread, main checkout       | preflight, adopt `HANDOFF.md`, then follow `driver.md`          |
| `/t3-handoff`   | the driver's thread              | sweep, push findings to GitHub, write `HANDOFF.md`, freeze      |
| `/t3-workers`   | your thread                      | show or switch provider/model per role; driver picks it up next dispatch |
| `/t3-gate`      | your thread                      | show pending gate briefs, take your decision, resolve on GitHub |
| `/t3-slice`     | your thread                      | file issues in the shape the driver parses                      |
| `/t3-implement` | a worker worktree                | run `implementer.md` by hand for one issue                      |
| `/t3-review`    | a fresh worktree on the PR branch| run `reviewer.md` by hand for one PR                            |

The context-window loop: when the driver's context climbs, run `/t3-handoff` in
its thread, wait for `safe to clear`, start a fresh thread and run `/t3-drive`.
Nothing is lost because findings go to GitHub before the file is written.
