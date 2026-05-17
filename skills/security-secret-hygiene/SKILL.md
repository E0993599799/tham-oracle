# Skill: Security & Secret Hygiene

## Purpose

Prevent credential leaks across all workflows. Enforce that secrets (.env, API keys, tokens, passwords) never make it into git commits, environment logs, or dashboard visibility.

## Scope

This skill applies to:
- All agents (Tham, Core, Codex, Gemini, Hermes, Housekeeper, Watchdog)
- All execution lanes (code, research, infrastructure, maintenance)
- All proof and logging systems
- All writebacks (Obsidian, Notion, GitHub)

## Rules

### R-01: Never Commit Secrets

**Policy:**
- Forbidden patterns in any commit:
  - `.env` files (any variant: `.env.local`, `.env.production`, etc.)
  - API keys: `api_key`, `API_KEY`, `sk-...` (OpenAI), `bearer_token`, `token`, `Token`
  - Passwords: `password`, `passwd`, `pwd`, `secret`, `Secret`
  - OAuth tokens: `oauth_token`, `access_token`, `refresh_token`
  - AWS credentials: `AKIA...` (AWS access key ID), `aws_secret_access_key`
  - GitHub tokens: `ghp_...`, `gho_...`, `ghu_...`, `ghs_...`
  - Private keys: `PRIVATE KEY`, `PRIVATE`, `private_key`
  - Connection strings: `sqlserver://...password=...`

**Enforcement:**
- Pre-commit hook: grep for patterns before git commit
- Proof reader: scan proof files + git logs for leaks
- Dashboard: mask sensitive values in logs
- Codex: manual review of code before commit

**Git Safe Workflow:**
```bash
# SAFE: secrets in .env.local (gitignored)
echo "API_KEY=sk-..." >> .env.local
git add -A
git commit -m "feat: add API integration"  # ✓ API_KEY not in commit

# UNSAFE: secrets in code
echo 'API_KEY="sk-..."' >> src/config.py
git add src/config.py
git commit -m "feat: add API"  # ✗ BLOCKED by pre-commit hook
```

### R-02: Never Log Secrets

**Policy:**
- stdout/stderr from execution lanes must not contain secrets
- Proof files must not expose any credential
- Dashboard events must mask sensitive values

**Redaction Pattern:**
- When logging, replace:
  - `password=***` (any password field)
  - `token=***` (any token value)
  - `api_key=***` (any key)
  - `bearer ***` (auth header)
  - URLs with credentials: `https://user:password@host` → `https://***:***@host`

**Examples:**
```
❌ UNSAFE:  "curl -H 'Authorization: Bearer sk-abc123xyz' https://..."
✓ SAFE:    "curl -H 'Authorization: Bearer ***' https://..."

❌ UNSAFE: {"status": "OK", "api_key": "sk-abc123xyz"}
✓ SAFE:   {"status": "OK", "api_key": "***"}

❌ UNSAFE: "Connection: Server=db.example.com;User=admin;Password=secret123"
✓ SAFE:   "Connection: Server=db.example.com;User=admin;Password=***"
```

### R-03: Environment Variable Safety

**Policy:**
- Secrets are ONLY in environment variables or secure vaults (Supabase, 1Password, etc.)
- `.env` files are NEVER committed to git (always in `.gitignore`)
- Secret rotation: change every 90 days minimum

**Vault Access Pattern:**
```bash
# SAFE: read from env var (set by CI/CD or shell session)
API_KEY="${API_KEY}"  # value loaded from environment

# SAFE: read from Supabase encrypted column
supabase.from('secrets').select('api_key').single()

# SAFE: read from 1Password via CLI
op get item 'api-credentials' --fields api_key

# UNSAFE: hardcoded in code
API_KEY = "sk-abc123"  # ✗ NEVER
```

### R-04: Proof File Scrubbing

**Policy:**
- Every proof file goes through secret scanner before archival
- If secrets detected → block proof, alert human, do NOT archive

**Scanner:**
```bash
jq '.proof_summary, .lane_response.output' proofs/<task_id>.json | \
  grep -E "(password|token|api_key|secret|bearer|password=)" && \
  echo "ALERT: Secrets detected in proof!" && \
  exit 1
```

### R-05: Dashboard Masking

**Policy:**
- All displayed values on Oracle Studio dashboard are scrubbed
- Any field matching secret pattern → replace with `***`
- Logs in real-time (no historical leaks visible)

**Field Masking:**
```json
// Before dashboard display
{
  "task_id": "abc-123",
  "output": "curl -H 'Authorization: Bearer sk-abc123xyz'",
  "env_vars": {"API_KEY": "sk-xyz789", "USER": "admin"}
}

// After masking
{
  "task_id": "abc-123",
  "output": "curl -H 'Authorization: Bearer ***'",
  "env_vars": {"API_KEY": "***", "USER": "admin"}
}
```

