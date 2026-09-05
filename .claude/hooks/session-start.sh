#!/bin/bash
# Auto-bootstrap ECC itself on every fresh session/container. Install is
# idempotent and safe to re-run; heavy (multi-minute) so this runs async —
# session starts immediately, ECC comes up in the background.
#
# Everything outside ECC itself (Honey, code-review-graph, notebooklm-py,
# OmniRoute, terrestrial-brain) is orchestrated separately by aesop-xi's own
# hook/dispatcher, not this one.
set -uo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

echo '{"async": true, "asyncTimeout": 590000}'

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
SCRIPT="$PROJECT_DIR/scripts/bootstrap-prime-agent-stack.sh"
LOG="$PROJECT_DIR/.session-start-bootstrap.log"

if [ -x "$SCRIPT" ]; then
  bash "$SCRIPT" >> "$LOG" 2>&1
fi

# Commit + push the log so proof this ran survives this (disposable) session's
# container. Best-effort — never fails the session over this.
(
  cd "$PROJECT_DIR" \
    && git add -f "$(basename "$LOG")" \
    && git commit -q -m "chore: session-start bootstrap log $(date -u +%Y-%m-%dT%H:%M:%SZ)" -- "$(basename "$LOG")" \
    && git push -q origin main
) >> "$LOG" 2>&1 || echo "[bootstrap] log commit/push failed — see above" >> "$LOG" 2>&1
