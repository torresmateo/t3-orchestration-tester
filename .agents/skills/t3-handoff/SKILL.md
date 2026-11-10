---
name: t3-handoff
description: Freeze the current T3 driver thread so the human can start a fresh thread and resume with /t3-drive. Does a final settlement sweep, pushes every unpropagated finding to GitHub, writes .t3/local/state/HANDOFF.md with intent only, stops dispatching, and prints "safe to clear". Use in the driver's thread when context is climbing past the useful zone.
disable-model-invocation: true
---

# Handoff — sweep, journal, freeze

The human wants to clear this thread and continue with a fresh driver. Your job
is to make that lossless. Order matters: **GitHub first, file second, freeze
last.** The file is a convenience; GitHub is the durable store.

Do not start any new dispatch from this point. Finish in-flight processing of
completions you already received, then stop.

## 1. Settlement sweep

For every taskId in your journal that you have not yet reconciled, call
`task_status` and read the result. For every task that has finished since you
last looked, process it now per `.t3/driver.md`: read the PR's latest
`**[reviewer]** VERDICT:` or implementer evidence and take the one action it
implies (dispatch review, dispatch fix, create gate, merge). **Exception:** if
that action is a new dispatch, do not start it — record it as the first line of
intent below. Merges and gates you may still do; they are cheap to resume from.

Live tasks keep running and will wake the *next* driver thread, not this one —
list them in the handoff so they are adopted, not orphaned.

## 2. Propagate

Any finding you hold that is not yet on a GitHub issue: post it now as a
`**[driver]**` comment on the issue it belongs to. Any `DESIGN.md` grooming you
were about to commit: commit it now in its own commit, or drop it. Nothing in
your head survives the clear unless it is in git or on GitHub.

## 3. Write HANDOFF.md

Write `.t3/local/state/HANDOFF.md`. **Intent only** — no state that the next
driver can re-derive. The next driver will re-derive it anyway and a stale
mirror is worse than none. Template:

```markdown
# Driver handoff — <ISO timestamp>

## Was about to
- <the next dispatch or action you did not start, with issue and reason>

## Open escalations
- #<issue>: <gate topic>, brief at .t3/local/human/<file>, waiting since <when>

## Findings not yet acted on
- <anything posted to GitHub in step 2 that still needs a follow-up dispatch>

## Live at freeze
- taskId <id>: <role> #<issue> round <n>
  (re-derive before trusting; listed only so nothing is orphaned)

## Judgment calls the next driver should not relitigate
- <decisions already made and why, one line each>
```

Also refresh `DRIVER-STATE.md` to say only: `See HANDOFF.md`.

## 4. Freeze and report

Print exactly this block and stop:

```
HANDOFF COMPLETE — safe to clear
  live tasks      : <n>   (they keep running; the next driver adopts them)
  open gates      : <n>
  briefs waiting  : <n> in .t3/local/human/
  next            : start a fresh thread here and run /t3-drive
```

Do not take any further action after printing it.
