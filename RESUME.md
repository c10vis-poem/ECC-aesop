# RESUME.md: ECC-aesop

Rewritten 2026-10-23.

## Current state
- Fork of `affaan-m/ECC` (AGENTS.md: version 2.2.1, 68 agents, 286 skills, 94 commands). Parked, not off-limits (MEMORY.md 2026-10-01): never used properly.
- origin/main has `MEMORY.md`, `local-inventory.json` (stale 2026-09-07 phone wiring snapshot) and the `sync-upstream.yml` fix.
- Branch protection on main requires status checks `Lint` and `Security Scan` (strict).

## Changed this week (2026-10-18..2026-10-23)
- #7 `docs: add local-inventory.json` (merged 2026-10-23); also `ci(sync-upstream)`: `persist-credentials: false`, push with explicit GITHUB_TOKEN, to satisfy the workflow-security validator that had failed CI on main since 2026-09-06.
- #8 `docs: add MEMORY.md` (merged 2026-10-23); same sync-upstream credential fix.

## Open items, in order
1. Operator review of ECC (parked; reactivate or not).
2. Stale launchers on the phone: `~/.local/bin/ecc-dashboard` and `nanoclaw` point at a deleted ECC cache 2.2.0 (MEMORY.md; not re-verified today).
3. Local clone `~/repos/ECC-aesop` is 417 commits behind origin/main, 1 ahead, with an untracked `local-inventory.json`; needs reconciling.

## Next steps
Decide the fate of ECC; if reactivated, sync from upstream per the fork workflow and re-inventory wiring.

## Sources
Read: AGENTS.md (first 60 lines), CLAUDE.md (first 30 lines), MEMORY.md, commit messages and stats of #7 and #8, branch protection, `git status` of the local clone.
Not read: the rest of AGENTS.md/CLAUDE.md, agents/skills/hooks contents, CI logs, upstream changes.