### R-06: Secret Rotation & Audit

**Policy:**
- Every 90 days minimum: rotate all secrets
- Audit log: who accessed which secret, when
- Breach response: immediate rotation + alert

**Rotation Schedule:**
```
API keys: every 90 days
Tokens: every 30 days
Passwords: every 60 days
Database credentials: every 90 days
```

**Audit Tracking:**
```json
{
  "timestamp": "2026-05-17T14:32:15+07:00",
  "action": "secret_access",
  "secret_id": "api_key_openai",
  "accessed_by": "codex",
  "purpose": "task-abc-123 (code generation)",
  "risk": "LOW"
}
```

### R-07: Secrets in Code Review

**Policy:**
- Code review (Codex / Tham) must scan for hardcoded secrets
- If found → comment → reject PR → do not merge

**Pattern Scan in PR:**
```bash
git diff origin/main... | \
  grep -E "(password|token|api_key|secret|bearer|AKIA)" && \
  echo "Secrets detected in PR diff!" && \
  exit 1
```

### R-08: Breach Response

**Policy:**
- If secret leaked → immediate rotation + notification
- Timeline: < 5 min alert, < 1 hour rotation, < 24 hour post-mortem

**Breach Protocol:**
```
1. DETECT → secret found in log/git/dashboard (< 5 min)
2. ALERT  → Telegram + Tham + BoB + Human (immediate)
3. ROTATE → new secret generated + deployed (< 1 hour)
4. VERIFY → confirm old secret revoked (< 2 hours)
5. AUDIT  → post-mortem + rule update (< 24 hours)
```

---

## Implementation

### Pre-Commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit
git diff --cached | grep -E "(password|token|api_key|secret|AKIA|sk-|ghp_|gho_)" && {
  echo "❌ Secrets detected in staged changes!"
  echo "   Use .env.local or environment variables instead"
  exit 1
}
```

### Codex Proof Validation

```python
import json
import re

SECRET_PATTERNS = [
    r'password["\']?\s*[=:]\s*["\']?[^"\'\s]+',
    r'(api_key|token|secret)["\']?\s*[=:]\s*["\']?sk-\w+',
    r'AKIA\w{16}',  # AWS access key
    r'ghp_\w+',      # GitHub token
    r'bearer\s+\w+', # OAuth bearer
]

def scan_for_secrets(text):
    for pattern in SECRET_PATTERNS:
        if re.search(pattern, text, re.IGNORECASE):
            return True
    return False

def validate_proof(proof_json):
    proof_str = json.dumps(proof_json)
    if scan_for_secrets(proof_str):
        raise Exception("Secrets detected in proof file!")
    return True
```

### Dashboard Masking Function

```javascript
function maskSecrets(obj) {
  const secretPatterns = ['password', 'token', 'api_key', 'secret', 'bearer'];
  
  const walk = (o) => {
    if (typeof o === 'string') {
      let masked = o;
      secretPatterns.forEach(pattern => {
        masked = masked.replace(
          new RegExp(`(${pattern}["\']?\\s*[=:]["\']?)([^"'\\s]+)`, 'gi'),
          `$1***`
        );
      });
      return masked;
    }
    if (typeof o === 'object' && o !== null) {
      Object.keys(o).forEach(k => {
        if (secretPatterns.some(p => k.toLowerCase().includes(p))) {
          o[k] = '***';
        } else {
          o[k] = walk(o[k]);
        }
      });
    }
    return o;
  };
  
  return walk(obj);
}
```

---

## Verification

### Test Scenarios

1. **Commit with .env file**
   ```bash
   echo "API_KEY=test" > .env
   git add .env
   git commit -m "test"  # ✗ Hook blocks
   ```

2. **Hardcoded password in code**
   ```python
   db_password = "secret123"  # ✗ Pre-commit hook + code review blocks
   ```

3. **Token in proof file**
   ```json
   {"token": "ghp_abc123", ...}  // ✗ Proof validation blocks archival
   ```

4. **Masking in dashboard**
   ```
   Log shows: "curl -H 'Authorization: Bearer ***'" (not actual token)
   ```

---

## Related Skills

- `git-safe-workflow` — no force push, small commits
- `code-review` — security audit scanning
- `proof-reader` — independent verification
- `risk-gate` — security as risk factor

---

## Standards

- OWASP Top 10 — credential management best practices
- CWE-798 — hardcoded credentials (prevent)
- CWE-200 — exposure of sensitive data (prevent)
- NIST SP 800-63B — authentication and lifecycle management

---

**Version:** 1.0  
**Status:** Active (Constitutional rule C-02)  
**Owner:** Tham (with enforcement by all agents)  
**Last Updated:** 2026-05-17
