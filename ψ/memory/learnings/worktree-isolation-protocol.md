---
name: worktree-isolation-protocol
description: Git worktree workflow for large changes, parallel work, and context isolation
metadata:
  type: reference
  ttl: ∞
---

# Worktree Isolation Protocol

## When to Use Worktree

Use `/worktree branch-name` when:

1. **Refactor/Rewrite** — >100 lines of changes OR >5 files touched
2. **Experimental** — spike, prototype, trying multiple approaches
3. **Cherry-pick** — large port from another branch or repo
4. **Parallel work** — two agents/streams working same repo simultaneously
5. **Risky operation** — where rollback might be needed mid-way

## Why Worktrees?

| Benefit | Impact |
|---------|--------|
| **Context isolation** | Large changes don't load main context; each pane is <500 lines per file |
| **Token efficiency** | Smaller diffs per iteration; main session context stays clean |
| **Parallel safe** | Two agents on same repo, zero merge/conflict overhead |
| **Easy rollback** | Delete worktree = full undo; no complex git operations |
| **Branch safety** | Experiments don't touch main; easy to discard and restart |

## Workflow

### Start: Isolated Branch

```bash
/worktree feature-x
```

Creates:
- Git worktree at `/root/ghq/github.com/E0993599799/zeus-oracle-wt-feature-x/`
- New branch `feature-x` (not yet pushed)
- Clean `main` checkout in worktree
- Separate context tree (no pollution of parent)

### Work: Edit in Isolation

All edits happen inside the worktree. Parent `zeus-oracle/` is untouched.

```bash
cd /root/ghq/github.com/E0993599799/zeus-oracle-wt-feature-x
# ... edit files, commit, test ...
git add file1 file2
git commit -m "feature: add feature-x"
git log --oneline
```

### Iterate: Lightweight Diffs

Because worktree is isolated, each iteration has small, clean diffs. Token-efficient.

```bash
git diff main..HEAD     # See what's different vs parent
git show HEAD           # See last commit
```

### Merge: Back to Main

When done and tested:

```bash
cd /root/ghq/github.com/E0993599799/zeus-oracle
git merge feature-x     # Fast-forward or merge commit
git push origin main    # Push to remote
```

### Cleanup: Remove Worktree

After merge (or if abandoned):

```bash
git worktree prune      # Clean up deleted worktrees
git worktree list       # Verify cleanup
```

## Examples

### Example 1: Refactor >100 Lines

```bash
# Start
/worktree refactor-auth-middleware

# Edit inside worktree
cd zeus-oracle-wt-refactor-auth-middleware/
# ... large rewrite of auth/middleware.ts ...
git add auth/middleware.ts docs/auth-flow.md
git commit -m "refactor: simplify auth middleware"

# Iterate (small token cost because worktree is isolated)
# ... review, test, fix ...
git commit -m "refactor: fix auth middleware edge cases"

# Merge back
cd ../zeus-oracle
git merge refactor-auth-middleware
git push origin main

# Cleanup
git worktree prune
```

### Example 2: Parallel Work (Two Streams)

```bash
# Main session (Zeus in zeus-oracle/)
/recap → RTK → strategic decisions → /rrr

# Agent ธาม spawned in worktree for implementation
/worktree tham-impl
cd zeus-oracle-wt-tham-impl
# ... ธาม implements in isolation ...
git commit
git push feature/tham-impl

# Back in main session
git pull origin feature/tham-impl
git merge feature/tham-impl
# Done
```

### Example 3: Spike / Prototype

```bash
# Explore idea in isolation
/worktree spike-redis-cache

cd zeus-oracle-wt-spike-redis-cache
# ... experiment with Redis setup ...
# ... POC code, messy iteration ...
git add . && git commit -m "spike: redis cache POC"

# Evaluate: "Is this the direction we want?"
# If NO: Delete worktree, discard
# If YES: Clean up, cherry-pick key parts to main
```

## Commands

| Command | Effect |
|---------|--------|
| `/worktree <name>` | Create new worktree + branch |
| `git worktree list` | See all active worktrees |
| `git worktree prune` | Clean up deleted worktrees |
| `git worktree remove <path>` | Delete specific worktree |
| `git branch -d <branch>` | Delete branch after merged |

## Naming Convention

- Feature: `worktree feature-name` → branch `feature-name`, dir `zeus-oracle-wt-feature-name/`
- Fix: `worktree fix-bug-x` → branch `fix-bug-x`, dir `zeus-oracle-wt-fix-bug-x/`
- Spike: `worktree spike-redis` → branch `spike-redis`, dir `zeus-oracle-wt-spike-redis/`
- Refactor: `worktree refactor-auth` → branch `refactor-auth`, dir `zeus-oracle-wt-refactor-auth/`

## Context Budget Impact

| Approach | Token Cost per Iteration |
|----------|-------------------------|
| **Without worktree** (edit main) | ~200 tokens (full diffs, context pollution) |
| **With worktree** | ~50 tokens (isolated, clean diffs) |

For a 10-iteration refactor: **1500 token savings** ≈ ~10% of session budget.

## Safety

- **No data loss** — worktree edits are real git commits; can be pushed/merged/examined
- **Easy discard** — `git worktree remove path` = total cleanup
- **No pollution** — parent repo stays untouched until merge
- **Parallel safe** — two worktrees on same repo, zero conflicts

---

**Last Updated**: 2026-07-16  
**Referenced in**: CLAUDE.md context budget rules
