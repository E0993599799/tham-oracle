# Omega Self-Evolution — First 5 Automation Contracts

> Phase 0/1 only • NOT RUN-PROVEN

These contracts define the first automations only. No runtime implementation is included yet.

---

## 1) OMEGA_12H_HEALTH_AUDIT
**Purpose**: confirm the system is healthy enough to keep learning.

**Trigger schedule**: every 12 hours at 09:00 and 21:00 Bangkok time.

**Inputs**:
- last 12h task traces
- proof artifacts
- queue state
- heartbeat state
- cost/latency snapshot

**Process steps**:
1. Load last 12h traces.
2. Verify proof completeness.
3. Check agent heartbeat and queue status.
4. Check cost and latency bands.
5. Emit health verdict.

**Outputs**:
- health summary markdown
- health JSON record
- dashboard health card update

**Proof required**:
- `task_trace` records for all checked items
- `proof_artifact` references
- one health verdict file

**Failure mode**:
- missing proof
- stale data
- missing heartbeat
- queue stall

**Dashboard card**: System Health

**Obsidian writeback target**: `Omega Self-Evolution/12H Reviews/`

**Promotion/blocking rules**:
- may run only if the kill switch is off
- blocks if SOT or proof is missing
- result is CHECK if any critical field is incomplete

---

## 2) OMEGA_12H_FAILURE_HARVEST
**Purpose**: turn failures into problem logs and prevention candidates.

**Trigger schedule**: every 12 hours at 09:05 and 21:05 Bangkok time.

**Inputs**:
- failure events
- failed traces
- weak proofs
- false OK detections
- user corrections

**Process steps**:
1. Cluster failures by class.
2. Produce problem logs.
3. Generate prevention rule candidates.
4. Generate prompt patch candidates if needed.
5. Flag repeated patterns for weekly review.

**Outputs**:
- failure log JSON
- problem log markdown
- prevention candidate list
- dashboard failure map update

**Proof required**:
- at least one failure event or explicit zero-failure proof
- trace links
- containment action recorded

**Failure mode**:
- hidden failure
- unclassified failure
- missing containment

**Dashboard card**: Failure Map

**Obsidian writeback target**: `Omega Self-Evolution/Failure Logs/`

**Promotion/blocking rules**:
- if proof is missing, output CHECK not DONE
- if SOT boundary is involved, mark BLOCKED_BY_SOT_BOUNDARY

---

## 3) OMEGA_DAILY_AGENT_REVIEW
**Purpose**: summarize daily agent usefulness and stability.

**Trigger schedule**: daily at 23:30 Bangkok time.

**Inputs**:
- 12h summaries
- task traces
- proof quality stats
- cost/latency data
- human feedback items

**Process steps**:
1. Aggregate the day.
2. Score agents.
3. Rank top failure classes.
4. Identify useful patterns.
5. Recommend keep / narrow / quarantine / retire.

**Outputs**:
- daily review markdown
- daily scorecard JSON
- dashboard agent scoreboard update

**Proof required**:
- daily aggregated dataset
- at least one proof artifact per major claim

**Failure mode**:
- wrong aggregation
- stale day boundary
- false success report

**Dashboard card**: Agent Scoreboard

**Obsidian writeback target**: `Omega Self-Evolution/Daily Reviews/`

**Promotion/blocking rules**:
- no promotion without proof and review
- quarantine if repeated false OK or SOT drift is found

---

## 4) OMEGA_DAILY_SKILL_MINING
**Purpose**: convert repeated successful patterns into skill candidates.

**Trigger schedule**: daily at 23:40 Bangkok time.

**Inputs**:
- successful traces
- repeated task patterns
- benchmark results
- proof records

**Process steps**:
1. Detect repeated successful patterns.
2. Produce skill candidate records.
3. Attach proofs and rollback notes.
4. Classify risk and ownership.
5. Queue for weekly skill release review.

**Outputs**:
- skill candidate JSON
- candidate summary markdown
- dashboard skill pipeline update

**Proof required**:
- at least 3 successful uses or a passing benchmark
- proof artifact links
- rollback instructions

**Failure mode**:
- promoting a one-off pattern
- missing rollback
- no test case

**Dashboard card**: Skill Pipeline

**Obsidian writeback target**: `Omega Self-Evolution/Skill Releases/`

**Promotion/blocking rules**:
- candidate only if proof-backed
- quarantine if unsafe automation is detected

---

## 5) OMEGA_WEEKLY_SKILL_RELEASE
**Purpose**: release only the skills that passed evaluation and can be rolled back.

**Trigger schedule**: weekly, Sunday 22:00 Bangkok time.

**Inputs**:
- skill candidates
- weekly scorecards
- red-team findings
- benchmark outputs
- rollback notes

**Process steps**:
1. Review candidate list.
2. Check proofs and benchmarks.
3. Verify rollback and safety.
4. Release, quarantine, deprecate, or retire.
5. Publish release notes and Obsidian summary.

**Outputs**:
- skill release JSON
- weekly release note markdown
- dashboard skill release status

**Proof required**:
- candidate proof links
- release eval score
- rollback path

**Failure mode**:
- release without proof
- release without rollback
- unsafe skill promotion

**Dashboard card**: Weekly Skill Release

**Obsidian writeback target**: `Omega Self-Evolution/Weekly Reviews/` and `Omega Self-Evolution/Skill Releases/`

**Promotion/blocking rules**:
- no release if red-team blocks it
- no release if rollback path is missing
- output CHECK if eval is incomplete
