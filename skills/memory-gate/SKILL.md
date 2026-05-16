# Skill: Memory Gate

## Purpose
Read operational memory, project rules, current baseline, and known traps before technical action.
Track **when** each critical file was last read this session and block stale context from reaching
major decisions.

## Use When
- Forge/Omega/Core/Hermes/SFSR/PowerShell work
- Any repair, architecture, automation, or writeback task
- Human says: read memory, continue, green, close, check, done, or asks about current state
- Starting any multi-step task (> 3 actions)
- Switching executor lane, repo, runtime, or risk tier mid-session

---

## Critical Files & Freshness Thresholds

| File | Path | Max Age |
|------|------|---------|
| ACTIVE_INDEX | `brain/memory/ACTIVE_INDEX.md` | 60 min |
| oracle.md | `ψ/memory/resonance/oracle.md` | 60 min |
| profile.md | `brain/identity/profile.md` | 120 min |

---

## Freshness Tracking — In-Session Hash+Timestamp Pattern

Tham tracks each read using a two-field record maintained in the **active context block**
(not a file — kept in working memory for the session):

```
MG_RECORD = {
  "<file_key>": {
    "hash": "<8-char git SHA>",
    "read_at_epoch": <unix epoch integer>,
    "read_at_human": "HH:MM"
  }
}
```

### Populating the Hash

**Preferred — git SHA:**
```bash
git log -1 --format="%h %ai" -- brain/memory/ACTIVE_INDEX.md
git log -1 --format="%h %ai" -- ψ/memory/resonance/oracle.md
git log -1 --format="%h %ai" -- brain/identity/profile.md
```
Take the first 8 characters of the short hash. Example: `7a49782 2026-05-16 09:00:00 +0700` → hash = `7a49782`.

**Fallback — md5 of first 100 bytes (if git unavailable):**
```bash
head -c 100 brain/memory/ACTIVE_INDEX.md | md5sum | cut -c1-8
```

**Timestamp** — record unix epoch immediately after read:
```bash
date +%s
```

### Example MG_RECORD after full gate read at 14:32
```
MG_RECORD = {
  "ACTIVE_INDEX": { "hash": "7a49782", "read_at_epoch": 1747378320, "read_at_human": "14:32" },
  "oracle.md":    { "hash": "c627089", "read_at_epoch": 1747378325, "read_at_human": "14:32" },
  "profile.md":   { "hash": "2dbb8af", "read_at_epoch": 1747378330, "read_at_human": "14:32" }
}
```

---

## Stale Gate Rules

| Condition | State | Required Action |
|-----------|-------|-----------------|
| Not in MG_RECORD (never read this session) | UNREAD | MUST read before proceeding |
| Age > 3600s for ACTIVE_INDEX or oracle.md | STALE | MUST re-read |
| Age > 7200s for profile.md | STALE | MUST re-read |
| Git SHA on disk differs from recorded hash | CHANGED | MUST re-read regardless of age |
| Within threshold and hash unchanged | FRESH | Proceed |

**Hash change check** — run before a multi-step task even if within time threshold:
```bash
git log -1 --format="%h" -- brain/memory/ACTIVE_INDEX.md
```
If output differs from recorded hash → CHANGED → re-read immediately.

---

## Block Rule — Multi-Step Tasks

For any task requiring **more than 3 sequential actions**:

1. Run memory gate evaluation BEFORE the first action.
2. If ANY required file is UNREAD, STALE, or CHANGED → **block task start**.
3. Read all flagged files first.
4. Re-evaluate gate → must reach PASS on all three files.
5. Only then proceed with the task plan.

---

## Gate Evaluation Procedure

```
STEP 1 — Get current epoch: now = $(date +%s)

STEP 2 — For each critical file:
  a. Check if file_key exists in MG_RECORD → If not: state = UNREAD
  b. Check age: age = now - read_at_epoch → If age > threshold: state = STALE
  c. Check hash: current_hash = $(git log -1 --format="%h" -- <path>)
     → If current_hash != recorded hash: state = CHANGED
  d. If none of the above: state = FRESH

STEP 3 — If any file is UNREAD/STALE/CHANGED: read it, update MG_RECORD

STEP 4 — Confirm all files = FRESH → emit gate output
```

---

## Output Format

```
MEMORY GATE: PASS | timestamp: 14:32 | files: ACTIVE_INDEX(fresh), oracle.md(fresh), profile.md(stale→re-read)
```

Then emit memory summary:

```
MEMORY GATE READ:
- enforced rules: <top 3–5 active rules from ACTIVE_INDEX>
- current baseline: <key repo/provider/tool facts>
- risk flags: <active risk flags from ACTIVE_INDEX>
- exact next action: <one sentence>
```

---

## Quick Bash Reference

```bash
# Check all three files at once
for f in "brain/memory/ACTIVE_INDEX.md" "ψ/memory/resonance/oracle.md" "brain/identity/profile.md"; do
  printf "%s → hash=%s time=%s\n" "$f" \
    "$(git log -1 --format='%h' -- "$f")" \
    "$(git log -1 --format='%ai' -- "$f")"
done

# Get current epoch
date +%s

# md5 fallback
head -c 100 brain/memory/ACTIVE_INDEX.md | md5sum | cut -c1-8
```

---

## Rules

- Never rely only on fresh chat context for major technical decisions.
- Check remembered baseline before proposing a runner or architecture.
- If memory conflicts with live proof, report CHECK and collect proof.
- Surface the memory gate result compactly before technical work.
- **Turn-based cache**: use last successful gate read for up to 5 chat turns OR until freshness threshold exceeded — whichever comes first. Both rules apply; stricter wins.
- On turn 6+, or when task changes risk tier/executor lane/repo/runtime/safety policy, re-evaluate gate even if within time threshold.
- Memory cache does NOT override live proof. If proof/logs contradict memory, proof/logs win.
- If git unavailable: fall back to md5 and log `[MG WARNING] git SHA unavailable — using md5 fallback for <file>`.

## Integration with Session Lifecycle

| Lifecycle Stage | Gate Action |
|-----------------|-------------|
| `/recap` (session start) | Full gate read — all 3 files, populate MG_RECORD |
| RTK block build | Confirm gate is PASS; include gate timestamp in RTK header |
| Before multi-step task (> 3 actions) | Re-evaluate gate; block if STALE/CHANGED/UNREAD |
| On task risk-tier change | Re-evaluate gate even if within time threshold |
| Turn 6+ since last gate | Re-evaluate gate |
| `/rrr` (session close) | No gate re-read needed |

## Failure States

| Failure | Response |
|---------|----------|
| git log returns empty | Use md5 fallback; log `[MG WARNING]` |
| File does not exist | Log `[MG ERROR] <file> missing`; halt task; alert พี่เอก |
| Hash changed mid-session | Re-read immediately; update MG_RECORD; note change in memory summary |
| Session > 2MB context | Use surgical reads (Read with offset/limit + grep); do not full-read FRESH files |
