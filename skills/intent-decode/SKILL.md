# Skill: Intent Decode

## Purpose
Convert natural language task requests from พี่เอก into structured, scored task contracts.
A contract is only passed to an executor lane after confidence >= 0.7 OR after a clarification round resolves ambiguity.

## Use When
Human gives informal commands such as: ทำเลย, สั่ง Core ทำ, run ต่อ, check, close, green, fix, setup, deploy, push, reset, audit, หยุด, ลอง, เปิด, ปิด, ดู, แก้.

---

## Decode Flow

### Step 1 — Extract four signal dimensions
For each incoming message, score these four dimensions (each worth 0.25 toward total confidence):

| Dimension | Present (0.25) | Partial (0.10) | Absent (0.0) |
|---|---|---|---|
| **Action verb** | Clear, unambiguous verb: fix, deploy, revert, audit | Vague but inferable: check, ดู, ลอง | Missing entirely |
| **Target** | Explicit file, repo, system, URL, agent name | Implied from recent context | Completely unspecified |
| **Scope** | Bounded clearly: "only this function", "just staging" | Partially bounded | Unbounded / global risk |
| **Success criteria** | Stated outcome or verifiable proof defined | Implied (e.g., "make it green") | No way to know when done |

### Step 2 — Collect ambiguity flags
Append a flag for each of the following that is true:

| Flag | Trigger condition |
|---|---|
| `action_vague` | Verb maps to 2+ different operations |
| `target_unclear` | No explicit target; context lookup failed |
| `scope_missing` | No boundary on what to touch |
| `success_undefined` | No stated or inferable success condition |
| `conflicting_intent` | Message contains mutually exclusive goals |
| `risk_unassessed` | Action could be destructive; no confirmation signal |
| `lane_ambiguous` | Cannot determine which executor lane to use |

### Step 3 — Compute confidence score

```
confidence = sum(dimension scores) − (0.05 × len(ambiguity_flags))
confidence = max(0.0, min(1.0, confidence))
```

Example: 3 of 4 dimensions present (0.75) minus 1 ambiguity flag (−0.05) = **0.70**

### Step 4 — Clarification gate

**If confidence < 0.7:**
- PAUSE. Do NOT create task contract yet.
- Ask exactly 1–2 targeted questions. Reference the highest-weight missing dimension first.
- Format: "ธามต้องการความชัดเจนก่อนดำเนินการ:\n1. [question about top missing dimension]\n2. [question about second missing dimension if needed]"
- After receiving answer, re-run Steps 1–3. Proceed when confidence >= 0.7.

**If confidence >= 0.7:**
- Proceed directly to contract creation (Step 5). Do NOT ask for confirmation.

### Step 5 — Produce task contract

Output a structured block:

```json
{
  "action": "<specific operation verb>",
  "target": "<file | system | repo | agent | URL>",
  "scope": "<boundary of change — files, services, environment>",
  "success_criteria": "<observable proof of completion>",
  "confidence": 0.00,
  "ambiguity_flags": [],
  "clarification_needed": false,
  "lane": "<Core Runner | PowerShell SFSR | OpenClaw | Codex | Hermes | research | web>",
  "risk_level": "<low | medium | high>",
  "proof_required": "<what artifact proves success>",
  "retry_count": 0,
  "retry_limit": 2,
  "escalation_status": "none"
}
```

### Step 6 — Hand off to executor
Pass the completed contract to `executor-lane-router`. Never pass raw natural language.

---

## Confidence Score Reference

| Score | Meaning | Action |
|---|---|---|
| 0.90 – 1.00 | Intent fully clear, all signals present | Execute immediately |
| 0.70 – 0.89 | Intent clear enough, minor gaps acceptable | Execute; note gaps in contract |
| 0.50 – 0.69 | Significant ambiguity — clarify before proceeding | Ask 1–2 questions, re-score |
| < 0.50 | Intent too vague — must clarify | Ask, wait, re-score from scratch |

---

## Scoring Examples

### Example A — High confidence (1.00)
> "fix the import error in services/auth.py"

- action: fix (0.25) — clear
- target: services/auth.py (0.25) — explicit
- scope: that file (0.25) — bounded
- success_criteria: no import error (0.25) — inferable
- ambiguity_flags: [] (no deduction)
- **confidence: 1.00** → proceed

### Example B — Clarification needed (0.10)
> "ลอง deploy ก่อนนะ"

- action: deploy (0.25) — clear
- target: absent (0.0)
- scope: absent (0.0)
- success_criteria: absent (0.0)
- ambiguity_flags: [target_unclear, scope_missing, success_undefined] → −0.15
- **confidence: 0.10** → ask:
  1. "Deploy ระบบไหนครับ พี่? (ชื่อ service หรือ repo)"
  2. "Deploy ไป environment ไหน? staging หรือ production?"

### Example C — Borderline (0.65)
> "check health ของ oracle studio"

- action: check health (0.25) — clear
- target: oracle studio (0.25) — named system
- scope: partial (0.10)
- success_criteria: implied (0.10)
- ambiguity_flags: [success_undefined] → −0.05
- **confidence: 0.65** → ask 1 question: "ต้องการดูแค่ HTTP status หรือต้องการ full log ด้วยครับ?"

---

## Rules

- Never send raw natural language directly to any executor lane.
- Preserve Human intent — decode do not invent.
- Ask only when truly blocked (confidence < 0.7). Never ask redundant questions.
- If context from the current session already answers a dimension, count it as present.
- A clarification round resets the score — do not carry over old flags after the human answers.
- `risk_level: high` always triggers a confirmation echo before lane handoff, regardless of confidence.
- After clarification, if confidence still < 0.7 after two rounds, escalate to Human with a plain-language summary of what's blocking execution.
- Every contract must include retry_count, retry_limit, and escalation_status for Risk Gate (C-09).

## Token Rule
Score inline — do not re-read this file mid-session once the scoring model is loaded into active context.
