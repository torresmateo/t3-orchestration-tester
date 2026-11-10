# T3 bindings — template

Copy to `.t3/local/env.md` and fill in. That path is gitignored.

These are the facts a driver cannot re-derive from `gh` or its own thread. In T3
there is no repo UUID and no Run id to bind — a driver thread is already in its
project, and `delegate_task` defaults to the parent project. So this file is
deliberately tiny.

---

## Repo

- GitHub: `<owner>/<repo>`
  (Derivable from `git remote`, but keep it explicit so the driver never has to
  guess which remote is the orchestration target.)

## Account note

If every agent commits through the same GitHub account, GitHub refuses a formal
approval from the PR author. Verdicts are then PR **comments** headed
`**[reviewer]** VERDICT: approve|request_changes`, and no green check will ever
appear. Record which applies:

- Shared account: `yes | no`

## Worker models

Not here. They live in `.t3/local/workers.json` (copy of
`.t3/workers.example.json`) so they can be switched between waves without
touching this file. View or change with `/t3-workers`. The driver re-reads that
file before every dispatch.
