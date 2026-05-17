#!/bin/bash
# Bootstrap harness for codex
# Run this when codex starts up to load and verify skills

AGENT_ID="codex"
REPO_ROOT=""
HARNESS="$REPO_ROOT/agents/harness/skill-executor.py"

echo "🚀 Bootstrapping skill harness for $AGENT_ID"
echo ""

# 1. Print harness status
python3 "$HARNESS" "$AGENT_ID" status

# 2. Verify skills are discoverable
echo "Verifying skill availability..."
python3 "$HARNESS" "$AGENT_ID" verify > /tmp/${AGENT_ID}_skill_verify.log 2>&1

if [ $? -eq 0 ]; then
  echo "✓ Skill verification complete"
else
  echo "⚠ Some skills may be missing - check arra-oracle-skills-cli installation"
fi

# 3. Create skill config for agent
cat > "$REPO_ROOT/ψ/inbox/$AGENT_ID/.skill-config.json" << 'CONFIG'
{
  "agent": "$AGENT_ID",
  "executor": "python3 agents/harness/skill-executor.py",
  "skills_repo": "arra-oracle-skills-cli",
  "harness_version": "1.0",
  "bootstrapped_at": "2026-05-17T10:32:03Z"
}
CONFIG

echo ""
echo "✓ Harness bootstrap complete for $AGENT_ID"
echo "  Run skills with: python3 $HARNESS $AGENT_ID execute <skill-name>"
echo ""
