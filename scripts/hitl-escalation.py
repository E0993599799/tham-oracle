#!/usr/bin/env python3
"""
Phase 9D: Human-In-The-Loop Escalation
Trigger escalation for HIGH/CRITICAL risk, constitutional violations, or secrets detected

Usage:
    python3 hitl-escalation.py --escalate <task_contract_json>
    python3 hitl-escalation.py --wait <task_id>
    python3 hitl-escalation.py --clear <task_id>
    python3 hitl-escalation.py --test
"""

import sys
import json
import time
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import hashlib
import uuid


class HITLEscalation:
    """Human-In-The-Loop escalation system"""

    def __init__(self, inbox_root: Path):
        self.inbox_root = inbox_root
        self.tham_inbox = inbox_root / "ψ" / "inbox" / "tham"
        self.tham_inbox.mkdir(parents=True, exist_ok=True)

    def create_escalation(self, contract: Dict, reason: str, details: Dict) -> str:
        """Create HITL escalation file"""
        task_id = contract.get("task_id", f"task-{uuid.uuid4().hex[:8]}")

        escalation = {
            "task_id": task_id,
            "escalated_at": datetime.utcnow().isoformat(),
            "escalation_reason": reason,
            "escalation_details": details,
            "contract": contract,
            "status": "pending",
            "timeout_at": (datetime.utcnow() + timedelta(seconds=300)).isoformat(),
            "required_action": self._get_required_action(reason, details),
        }

        escalation_file = self.tham_inbox / f"hitl-{task_id}.json"

        with open(escalation_file, "w") as f:
            json.dump(escalation, f, indent=2)

        return task_id

    @staticmethod
    def _get_required_action(reason: str, details: Dict) -> str:
        """Determine required human action"""
        if reason == "high_risk":
            return f"Review and approve HIGH-risk task: {details.get('risk_level')}"

        if reason == "critical_risk":
            return f"CRITICAL risk detected: {details.get('signals')}"

        if reason == "constitutional_violation":
            violations = details.get("violations", [])
            rules = ", ".join([v.get("rule") for v in violations])
            return f"Constitutional violations detected: {rules}. Review and override or abort."

        if reason == "secret_detected":
            return f"Secrets detected ({details.get('count')} pattern(s)): Review contract and remove before proceeding."

        return "Human approval required before proceeding"

    def wait_for_response(self, task_id: str, timeout_seconds: int = 300) -> Optional[Dict]:
        """Wait for human response to escalation"""
        response_file = self.tham_inbox / f"hitl-{task_id}-response.json"
        start_time = time.time()

        while time.time() - start_time < timeout_seconds:
            if response_file.exists():
                try:
                    with open(response_file) as f:
                        response = json.load(f)

                    return {
                        "status": "responded",
                        "response": response,
                        "wait_time": time.time() - start_time,
                    }
                except json.JSONDecodeError:
                    pass

            time.sleep(1)

        # Timeout
        return {
            "status": "timeout",
            "timeout_seconds": timeout_seconds,
            "instruction": "Task was blocked due to escalation timeout",
        }

    def clear_escalation(self, task_id: str) -> bool:
        """Clear escalation files (after resolution)"""
        escalation_file = self.tham_inbox / f"hitl-{task_id}.json"
        response_file = self.tham_inbox / f"hitl-{task_id}-response.json"

        removed = False

        if escalation_file.exists():
            escalation_file.unlink()
            removed = True

        if response_file.exists():
            response_file.unlink()
            removed = True

        return removed

    def get_status(self, task_id: str) -> Dict:
        """Get escalation status"""
        escalation_file = self.tham_inbox / f"hitl-{task_id}.json"
        response_file = self.tham_inbox / f"hitl-{task_id}-response.json"

        if not escalation_file.exists():
            return {"status": "not_found", "task_id": task_id}

        try:
            with open(escalation_file) as f:
                escalation = json.load(f)

            result = {
                "status": "escalated",
                "task_id": task_id,
                "escalation_reason": escalation.get("escalation_reason"),
                "escalated_at": escalation.get("escalated_at"),
                "timeout_at": escalation.get("timeout_at"),
                "required_action": escalation.get("required_action"),
            }

            if response_file.exists():
                with open(response_file) as f:
                    response = json.load(f)

                result["status"] = "responded"
                result["response"] = response

            return result
        except json.JSONDecodeError:
            return {"status": "error", "task_id": task_id, "error": "Invalid escalation file"}


