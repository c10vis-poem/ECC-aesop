#!/usr/bin/env bash
# Bootstrap the full ECC/Prime-agent multi-repo stack in a fresh session/
# container — everything installed, wired, and started this session, in one
# pass, so no session has to re-derive or re-explain it by hand.
#
# Every session gets a fresh container: nothing installed by a previous
# session survives (npm/uv packages, ~/.claude state, running servers,
# the local Postgres instance). This script rebuilds all of it from source.
#
# Usage: bash scripts/bootstrap-prime-agent-stack.sh [base-dir]
#   base-dir defaults to the directory ECC-aesop itself was cloned into —
#   the directory every sibling repo is expected alongside. A repo not
#   present in this session is skipped, not fatal.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ECC_ROOT="$(dirname "$SCRIPT_DIR")"
BASE_DIR="${1:-$(dirname "$ECC_ROOT")}"

log() { echo "[bootstrap] $*"; }
skip() { echo "[bootstrap] skip: $* (not cloned in this session)"; }

# --- 1. ECC itself: full profile into ~/.claude ---------------------------
log "Installing ECC (full profile) into ~/.claude ..."
bash "$ECC_ROOT/install.sh" --profile full --target claude || log "ECC install failed — see output above"

# --- 2. Skill repos: use each repo's own linker where it has one ----------
mkdir -p "$HOME/.claude/skills" "$HOME/.agents/skills"

if [ -x "$BASE_DIR/NovA-skills/scripts/link-skills.sh" ]; then
  log "Linking NovA-skills (repo's own script) ..."
  bash "$BASE_DIR/NovA-skills/scripts/link-skills.sh"
else
  skip "NovA-skills"
fi

