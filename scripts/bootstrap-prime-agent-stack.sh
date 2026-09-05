#!/usr/bin/env bash
# Bootstrap ECC itself in a fresh session/container — nothing else.
#
# ECC's job is installing ECC: its own skills, agents, hooks, and dashboard.
# Attaching other repos/tools (Honey, code-review-graph, notebooklm-py,
# OmniRoute, terrestrial-brain, etc.) is the orchestration layer's job
# (aesop-xi's scripts/bootstrap-stack.sh), not this script's — those steps
# used to live here and have been moved out.
#
# Every session gets a fresh container: nothing installed by a previous
# session survives (npm/uv packages, ~/.claude state, running servers).
# This script rebuilds ECC from source each time.
#
# Usage: bash scripts/bootstrap-prime-agent-stack.sh [base-dir]
#   base-dir is unused by this script now (kept as a no-op positional arg
#   for callers that still pass it, e.g. aesop-xi's dispatcher).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ECC_ROOT="$(dirname "$SCRIPT_DIR")"

log() { echo "[bootstrap] $*"; }

# --- 0. Sync this repo to origin/main before doing anything else ----------
log "Syncing ECC-aesop to origin/main ..."
git -C "$ECC_ROOT" fetch origin main 2>&1 | sed 's/^/  /' \
  && git -C "$ECC_ROOT" checkout -B main origin/main 2>&1 | sed 's/^/  /' \
  || log "sync to main failed — continuing with whatever's on disk"

# --- 1. ECC itself: full profile into ~/.claude ---------------------------
log "Installing ECC (full profile) into ~/.claude ..."
bash "$ECC_ROOT/install.sh" --profile full --target claude || log "ECC install failed — see output above"

# --- 2. ECC dashboard: xdg-open shim (headless containers) + start --------
if ! command -v xdg-open >/dev/null 2>&1; then
  log "Shimming xdg-open (no browser in this container) ..."
  printf '#!/bin/sh\nexit 0\n' > /usr/local/bin/xdg-open
  chmod +x /usr/local/bin/xdg-open
fi
log "Starting ECC dashboard (:3456) ..."
nohup npm --prefix "$ECC_ROOT" run dashboard:web < /dev/null > "$ECC_ROOT/.bootstrap-dashboard.log" 2>&1 &
disown

cat <<'EOF'

[bootstrap] Done. Running now:
  - ECC dashboard: http://127.0.0.1:3456

ECC's own 280+ skills / 70+ agents are installed and active. Everything
outside ECC itself (Honey, code-review-graph, notebooklm-py, OmniRoute,
terrestrial-brain, dashboard-adjacent siblings) is orchestrated separately —
see aesop-xi/scripts/bootstrap-stack.sh.
EOF
