#!/usr/bin/env python3
"""
Agent Skill Executor Harness
Each agent uses this to load, discover, and execute their assigned skills.
"""

import json
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional

class SkillExecutorHarness:
    """Load and execute skills assigned to an agent."""

    def __init__(self, agent_id: str):
        self.agent_id = agent_id
        self.repo_root = Path(__file__).parent.parent.parent
        self.agent_inbox = self.repo_root / "ψ/inbox" / agent_id
        self.skills_dir = self.repo_root / "arra-oracle-skills-cli/src/skills"
        self.skill_manifest = self._load_skill_manifest()

    def _load_skill_manifest(self) -> Dict:
        """Load this agent's assigned skills from .agent-skills.json"""
        manifest_file = self.agent_inbox / ".agent-skills.json"
        if not manifest_file.exists():
            return {"skills": [], "agent": self.agent_id}
        
        try:
            with open(manifest_file) as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading manifest: {e}")
            return {"skills": [], "agent": self.agent_id}

    def list_skills(self) -> List[str]:
        """List all skills assigned to this agent."""
        return self.skill_manifest.get("skills", [])

    def discover_skill(self, skill_name: str) -> Optional[Path]:
        """Find a skill directory in arra-oracle-skills-cli."""
        skill_path = self.skills_dir / skill_name
        if skill_path.exists() and skill_path.is_dir():
            return skill_path
        return None

    def verify_skills(self) -> Dict[str, bool]:
        """Verify which assigned skills are available."""
        verification = {}
        for skill in self.list_skills():
            skill_path = self.discover_skill(skill)
            verification[skill] = skill_path is not None
        return verification

    def execute_skill(self, skill_name: str, args: Optional[List[str]] = None) -> bool:
        """Execute a skill by running its main script."""
        skill_path = self.discover_skill(skill_name)
        
        if not skill_path:
            print(f"Skill not found: {skill_name}")
            return False

        # Look for main script (skill.sh, main.py, index.ts, etc.)
        main_script = None
        for script in [skill_path / "main.sh", skill_path / "skill.sh", skill_path / "run.sh"]:
            if script.exists():
                main_script = script
                break

        if not main_script:
            print(f"No executable found in skill: {skill_name}")
            return False

        try:
            cmd = ["bash", str(main_script)] + (args or [])
            result = subprocess.run(cmd, cwd=str(skill_path), timeout=300)
            return result.returncode == 0
        except Exception as e:
            print(f"Error executing skill {skill_name}: {e}")
            return False

    def print_harness_status(self):
        """Print status of skill harness."""
        print(f"\n{'='*70}")
        print(f"SKILL EXECUTOR HARNESS — {self.agent_id.upper()}")
        print(f"{'='*70}")
        
        skills = self.list_skills()
        print(f"\nAssigned skills: {len(skills)}")
        for skill in skills:
            print(f"  • {skill}")

        verification = self.verify_skills()
        available = sum(1 for v in verification.values() if v)
        print(f"\nAvailable: {available}/{len(skills)}")
        
        for skill, found in verification.items():
            status = "✓" if found else "✗"
            print(f"  {status} {skill}")

        if available < len(skills):
            print(f"\n⚠ Missing {len(skills) - available} skill(s)")
            print("  Ensure arra-oracle-skills-cli is cloned to:")
            print(f"  {self.skills_dir}")

        print(f"{'='*70}\n")


def main():
    if len(sys.argv) < 2:
        print("Usage: skill-executor.py <agent-id> [status|verify|execute <skill> [args...]]")
        sys.exit(1)

    agent_id = sys.argv[1]
    command = sys.argv[2] if len(sys.argv) > 2 else "status"

    harness = SkillExecutorHarness(agent_id)

    if command == "status":
        harness.print_harness_status()
    elif command == "verify":
        verification = harness.verify_skills()
        for skill, found in verification.items():
            status = "✓ FOUND" if found else "✗ MISSING"
            print(f"{skill}: {status}")
    elif command == "execute":
        if len(sys.argv) < 4:
            print("Usage: skill-executor.py <agent-id> execute <skill> [args...]")
            sys.exit(1)
        skill_name = sys.argv[3]
        args = sys.argv[4:] if len(sys.argv) > 4 else []
        success = harness.execute_skill(skill_name, args)
        sys.exit(0 if success else 1)
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)


if __name__ == "__main__":
    main()
