---
pattern: In a multi-oracle monorepo, resolve which oracle's ψ vault to write to from identity/memory, not filesystem heuristics
date: 2026-05-25
source: rrr: mission-control
concepts: [rrr, multi-oracle, vault-routing, oracle-root-detection]
---

# Multi-Oracle ψ Vault Routing

The /rrr skill's oracle root detection (`git rev-parse --show-toplevel` + CLAUDE.md + ψ/ check) assumes one oracle per repo. In mission-control, ψ vaults live at `tham-oracle/ψ`, `Dheva-oracle/ψ`, etc. — nested subdirectories, not at the git root.

**Rule**: When in a multi-oracle monorepo, derive vault path from identity context first:
1. Check memory/CLAUDE.md for current oracle name
2. Use `tham-oracle/ψ`, not `./ψ` or git-root ψ
3. Fall back to filesystem scan only if identity is unknown

**Also**: the ENCODED_PWD sed command in /rrr does not handle spaces in paths. Fix: `sed 's|^/|-|; s|[/ ]|-|g; s|\\.|-|g'` (add space to the character class).

Related: [[rrr-oracle-root-detection]]
