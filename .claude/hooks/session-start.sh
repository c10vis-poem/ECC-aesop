#!/bin/bash
# Auto-bootstrap the full ECC/Prime-agent multi-repo stack on every fresh
# session/container. Installs are idempotent and safe to re-run; heavy
# (multi-minute) so this runs async — session starts immediately, stack
# comes up in the background.
set -uo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

echo '{"async": true, "asyncTimeout": 590000}'

SCRIPT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}/scripts/bootstrap-prime-agent-stack.sh"
if [ -x "$SCRIPT" ]; then
  bash "$SCRIPT" >> "${CLAUDE_PROJECT_DIR:-.}/.session-start-bootstrap.log" 2>&1
fi