link_flat_skills_dir() {
  # For repos with a skills/ dir but no linker script of their own.
  local repo="$1" src="$BASE_DIR/$1/skills"
  if [ ! -d "$src" ]; then skip "$repo"; return; fi
  log "Linking skills from $repo ..."
  for d in "$src"/*/; do
    name="$(basename "$d")"
    for dest in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
      target="$dest/$name"
      [ -e "$target" ] && [ ! -L "$target" ] && rm -rf "$target"
      ln -sfn "${d%/}" "$target"
    done
  done
}
link_flat_skills_dir "obsidian-skills"

if [ -f "$BASE_DIR/NoVa-reverse-skill/README_AI.md" ]; then
  log "NoVa-reverse-skill: refreshing tool index ..."
  bash "$BASE_DIR/NoVa-reverse-skill/skills/scripts/refresh-tool-index.sh" || log "tool-index refresh failed"
else
  skip "NoVa-reverse-skill"
fi

if [ -f "$BASE_DIR/NovA-clean-my-ai-harness/clean-my-ai-harness-claude.zip" ]; then
  log "Installing clean-my-ai-harness skill ..."
  rm -rf "$HOME/.claude/skills/clean-my-ai-harness"
  mkdir -p /tmp/cmah-bootstrap
  unzip -oq "$BASE_DIR/NovA-clean-my-ai-harness/clean-my-ai-harness-claude.zip" -d /tmp/cmah-bootstrap
  cp -r /tmp/cmah-bootstrap/claude-edition "$HOME/.claude/skills/clean-my-ai-harness"
else
  skip "NovA-clean-my-ai-harness"
fi

# --- 3. Honey: real plugin install, then symlink for same-session hot-load
if [ -d "$BASE_DIR/NoVa-honey-for-devs" ]; then
  log "Installing Honey ..."
  (cd "$BASE_DIR/NoVa-honey-for-devs" && node bin/install.js --only claude --yes) || log "Honey install failed"
  HONEY_CACHE=$(find "$HOME/.claude/plugins/cache/greenpt/honey" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort -V | tail -1)
  if [ -n "${HONEY_CACHE:-}" ]; then
    for d in "$HONEY_CACHE"/skills/*/; do
      name="$(basename "$d")"
      target="$HOME/.claude/skills/$name"
      [ -e "$target" ] && [ ! -L "$target" ] && rm -rf "$target"
      ln -sfn "${d%/}" "$target"
    done
  fi
else
  skip "NoVa-honey-for-devs"
fi

# --- 4. code-review-graph: install, build self, register+build for repos --
if [ -d "$BASE_DIR/NovA-code-review-graph" ]; then
  log "Installing code-review-graph ..."
  (cd "$BASE_DIR/NovA-code-review-graph" && uv sync) || log "code-review-graph install failed"
  CRG="$BASE_DIR/NovA-code-review-graph/.venv/bin/code-review-graph"
  if [ -x "$CRG" ]; then
    log "Building code-review-graph's own graph ..."
    (cd "$BASE_DIR/NovA-code-review-graph" && "$CRG" build) || true
    if [ -d "$BASE_DIR/NovA-terrestrial-brain" ]; then
      log "Registering + building graph for NovA-terrestrial-brain ..."
      "$CRG" register "$BASE_DIR/NovA-terrestrial-brain" || true
      (cd "$BASE_DIR/NovA-terrestrial-brain" && "$CRG" build) || true
      # .mcp.json / CLAUDE.md / hooks / skills for this repo are already
      # committed (from `code-review-graph install`) — only the gitignored
      # graph itself (.code-review-graph/) needs regenerating per-container.
    fi
  fi
else
  skip "NovA-code-review-graph"
fi

# --- 5. notebooklm-py: install deps (still needs interactive login) -------
if [ -d "$BASE_DIR/notebooklm-py" ]; then
  log "Installing notebooklm-py ..."
  (cd "$BASE_DIR/notebooklm-py" && uv sync --frozen --extra browser --extra dev --extra markdown --extra mcp) || log "notebooklm-py install failed"
else
  skip "notebooklm-py"
fi

# --- 6. OmniRoute: install + start dev server ------------------------------
if [ -d "$BASE_DIR/OmniRoute" ]; then
  log "Installing OmniRoute ..."
  (cd "$BASE_DIR/OmniRoute" && npm install) || log "OmniRoute install failed"
  log "Starting OmniRoute dev server (:20128) ..."
  nohup npm --prefix "$BASE_DIR/OmniRoute" run dev < /dev/null > "$BASE_DIR/OmniRoute/.bootstrap-dev.log" 2>&1 &
  disown
else
  skip "OmniRoute"
fi

# --- 7. NovA-terrestrial-brain: obsidian plugin + local MCP server --------
if [ -d "$BASE_DIR/NovA-terrestrial-brain" ]; then
  log "Installing + building terrestrial-brain obsidian plugin ..."
  (cd "$BASE_DIR/NovA-terrestrial-brain/obsidian-plugin" && npm install && npm run build) || log "obsidian-plugin build failed"
  log "Starting terrestrial-brain obsidian plugin dev watcher ..."
  nohup npm --prefix "$BASE_DIR/NovA-terrestrial-brain/obsidian-plugin" run dev < /dev/null > "$BASE_DIR/NovA-terrestrial-brain/obsidian-plugin/.bootstrap-dev.log" 2>&1 &
  disown
  if [ -x "$BASE_DIR/NovA-terrestrial-brain/local-mcp/setup.sh" ]; then
    log "Standing up terrestrial-brain's local Postgres-backed MCP server ..."
    bash "$BASE_DIR/NovA-terrestrial-brain/local-mcp/setup.sh" || log "terrestrial-brain local MCP setup failed"
  fi
else
  skip "NovA-terrestrial-brain"
fi

# --- 8. ECC dashboard: xdg-open shim (headless containers) + start --------
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
  - ECC dashboard:            http://127.0.0.1:3456
  - OmniRoute dev server:     http://127.0.0.1:20128
  - terrestrial-brain plugin: dev watcher active (dist/main.js -> test-vault)
  - terrestrial-brain MCP:    http://127.0.0.1:8000 (local Postgres, no Supabase account)

Still requires a human step:
  - notebooklm-py: `notebooklm login` (interactive browser OAuth)
  - terrestrial-brain MCP: OPENROUTER_API_KEY is a placeholder until a real
    OmniRoute API key is set — capture_thought/search_thoughts won't work
    until then; plain CRUD tools (projects/tasks/people/documents) do.

Skill availability: direct-copy/symlink into ~/.claude/skills hot-loads
within the current session. Plugin-marketplace installs (Honey's native
/honey command) do not hot-load mid-session — they work starting next
session regardless, no re-run needed.
EOF
