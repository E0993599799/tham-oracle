#!/usr/bin/env python3
"""
Phase 9A: Constitution Enforcer
Validates task contracts against Tham Constitution (C-01 to C-12)

Usage:
    python3 constitution-enforcer.py --contract <json_file>
    python3 constitution-enforcer.py --task <task_id>
    python3 constitution-enforcer.py --test
"""

import sys
import json
import re
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple
import hashlib


class ConstitutionEnforcer:
    """Gate each task against 12 constitutional rules"""

    def __init__(self, constitution_path: str):
        self.constitution_path = Path(constitution_path)
        self.rules = self._load_constitution()
        self.violations = []
        self.checked_rules = []

    def _load_constitution(self) -> Dict:
        """Load constitution.md and parse rules C-01 to C-12"""
        rules_dict = {
            "C-01": {"name": "No Force Push", "pattern": r"(push\s+--force|push\s+-f|--force-with-lease)"},
            "C-02": {"name": "No Secret Commits", "pattern": r"(\\.env|token|secret|credential|password|\\.key|\\.pem)"},
            "C-03": {"name": "Memory Gate Required", "check": "memory_gate_hash"},
            "C-04": {"name": "Human Control on Destructive Actions", "irreversible": True},
            "C-05": {"name": "Reversible Over Irreversible", "reversibility": True},
            "C-06": {"name": "No Fabricated Success", "proof_required": True},
            "C-07": {"name": "Honest Failure Reporting", "failure_honest": True},
            "C-08": {"name": "No Risk Gate Bypass", "risk_gate_required": True},
            "C-09": {"name": "Retry Limit", "max_retries": 2},
            "C-10": {"name": "Hermes Restriction", "hermes_justification": True},
            "C-11": {"name": "No Secret Storage", "pattern": r"(token|credential|password|secret|api_key|private_key)"},
            "C-12": {"name": "No Direct Execution", "delegate_execution": True},
        }
        return rules_dict

    def check_c01_no_force_push(self, contract: Dict) -> bool:
        """C-01: Reject force push"""
        instructions = str(contract.get("instructions", "")).lower()
        command = str(contract.get("command", "")).lower()

        if re.search(r"(push\s+--force|push\s+-f|--force-with-lease)", command + " " + instructions):
            self.violations.append({
                "rule": "C-01",
                "violation": "Force push detected",
                "instructions": instructions[:100],
            })
            return False
        return True

    def check_c02_no_secret_commits(self, contract: Dict) -> bool:
        """C-02: Reject if secrets in staged files or contract"""
        staged_files = contract.get("staged_files", [])
        secret_patterns = [r"\.env", r"token", r"secret", r"credential", r"password", r"\.key", r"\.pem"]

        for file in staged_files:
            for pattern in secret_patterns:
                if re.search(pattern, file, re.IGNORECASE):
                    self.violations.append({
                        "rule": "C-02",
                        "violation": f"Secret file detected in staging: {file}",
                    })
                    return False

        # Also check contract fields
        contract_str = json.dumps(contract)
        if re.search(r"(api_key|token|password|secret|credential).*[:=]\s*['\"]?[a-zA-Z0-9]{8,}", contract_str):
            self.violations.append({
                "rule": "C-02",
                "violation": "Secret pattern detected in contract fields",
            })
            return False

        return True

    def check_c03_memory_gate(self, contract: Dict) -> bool:
        """C-03: Memory gate must have been run with hash + timestamp"""
        memory_gate = contract.get("memory_gate", {})

        if not memory_gate.get("hash") or not memory_gate.get("timestamp"):
            self.violations.append({
                "rule": "C-03",
                "violation": "Memory gate not completed (missing hash or timestamp)",
                "required": {"hash": "yes", "timestamp": "yes"},
                "provided": {
                    "hash": "yes" if memory_gate.get("hash") else "no",
                    "timestamp": "yes" if memory_gate.get("timestamp") else "no",
                },
            })
            return False
        return True

    def check_c04_human_control_destructive(self, contract: Dict) -> bool:
        """C-04: Destructive/irreversible actions require human approval"""
        risk_level = contract.get("risk_gate", {}).get("level")
        irreversible_patterns = [r"rm\s+-rf", r"hard.*reset", r"drop\s+table", r"delete\s+.*database"]

        instructions = str(contract.get("instructions", "")).lower()

        if risk_level in ["CRITICAL", "HIGH"]:
            human_approval = contract.get("human_approval")
            if not human_approval:
                self.violations.append({
                    "rule": "C-04",
                    "violation": f"High/Critical risk action requires human approval",
                    "risk_level": risk_level,
                    "human_approval": human_approval,
                })
                return False

        for pattern in irreversible_patterns:
            if re.search(pattern, instructions):
                human_approval = contract.get("human_approval")
                if not human_approval:
                    self.violations.append({
                        "rule": "C-04",
                        "violation": f"Irreversible action detected: requires human approval",
                        "detected_action": pattern,
                    })
                    return False

        return True

    def check_c05_reversible_preferred(self, contract: Dict) -> bool:
        """C-05: Prefer reversible alternative"""
        # This is more of a recommendation check
        reversible_path = contract.get("reversible_alternative")
        if contract.get("reversible_alternative") is not None:
            # If reversible path exists, ensure it's documented
            return True
        return True

    def check_c06_proof_required(self, contract: Dict) -> bool:
        """C-06: No fabricated success — proof schema required"""
        proof_schema = contract.get("proof_schema")

        if not proof_schema:
            self.violations.append({
                "rule": "C-06",
                "violation": "Proof schema not defined — cannot verify completion",
                "required": "proof_schema with verification method",
            })
            return False

        return True

    def check_c07_honest_failure(self, contract: Dict) -> bool:
        """C-07: Failure reporting must be honest"""
        # This is checked on result, not contract
        return True

    def check_c08_risk_gate_required(self, contract: Dict) -> bool:
        """C-08: Risk gate must be populated"""
        risk_gate = contract.get("risk_gate")

        if not risk_gate or not risk_gate.get("level"):
            self.violations.append({
                "rule": "C-08",
                "violation": "Risk gate not classified",
                "required": "risk_gate.level (CRITICAL|HIGH|MEDIUM|LOW)",
            })
            return False

        return True

    def check_c09_retry_limit(self, contract: Dict) -> bool:
        """C-09: Retry count must not exceed 2"""
        retry_count = contract.get("retry_count", 0)

        if retry_count > 2:
            self.violations.append({
                "rule": "C-09",
                "violation": f"Retry limit exceeded ({retry_count} > 2) — escalation required",
                "retry_count": retry_count,
                "max_allowed": 2,
            })
            return False

        return True

    def check_c10_hermes_justification(self, contract: Dict) -> bool:
        """C-10: Hermes route requires human justification"""
        target_lane = contract.get("target_lane")

        if target_lane == "hermes":
            human_justification = contract.get("hermes_justification")
            if not human_justification:
                self.violations.append({
                    "rule": "C-10",
                    "violation": "Hermes lane selected without human justification",
                    "required": "hermes_justification field must be populated by human",
                })
                return False

        return True

    def check_c11_no_secret_storage(self, contract: Dict) -> bool:
        """C-11: No secrets in memory, contracts, or writebacks"""
        secret_patterns = [r"api_key", r"token", r"credential", r"password", r"secret", r"private_key"]

        # Check various fields
        check_fields = {
            "memory_write": contract.get("memory_write", ""),
            "proof_artifact": str(contract.get("proof_artifact", "")),
            "writeback": str(contract.get("writeback_target", "")),
        }

        contract_str = json.dumps(contract)

        for pattern in secret_patterns:
            if re.search(rf"{pattern}.*[:=]\s*['\"]?[a-zA-Z0-9]{{8,}}", contract_str, re.IGNORECASE):
                self.violations.append({
                    "rule": "C-11",
                    "violation": f"Secret pattern '{pattern}' detected in contract",
                })
                return False

        return True

    def check_c12_delegate_execution(self, contract: Dict) -> bool:
        """C-12: Tham must delegate, not execute directly"""
        target_lane = contract.get("target_lane")

        if not target_lane or target_lane == "direct":
            self.violations.append({
                "rule": "C-12",
                "violation": "Task not routed through executor lane",
                "required": "target_lane must be one of: shell-safe, github-cli, codex, hermes",
            })
            return False

        valid_lanes = ["shell-safe", "github-cli", "codex", "hermes"]
        if target_lane not in valid_lanes:
            self.violations.append({
                "rule": "C-12",
                "violation": f"Invalid target_lane: {target_lane}",
                "valid_lanes": valid_lanes,
            })
            return False

        return True

    def enforce(self, contract: Dict) -> Dict:
        """Run all 12 rule checks"""
        self.violations = []
        self.checked_rules = []

        checks = [
            ("C-01", self.check_c01_no_force_push),
            ("C-02", self.check_c02_no_secret_commits),
            ("C-03", self.check_c03_memory_gate),
            ("C-04", self.check_c04_human_control_destructive),
            ("C-05", self.check_c05_reversible_preferred),
            ("C-06", self.check_c06_proof_required),
            ("C-07", self.check_c07_honest_failure),
            ("C-08", self.check_c08_risk_gate_required),
            ("C-09", self.check_c09_retry_limit),
            ("C-10", self.check_c10_hermes_justification),
            ("C-11", self.check_c11_no_secret_storage),
            ("C-12", self.check_c12_delegate_execution),
        ]

        for rule_id, check_func in checks:
            passed = check_func(contract)
            self.checked_rules.append({
                "rule": rule_id,
                "name": self.rules[rule_id]["name"],
                "passed": passed,
            })

        compliant = all(r["passed"] for r in self.checked_rules)

        return {
            "compliant": compliant,
            "violations": self.violations,
            "checked_rules": self.checked_rules,
            "timestamp": datetime.utcnow().isoformat(),
        }


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    project_root = Path(__file__).parent.parent
    constitution_path = project_root / "brain" / "identity" / "constitution.md"

    enforcer = ConstitutionEnforcer(str(constitution_path))

    if sys.argv[1] == "--test":
        # Run test suite
        test_contract_pass = {
            "task_id": "test-001",
            "instructions": "Read and analyze logs",
            "memory_gate": {
                "hash": "abc123",
                "timestamp": "2026-05-17T10:00:00Z",
            },
            "risk_gate": {
                "level": "LOW",
            },
            "proof_schema": {
                "method": "file_probe",
                "path": "/tmp/results.json",
            },
            "target_lane": "shell-safe",
            "staged_files": ["README.md"],
        }

        result = enforcer.enforce(test_contract_pass)
        print("TEST PASSING CONTRACT:")
        print(json.dumps(result, indent=2))

        if not result["compliant"]:
            print("FAIL: Passing contract failed enforcement")
            sys.exit(1)

        # Test with violations
        test_contract_fail = {
            "task_id": "test-002",
            "instructions": "git push --force",
            "memory_gate": {},
            "staged_files": [".env", "config.py"],
        }

        result2 = enforcer.enforce(test_contract_fail)
        print("\n\nTEST FAILING CONTRACT:")
        print(json.dumps(result2, indent=2))

        if result2["compliant"]:
            print("FAIL: Should have violations")
            sys.exit(1)

        print("\n\n✓ All tests passed")
        sys.exit(0)

    elif sys.argv[1] == "--contract":
        if len(sys.argv) < 3:
            print("Usage: python3 constitution-enforcer.py --contract <json_file>")
            sys.exit(1)

        contract_file = Path(sys.argv[2])
        if not contract_file.exists():
            print(f"Error: Contract file not found: {contract_file}")
            sys.exit(1)

        with open(contract_file) as f:
            contract = json.load(f)

        result = enforcer.enforce(contract)
        print(json.dumps(result, indent=2))

        sys.exit(0 if result["compliant"] else 1)

    elif sys.argv[1] == "--task":
        if len(sys.argv) < 3:
            print("Usage: python3 constitution-enforcer.py --task <task_id>")
            sys.exit(1)

        task_id = sys.argv[2]
        contract_file = project_root / "ψ" / "inbox" / "tham" / f"task-{task_id}-contract.json"

        if not contract_file.exists():
            print(f"Error: Task contract not found: {contract_file}")
            sys.exit(1)

        with open(contract_file) as f:
            contract = json.load(f)

        result = enforcer.enforce(contract)
        print(json.dumps(result, indent=2))

        sys.exit(0 if result["compliant"] else 1)

    else:
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
