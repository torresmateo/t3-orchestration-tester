---
name: t3-drive
description: Become the T3 driver for this repo. Runs preflight (env.md, project.md, DESIGN.md, t3.json, worker providers), adopts a HANDOFF.md left by a previous driver session, then follows .t3/driver.md verbatim. Use in a T3 thread in the MAIN checkout to start or resume driving; the resume path after /t3-handoff and a fresh thread.
disable-model-invocation: true
---

# Drive

You are about to become the **driver** described in `.t3/driver.md`. That file
is the protocol and you will follow it word for word. This skill only adds a
preflight and a resume path.

## 1. Load references

- `cat .t3/driver.md` — read all of it, every session, even if you think you
  remember it.
- `cat .t3/README.md` — how the pieces fit. `driver.md` wins on policy.

## 2. Preflight — refuse to dispatch if any fails

| Check | How | On failure |
| --- | --- | --- |
| In main checkout | `git branch --show-current` is the default branch and `git rev-parse --show-toplevel` is the project root, not a worktree subdir | stop; tell the human where you are |
| env.md exists, no `<...>` | `grep -c '<' .t3/local/env.md` is 0 | tell the human to run `/t3-setup` |
| project.md filled | `grep -c '<' .t3/project.md` is 0 (code fences aside) | gate: workers cannot be sent into an undescribed project |
| workers.json valid | `jq -e .roles.implementer,.roles.reviewer .t3/local/workers.json` and both name existing presets | tell the human to run `/t3-workers` |
| DESIGN.md exists | `test -f DESIGN.md` | gate: human writes the first version |
| Setup script wired | `test -f t3.json` and it has a script with `runOnWorktreeCreate: true` | tell the human: SETUP.md step 3 |
| Worker providers ready | call `orchestrator_capabilities`; each role's `providerInstanceId` reports `canRunChildTask: true` | tell the human which provider to install/authenticate (SETUP.md step 2) |

## 3. Adopt a handoff, if one exists

If `.t3/local/state/HANDOFF.md` exists, a previous driver froze cleanly:

1. Read it. It contains **intent only**: what was about to happen, open
   escalations, findings not yet propagated to GitHub, and the list of taskIds
   that were live at freeze time.
2. Re-derive every fact it mentions from `gh` and `task_status` before acting:
   the `**[reviewer]** VERDICT:` count on each open PR, and each live task's
   status. Where the file and reality disagree, reality wins.
3. Reconcile every task it lists: finished ones get processed per `driver.md`;
   live ones are already waking this thread when they finish.
4. Propagate any unpropagated finding to its GitHub issue **now**.
5. Rename the file to `HANDOFF-<timestamp>-adopted.md` so a later resume does
   not adopt it twice.

If there is no `HANDOFF.md` but `DRIVER-STATE.md` exists, treat it the same way
but with less trust: it may be mid-wave.

## 4. Drive

Follow `.t3/driver.md` from its "Start here" section. Everything about limits,
settlement, escalation, per-issue protocol, hard rules and the journal is
defined there, not here.

Two additions for the human's benefit:

- At every wave boundary print a **five-line status**: ready issues, active
  dispatches with round numbers, open gates, briefs waiting in
  `.t3/local/human/`, and the next thing you intend to do.
- If the human runs `/t3-handoff` in this thread, stop dispatching and follow
  that skill. Do not resist it.