def escalate_task(contract: Dict, constitution_result: Dict, risk_result: Dict, secret_result: Dict) -> Dict:
    """Determine if escalation is needed and create it"""
    project_root = Path(__file__).parent.parent
    hitl = HITLEscalation(project_root)

    task_id = contract.get("task_id")
    escalation_reasons = []
    escalation_details = {}

    # Check constitutional violations
    if not constitution_result.get("compliant"):
        escalation_reasons.append("constitutional_violation")
        escalation_details["violations"] = constitution_result.get("violations", [])

    # Check risk level
    risk_level = risk_result.get("risk_level")
    if risk_level == "CRITICAL":
        escalation_reasons.append("critical_risk")
        escalation_details["risk_level"] = risk_level
        escalation_details["signals"] = risk_result.get("signals_detected", [])

    elif risk_level == "HIGH":
        escalation_reasons.append("high_risk")
        escalation_details["risk_level"] = risk_level
        escalation_details["signals"] = risk_result.get("signals_detected", [])

    # Check secrets
    if not secret_result.get("clean"):
        escalation_reasons.append("secret_detected")
        escalation_details["count"] = secret_result.get("secret_count", 0)
        escalation_details["types"] = [s.get("type") for s in secret_result.get("detected_secrets", [])]

    if not escalation_reasons:
        return {
            "needs_escalation": False,
            "task_id": task_id,
            "reason": "All safety checks passed",
        }

    # Create escalation
    primary_reason = escalation_reasons[0]
    escalated_task_id = hitl.create_escalation(contract, primary_reason, escalation_details)

    return {
        "needs_escalation": True,
        "task_id": escalated_task_id,
        "reasons": escalation_reasons,
        "escalation_file": str(hitl.tham_inbox / f"hitl-{escalated_task_id}.json"),
        "response_file": str(hitl.tham_inbox / f"hitl-{escalated_task_id}-response.json"),
    }


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    project_root = Path(__file__).parent.parent
    hitl = HITLEscalation(project_root)

    if sys.argv[1] == "--test":
        # Test 1: Create escalation
        test_contract = {
            "task_id": "test-001",
            "instructions": "Deploy to production",
            "risk_level": "HIGH",
        }

        task_id = hitl.create_escalation(
            test_contract,
            "high_risk",
            {"risk_level": "HIGH", "signals": ["production_env_detected"]},
        )

        assert task_id == "test-001", f"Expected task_id test-001, got {task_id}"
        print("✓ Create escalation test passed")

        # Test 2: Get status
        status = hitl.get_status(task_id)
        assert status["status"] == "escalated"
        assert status["task_id"] == task_id
        print("✓ Get status test passed")

        # Test 3: Clear escalation
        removed = hitl.clear_escalation(task_id)
        assert removed, "Should have removed escalation files"
        print("✓ Clear escalation test passed")

        # Test 4: Status after clear
        status2 = hitl.get_status(task_id)
        assert status2["status"] == "not_found"
        print("✓ Clear verification test passed")

        print("\n✓ All 4 tests passed")
        sys.exit(0)

    elif sys.argv[1] == "--escalate":
        if len(sys.argv) < 3:
            print("Usage: python3 hitl-escalation.py --escalate <task_contract_json>")
            sys.exit(1)

        contract_file = Path(sys.argv[2])
        if not contract_file.exists():
            print(f"Error: Contract file not found: {contract_file}")
            sys.exit(1)

        with open(contract_file) as f:
            contract = json.load(f)

        # For standalone escalation, read the validation results if provided
        constitution_file = contract_file.parent / f"{contract_file.stem}-constitution.json"
        risk_file = contract_file.parent / f"{contract_file.stem}-risk.json"
        secret_file = contract_file.parent / f"{contract_file.stem}-secret.json"

        constitution_result = {"compliant": True}
        risk_result = {"risk_level": "LOW"}
        secret_result = {"clean": True}

        if constitution_file.exists():
            with open(constitution_file) as f:
                constitution_result = json.load(f)

        if risk_file.exists():
            with open(risk_file) as f:
                risk_result = json.load(f)

        if secret_file.exists():
            with open(secret_file) as f:
                secret_result = json.load(f)

        result = escalate_task(contract, constitution_result, risk_result, secret_result)
        print(json.dumps(result, indent=2))

        sys.exit(0 if not result["needs_escalation"] else 0)

    elif sys.argv[1] == "--wait":
        if len(sys.argv) < 3:
            print("Usage: python3 hitl-escalation.py --wait <task_id>")
            sys.exit(1)

        task_id = sys.argv[2]
        timeout = int(sys.argv[3]) if len(sys.argv) > 3 else 300

        print(f"Waiting for response to escalation {task_id} (timeout: {timeout}s)")

        result = hitl.wait_for_response(task_id, timeout)
        print(json.dumps(result, indent=2))

        sys.exit(0 if result["status"] == "responded" else 1)

    elif sys.argv[1] == "--clear":
        if len(sys.argv) < 3:
            print("Usage: python3 hitl-escalation.py --clear <task_id>")
            sys.exit(1)

        task_id = sys.argv[2]
        removed = hitl.clear_escalation(task_id)

        result = {
            "task_id": task_id,
            "cleared": removed,
            "status": "cleared" if removed else "not_found",
        }

        print(json.dumps(result, indent=2))
        sys.exit(0 if removed else 1)

    else:
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
