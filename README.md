# Snip

A small URL shortener with a JSON API, built as a realistic target for testing
agent orchestration harnesses. Work is split into GitHub issues ("slices") that
a [T3](.t3/README.md) driver dispatches to implementer and reviewer agents in
isolated worktrees — using T3 Code's MCP tools (`delegate_task`,
`watch_pull_request`) rather than a CLI.

## Quickstart

Requires [Bun](https://bun.sh) 1.3+ and Docker.

```sh
bash scripts/t3-setup.sh       # claims a port block, writes .env.local, installs deps
bun run db:up                # Postgres on $PORT_DB
bun run test                 # expect "0 skip"
bun run start                # http://localhost:$PORT_WEB
curl localhost:$(grep ^PORT_WEB .env.local | cut -d= -f2)/healthz
# {"ok":true,"db":"up"}
bun run db:down              # stop Postgres and delete its volume
```

Use `bun run test`, not bare `bun test`: the latter does not load `.env.local`
and quietly skips every database test.

## API

See [`DESIGN.md`](DESIGN.md) §Contracts. Today only `GET /healthz` exists; the
rest arrives slice by slice.

## Orchestration

- [`.t3/README.md`](.t3/README.md): how the driver, implementers and reviewers
  work together
- [`.t3/SETUP.md`](.t3/SETUP.md): wiring this repo into T3 Code
- [`.t3/project.md`](.t3/project.md): what workers need to know about Snip
- Slices: [issues labelled `slice`](../../issues?q=label%3Aslice)
