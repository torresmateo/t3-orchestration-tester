#!/usr/bin/env bash
# T3 Code worktree archive script — runs when a worktree's thread settles.
# Declared in t3.json (`runOnSettle: true`).
#
# Two jobs, in this order:
#   1. Tear down this worktree's Docker stack, including its volumes, if the
#      project has a compose file. A reviewer worktree is recreated fresh every
#      round, and a leftover volume would outlive it and be inherited by the
#      next worktree that claims the same port block — handing a "clean" review
#      environment a previous round's database. That is precisely the class of
#      bug a fresh worktree exists to catch.
#   2. Release the port block so it returns to circulation immediately rather
#      than waiting to be reaped as stale.
set -euo pipefail

WORKTREE="$(pwd -P)"
CLAIMS="${XDG_CACHE_HOME:-$HOME/.cache}/t3-portblocks"

has_compose() {
  for f in compose.yaml compose.yml docker-compose.yaml docker-compose.yml; do
    [ -f "$WORKTREE/$f" ] && return 0
  done
  return 1
}

# Best-effort: the stack may never have been started, and a torn-down Docker
# daemon must not fail the hook and strand the port claim below.
if [ -f "$WORKTREE/.env.local" ] && has_compose && command -v docker >/dev/null 2>&1; then
  echo "t3-archive: docker compose down -v"
  docker compose --env-file "$WORKTREE/.env.local" down -v --remove-orphans >/dev/null 2>&1 || true
fi

# ---- PROJECT-SPECIFIC: other per-worktree resources to release ---------------
# e.g. kill a dev server pidfile, drop a scratch database, remove a temp dir.
# ------------------------------------------------------------------------------

[ -d "$CLAIMS" ] || exit 0

for f in "$CLAIMS"/*; do
  [ -f "$f" ] || continue
  if [ "$(cat "$f")" = "$WORKTREE" ]; then
    rm -f "$f"
    echo "t3-archive: released PORT_BASE=$(basename "$f")"
  fi
done
