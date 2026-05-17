#!/usr/bin/env python3
"""
Phase 9B: Risk Classifier
Classify task risk level and reversibility

Risk levels:
- CRITICAL: force push, drop table, rm -rf, delete all, hard reset
- HIGH: git push, db migration, production deploy, credential rotation
- MEDIUM: git commit, file write, API call, restart service
- LOW: read, search, analyze, summarize, test

Usage:
    python3 risk-classifier.py --contract <json_file>
    python3 risk-classifier.py --text "<task description>"
    python3 risk-classifier.py --test
"""

import sys
import json
import re
from pathlib import Path
from datetime import datetime
from typing import Dict, List


class RiskClassifier:
    """Classify task risk level and reversibility"""

    # Pattern definitions for risk levels
    CRITICAL_PATTERNS = [
        r"\bgit\s+push\s+(--force|-f|--force-with-lease)",
        r"\brm\s+-rf",
        r"\brmdir\s+/s\s+/q",
        r"\bdrop\s+table",
        r"\bdrop\s+database",
        r"\btruncate\s+table",
        r"\bdelete\s+from.*where.*1=1",
        r"\bgit\s+reset\s+--hard",
        r"\bgit\s+clean\s+-fd",
        r"\bproduction.*delete",
        r"\bdestroy.*all",
        r"\b(rm|del)\s+\*.*\*",
    ]

    HIGH_PATTERNS = [
        r"\bgit\s+push(?!\s+--force)",
        r"\bgit\s+rebase",
        r"\bdb.*migration",
        r"\bdatabase.*migration",
        r"\bproduction.*deploy",
        r"\bprod.*deploy",
        r"\bproduction.*change",
        r"\bdeploy.*production",
        r"\bcredential\s+rotation",
        r"\b(restart|stop|kill)\s+(service|server|process)",
        r"\bupdate.*table\s+set",
        r"\balter\s+table",
        r"\bgit\s+tag\s+-d",
        r"\bgit\s+branch\s+-D",
    ]

    MEDIUM_PATTERNS = [
        r"\bgit\s+commit",
        r"\bgit\s+add",
        r"\bwrite.*file",
        r"\bcreate.*file",
        r"\bedit.*config",
        r"\bmodify.*config",
        r"\badd.*to.*database",
        r"\binsert\s+into",
        r"\bupdate.*database",
        r"\bAPI\s+call",
        r"\bHTTP\s+request",
        r"\bfile.*modify",
        r"\bconfig.*change",
        r"\bset.*env",
    ]

    LOW_PATTERNS = [
        r"\bread\s+(file|log)",
        r"\bgrep",
        r"\bsearch",
        r"\bfind",
        r"\blist",
        r"\bcat",
        r"\bhead",
        r"\btail",
        r"\banalyze",
        r"\binspect",
        r"\bsummarize",
        r"\btest",
        r"\bvalidate",
        r"\bcheck",
        r"\bquery\s+database",
        r"\bselect\s+from",
    ]

    def __init__(self):
        self.signals_detected = []
        self.reversible = True

    def _match_patterns(self, text: str, patterns: List[str]) -> bool:
        """Check if text matches any pattern"""
        text_lower = text.lower()
        for pattern in patterns:
            if re.search(pattern, text_lower):
                return True
        return False

    def _extract_signals(self, text: str):
        """Extract specific risk signals"""
        signals = []

        if re.search(r"\bforce\s*push", text, re.IGNORECASE):
            signals.append("force_push_detected")

        if re.search(r"\brm\s+-rf", text, re.IGNORECASE):
            signals.append("destructive_rm_detected")

        if re.search(r"\bdrop\s+(table|database)", text, re.IGNORECASE):
            signals.append("drop_database_detected")

        if re.search(r"\bproduction", text, re.IGNORECASE):
            signals.append("production_env_detected")

        if re.search(r"\bcredential|password|token|secret|key", text, re.IGNORECASE):
            signals.append("credential_operation_detected")

        if re.search(r"\b(restart|stop|kill)\s+(service|server)", text, re.IGNORECASE):
            signals.append("service_control_detected")

        if re.search(r"\b(hard|force).*reset", text, re.IGNORECASE):
            signals.append("hard_reset_detected")

        if re.search(r"\bdelete.*all", text, re.IGNORECASE):
            signals.append("bulk_delete_detected")

        return signals

    def _check_reversibility(self, risk_level: str, text: str) -> bool:
        """Check if action is reversible"""
        # CRITICAL = never reversible
        if risk_level == "CRITICAL":
            return False

        # HIGH = generally reversible with effort
        if risk_level == "HIGH":
            return True

        # MEDIUM/LOW = reversible
        return True

    def classify(self, task_text: str, context: Dict = None) -> Dict:
        """Classify task risk"""
        if context is None:
            context = {}

        self.signals_detected = []

        # Extract signals
        self.signals_detected = self._extract_signals(task_text)

        # Classify by risk level
        if self._match_patterns(task_text, self.CRITICAL_PATTERNS):
            risk_level = "CRITICAL"
            confidence = 0.95
        elif self._match_patterns(task_text, self.HIGH_PATTERNS):
            risk_level = "HIGH"
            confidence = 0.90
        elif self._match_patterns(task_text, self.MEDIUM_PATTERNS):
            risk_level = "MEDIUM"
            confidence = 0.85
        else:
            risk_level = "LOW"
            confidence = 0.95

        # Check reversibility
        reversible = self._check_reversibility(risk_level, task_text)

        # Add context signals
        if context.get("human_approval_provided"):
            confidence += 0.05

        if context.get("rollback_plan_defined"):
            reversible = True

        # Clamp confidence to 0-1
        confidence = min(1.0, confidence)

        return {
            "risk_level": risk_level,
            "reversible": reversible,
            "signals_detected": self.signals_detected,
            "confidence": confidence,
            "timestamp": datetime.utcnow().isoformat(),
            "context": context,
        }

    def classify_contract(self, contract: Dict) -> Dict:
        """Classify risk from task contract"""
        task_text = f"""
        Task ID: {contract.get('task_id')}
        Instructions: {contract.get('instructions', '')}
        Command: {contract.get('command', '')}
        Target Lane: {contract.get('target_lane', '')}
        Staged Files: {' '.join(contract.get('staged_files', []))}
        """

        context = {
            "task_id": contract.get("task_id"),
            "human_approval_provided": bool(contract.get("human_approval")),
            "rollback_plan_defined": bool(contract.get("rollback_plan")),
            "target_lane": contract.get("target_lane"),
        }

        return self.classify(task_text, context)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    classifier = RiskClassifier()

    if sys.argv[1] == "--test":
        # Test CRITICAL
        result = classifier.classify("git push --force to rewrite history")
        assert result["risk_level"] == "CRITICAL", f"Expected CRITICAL, got {result['risk_level']}"
        assert not result["reversible"], "Force push should be irreversible"
        print("✓ CRITICAL test passed")

        # Test HIGH
        result = classifier.classify("Deploy to production server")
        assert result["risk_level"] == "HIGH", f"Expected HIGH, got {result['risk_level']}"
        print("✓ HIGH test passed")

        # Test MEDIUM
        result = classifier.classify("git commit and push changes")
        assert result["risk_level"] == "MEDIUM", f"Expected MEDIUM, got {result['risk_level']}"
        print("✓ MEDIUM test passed")

        # Test LOW
        result = classifier.classify("Read and analyze the log files")
        assert result["risk_level"] == "LOW", f"Expected LOW, got {result['risk_level']}"
        print("✓ LOW test passed")

        # Test signal detection
        result = classifier.classify("Rotate production credentials")
        assert "credential_operation_detected" in result["signals_detected"]
        assert "production_env_detected" in result["signals_detected"]
        print("✓ Signal detection test passed")

        print("\n✓ All tests passed")
        sys.exit(0)

    elif sys.argv[1] == "--contract":
        if len(sys.argv) < 3:
            print("Usage: python3 risk-classifier.py --contract <json_file>")
            sys.exit(1)

        contract_file = Path(sys.argv[2])
        if not contract_file.exists():
            print(f"Error: Contract file not found: {contract_file}")
            sys.exit(1)

        with open(contract_file) as f:
            contract = json.load(f)

        classifier_inst = RiskClassifier()
        result = classifier_inst.classify_contract(contract)
        print(json.dumps(result, indent=2))
        sys.exit(0)

    elif sys.argv[1] == "--text":
        if len(sys.argv) < 3:
            print("Usage: python3 risk-classifier.py --text '<task description>'")
            sys.exit(1)

        task_text = " ".join(sys.argv[2:])
        result = classifier.classify(task_text)
        print(json.dumps(result, indent=2))
        sys.exit(0)

    else:
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
