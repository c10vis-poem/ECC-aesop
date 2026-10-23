# MEMORY.md — ECC-aesop
Durable facts about this repo. Dated; newest first. Updated at session wrap-up.

## 2026-10-01
- Fork of `affaan-m/ECC`. **Parked, not off-limits**: it was never used properly. Reviewed in housekeeping like any repo.
- `local-inventory.json`: a snapshot (2026-09-07) of how ECC was wired on the phone (68 agents, 9 hooks, 3 MCP servers, 94 commands); runtime details are stale.
- CI had failed on main since 2026-09-06: the "Validate workflow security" step rejected `sync-upstream.yml` for persisting checkout credentials. Fixed (persist-credentials: false; the push uses GITHUB_TOKEN explicitly).
- Stale launchers on the phone: `~/.local/bin/ecc-dashboard` and `nanoclaw` point at a deleted ECC cache 2.2.0.
