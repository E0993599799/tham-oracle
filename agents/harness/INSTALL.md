# Agent Skill Harness Installation Guide

Each agent needs:
1. Skill executor framework (provided)
2. arra-oracle-skills-cli repository cloned
3. Skill manifest loaded
4. Bootstrap script run

## Quick Start for Each Agent

### Step 1: Clone Skills Repository
```bash
git clone https://github.com/Soul-Brews-Studio/arra-oracle-skills-cli.git
```

### Step 2: Run Bootstrap
```bash
# For agent X:
bash agents/harness/bootstrap-X.sh
```

### Step 3: Verify Skills Loaded
```bash
python3 agents/harness/skill-executor.py X verify
```

## Using Skills

### List Assigned Skills
```bash
python3 agents/harness/skill-executor.py <agent-id> status
```

### Execute a Skill
```bash
python3 agents/harness/skill-executor.py <agent-id> execute <skill-name> [args...]

# Example:
python3 agents/harness/skill-executor.py tham execute go --help
```

## What Each Agent Gets

- **Harness**: Python skill executor + bootstrap script
- **Manifest**: `.agent-skills.json` in inbox
- **Config**: `.skill-config.json` after bootstrap
- **Registry**: Connection to arra-oracle-skills-cli/src/skills/

## Skill Execution Flow

```
Agent starts
    ↓
Reads .agent-skills.json (inbox)
    ↓
Loads skill-executor.py
    ↓
Discovers skills in arra-oracle-skills-cli
    ↓
Executes skill on demand
    ↓
Reports result
```

## Troubleshooting

**Skills not found:**
- Verify `arra-oracle-skills-cli` is cloned
- Check path: `arra-oracle-skills-cli/src/skills/<skill-name>/`
- Run: `python3 agents/harness/skill-executor.py <agent-id> verify`

**Skill execution fails:**
- Check skill has `main.sh`, `skill.sh`, or `run.sh`
- Verify script is executable: `chmod +x`
- Check syntax: `bash -n script.sh`

**Bootstrap not completing:**
- Ensure Python 3.8+ installed
- Check permissions: `chmod +x agents/harness/bootstrap-<agent>.sh`
- Review logs: `/tmp/<agent>_skill_verify.log`
