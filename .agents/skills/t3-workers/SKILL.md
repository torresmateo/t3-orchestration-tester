---
name: t3-workers
description: View or switch which provider and model each T3 role (implementer, reviewer) uses, via presets in .t3/local/workers.json. Use between driver waves when one provider runs out of quota or misbehaves, to add a preset for a new provider, or to check that the chosen providers can run child tasks. Args - none to show; "<role> <preset>" to switch; "add <preset> <providerInstanceId> <model> [optionId=value ...]" to define one.
disable-model-invocation: true
---

# Workers

`.t3/local/workers.json` decides which provider and model each role runs on. The
driver reads it **before every `delegate_task`**, so a change here takes effect
on the next worker it starts, with no driver restart. This skill is a safe
editor for that file.

## No arguments — show

1. If the file is missing, copy `.t3/workers.example.json` to it and say so.
2. Parse it. Print two tables:
   - **Roles**: role, preset, providerInstanceId, model, options.
   - **Presets**: every preset, marked `active` if a role uses it.
3. Call `orchestrator_capabilities`. For each preset's `providerInstanceId`,
   report `ready` (`canRunChildTask: true`), `not installed` / `disabled`, or
   `unknown`. A role pointing at a provider that cannot run child tasks is the
   most likely cause of "dispatch failed to launch"; say so plainly. Also flag
   any preset whose model or option is not in the provider's list.
4. Warn if implementer and reviewer share the same provider **and** model: the
   reviewer then shares the implementer's blind spots.

## `<role> <preset>` — switch

- Validate: role is `implementer` or `reviewer`; preset exists. Refuse
  otherwise and print the preset list.
- Write the change with a JSON-preserving edit (keep key order and comments).
- Print before → after for that role.
- Then say exactly when it takes effect, because this is the part people get
  wrong:
  - **Reviewer**: next review round, on every slice. Reviewers are fresh
    worktrees each round, so the switch is immediate.
  - **Implementer**: next *new slice* only. A fix round re-dispatch uses the
    preset read at that dispatch, so it will also pick up the switch; but an
    already-running worker keeps its provider.
- If the driver is running, remind the human it needs no restart.

## `add <preset> <providerInstanceId> <model> [optionId=value ...]` — define

- `providerInstanceId` and `model` must match `orchestrator_capabilities`
  exactly (case-sensitive). `optionId=value` pairs are optional and go under
  `options` (e.g. `effort=high`, or `variant=max`).
- If the provider is not in `orchestrator_capabilities` or reports a constraint,
  say so as a warning, not an error: adding a preset for a provider you are
  about to install is exactly why this command exists.
- Do not switch a role to it; that is a separate, deliberate command.

## Never

- Never edit `.t3/env.example.md` or `.t3/workers.example.json`; those are the
  committed templates.
- Never start, stop, or cancel a worker. Report; the driver acts.
