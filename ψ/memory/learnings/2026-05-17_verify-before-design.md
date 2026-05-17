---
name: verify-before-external-design
description: Verify external dependencies (repos, APIs, resources) exist before designing integration
metadata:
  type: feedback
---

## Verify External Dependencies Before Design

**Rule**: When designing integration with an external repo, API endpoint, or resource, verify it exists and is accessible BEFORE committing to architecture.

**Why**: 
I designed the entire GitHub Connector assuming `E0993599799/oasync` repo existed (based on พี่เอก's mention). Spent 30 min on oasync-push.sh script architecture, mailbox-v1 schema design, error handling — then ran the script and got "Repository not found." Had to backtrack and tell พี่ "user must create oasync first." Cost: ~15 min lost time, embarrassment of incomplete feature.

**How to apply**:
Before designing:
1. If external repo: `gh repo view OWNER/REPO` (2 seconds)
2. If external API: `curl -s https://api.example.com/health` (3 seconds)
3. If file path: `ls -la /path/to/resource` (1 second)
4. If permission-gated: check `gh auth status` or similar

Only THEN design the integration.

**Tradeoff**: Costs 5 seconds of verification now, saves 15+ min of design-then-fail later.

**Not about**:
- Defensive coding (that's a different pattern)
- Assuming user mistakes (this is about due diligence)
- Over-caution (if thing should exist, verify it; don't design around "what if it's missing")

**Related**: [[assumption-lock-in]] — related pattern where confidence in assumptions causes tunnel vision

---

## Session Context

- **Incident**: Designed `/oasync "text"` command route via E0993599799/oasync without checking if repo exists
- **Discovery**: Script failed with `fatal: repository not found`
- **Caught by**: Error handler (as expected), but should have been caught pre-design
- **Next time**: One `gh repo view` call in planning phase
