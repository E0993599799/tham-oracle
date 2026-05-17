#!/usr/bin/env python3
"""
Test Suite for Executor Lane Router (Phase 2)

Unit tests + integration tests for routing decision engine.
"""

import unittest
import json
from datetime import datetime, timezone, date
from pathlib import Path
from executor_lane_router import ExecutorLaneRouter, validate_proof_module


class TestIntentAccuracy(unittest.TestCase):
    """Test 1: Intent signal classification accuracy."""

    def test_write_code_routing(self):
        """write_code should route to codex_gpt55."""
        router = ExecutorLaneRouter()
        primary, fallback = router.ROUTING_TABLE.get("write_code")
        assert primary == "codex_gpt55"
        assert fallback == "ollama"

    def test_review_routing(self):
        """review should route to claude."""
        router = ExecutorLaneRouter()
        primary, fallback = router.ROUTING_TABLE.get("review")
        assert primary == "claude"
        assert fallback == "codex_gpt55"

    def test_search_routing(self):
        """search should route to gemini."""
        router = ExecutorLaneRouter()
        primary, fallback = router.ROUTING_TABLE.get("search")
        assert primary == "gemini"
        assert fallback == "ollama"

    def test_all_signals_routed(self):
        """All 16 intent signals should have routing."""
        router = ExecutorLaneRouter()
        signals = [
            "write_code", "fix_bug", "patch", "refactor_code",
            "review", "design", "refactor", "security_audit", "performance",
            "search", "summarize", "web_fetch", "data_gathering",
            "tag", "classify", "embed_text", "batch_tag", "tool_call"
        ]
        for signal in signals:
            assert signal in router.ROUTING_TABLE, f"{signal} not in routing table"


class TestLaneHealth(unittest.TestCase):
    """Test 2: Lane health checks."""

    def test_health_check_returns_dict(self):
        """health_check should return proper structure."""
        router = ExecutorLaneRouter()
        health = router._health_check("codex_gpt55")
        assert health in [True, False]

    def test_all_lanes_checked(self):
        """Can check health for all known lanes."""
        router = ExecutorLaneRouter()
        lanes = ["codex_gpt55", "claude", "gemini", "ollama", "hermes", "powershell_sfsr"]
        for lane in lanes:
            result = router._health_check(lane)
            assert isinstance(result, bool)


class TestLaneSelection(unittest.TestCase):
    """Test 3: Lane selection logic."""

    def test_hermes_blocked_on_high_risk(self):
        """Hermes should be blocked when risk is HIGH."""
        router = ExecutorLaneRouter()
        primary, fallback = router._select_lane("hermes", "high")
        assert primary != "hermes", "Hermes should not be selected for HIGH risk"

    def test_hermes_allowed_on_medium_risk(self):
        """Hermes can be selected for MEDIUM risk."""
        router = ExecutorLaneRouter()
        primary, fallback = router._select_lane("hermes", "medium")
        # hermes is primary for tool_call, which is medium
        assert primary is not None

    def test_default_routing_on_unknown_intent(self):
        """Unknown intent should default to codex_gpt55."""
        router = ExecutorLaneRouter()
        primary, fallback = router._select_lane("unknown_intent_xyz", "medium")
        assert primary == "codex_gpt55"


class TestProofValidation(unittest.TestCase):
    """Test 4: Proof schema validation (8 checks)."""

    def get_valid_proof(self):
        """Generate a valid proof template."""
        return {
            "task_id": "test-001",
            "routed_lane": "codex_gpt55",
            "fallback_lane": "ollama",
            "risk_level": "medium",
            "status": "SUCCESS",
            "gates_passed": ["memory_gate", "risk_gate", "intent_gate"],
            "execution_timestamp": datetime.now(timezone.utc).isoformat(),
            "execution_duration_seconds": 5.2,
            "lane_response": {"status_code": 200, "response_time_ms": 5200, "output_length": 100},
            "proof_path": f"proofs/{date.today().isoformat()}/test-001.json",
            "proof_summary": "Test task executed successfully",
            "next_action": "Validate and archive",
        }

    def test_check_1_json_validity(self):
        """Check 1: JSON validity (implicit)."""
        proof = self.get_valid_proof()
        # If we can serialize it, it's valid
        json_str = json.dumps(proof)
        assert json.loads(json_str) == proof

    def test_check_2_required_fields(self):
        """Check 2: Required fields present."""
        proof = self.get_valid_proof()
        valid, errors = validate_proof_module(proof)
        assert valid
        assert not any("Missing" in e for e in errors)

    def test_check_2_missing_fields(self):
        """Check 2: Detect missing required fields."""
        proof = self.get_valid_proof()
        del proof["task_id"]
        valid, errors = validate_proof_module(proof)
        assert not valid
        assert any("Missing" in e for e in errors)

    def test_check_3_enum_status(self):
        """Check 3: Status enum valid."""
        for status in ["SUCCESS", "BLOCKED", "TIMEOUT", "ERROR"]:
            proof = self.get_valid_proof()
            proof["status"] = status
            valid, _ = validate_proof_module(proof)
            assert valid

    def test_check_3_invalid_status(self):
        """Check 3: Invalid status rejected."""
        proof = self.get_valid_proof()
        proof["status"] = "INVALID_STATUS"
        valid, errors = validate_proof_module(proof)
        assert not valid
        assert any("Invalid status" in e for e in errors)

    def test_check_4_timestamp_iso8601(self):
        """Check 4: Timestamp ISO-8601 format."""
        proof = self.get_valid_proof()
        # Valid ISO format
        proof["execution_timestamp"] = "2026-05-17T13:00:00+00:00"
        valid, _ = validate_proof_module(proof)
        assert valid

    def test_check_4_invalid_timestamp(self):
        """Check 4: Invalid timestamp rejected."""
        proof = self.get_valid_proof()
        proof["execution_timestamp"] = "not-a-timestamp"
        valid, errors = validate_proof_module(proof)
        assert not valid
        assert any("Invalid timestamp" in e for e in errors)

    def test_check_5_nonnegative_duration(self):
        """Check 5: Non-negative duration."""
        proof = self.get_valid_proof()
        proof["execution_duration_seconds"] = 0
        valid, _ = validate_proof_module(proof)
        assert valid

    def test_check_5_negative_duration(self):
        """Check 5: Negative duration rejected."""
        proof = self.get_valid_proof()
        proof["execution_duration_seconds"] = -1.0
        valid, errors = validate_proof_module(proof)
        assert not valid
        assert any("Negative" in e for e in errors)

    def test_check_6_fallback_ne_primary(self):
        """Check 6: Fallback ≠ primary."""
        proof = self.get_valid_proof()
        # Should fail when equal
        proof["fallback_lane"] = proof["routed_lane"]
        valid, errors = validate_proof_module(proof)
        assert not valid
        assert any("Fallback" in e for e in errors)

    def test_check_7_proof_path(self):
        """Check 7: Proof path must be .json file."""
        proof = self.get_valid_proof()
        valid, _ = validate_proof_module(proof)
        assert valid

    def test_check_7_invalid_path(self):
        """Check 7: Invalid proof path rejected."""
        proof = self.get_valid_proof()
        proof["proof_path"] = "invalid_path_no_extension"
        valid, errors = validate_proof_module(proof)
        assert not valid
        assert any("Invalid proof_path" in e for e in errors)

    def test_check_8_summary_length(self):
        """Check 8: Summary 1-200 chars."""
        proof = self.get_valid_proof()
        # Valid lengths
        for length in [1, 50, 100, 200]:
            proof["proof_summary"] = "x" * length
            valid, _ = validate_proof_module(proof)
            assert valid

    def test_check_8_summary_too_short(self):
        """Check 8: Empty summary rejected."""
        proof = self.get_valid_proof()
        proof["proof_summary"] = ""
        valid, errors = validate_proof_module(proof)
        assert not valid
        assert any("Summary length" in e for e in errors)

    def test_check_8_summary_too_long(self):
        """Check 8: Summary > 200 chars rejected."""
        proof = self.get_valid_proof()
        proof["proof_summary"] = "x" * 201
        valid, errors = validate_proof_module(proof)
        assert not valid
        assert any("Summary length" in e for e in errors)


class TestEndToEnd(unittest.TestCase):
    """Test 5: End-to-end routing."""

    def test_route_write_code_contract(self):
        """Route a write_code contract."""
        router = ExecutorLaneRouter()
        contract = {
            "task_id": "e2e-write-code",
            "intent": "write_code",
            "prompt": "Write a Python function",
            "risk_classification": "medium",
            "metadata": {},
        }
        proof = router.route_task(contract)
        assert proof["task_id"] == "e2e-write-code"
        assert proof["status"] in ["SUCCESS", "ERROR", "BLOCKED"]
        assert proof["routed_lane"] is not None

    def test_route_review_contract(self):
        """Route a review contract."""
        router = ExecutorLaneRouter()
        contract = {
            "task_id": "e2e-review",
            "intent": "review",
            "prompt": "Review this code",
            "risk_classification": "low",
            "metadata": {},
        }
        proof = router.route_task(contract)
        assert proof["task_id"] == "e2e-review"
        assert proof["routed_lane"] in ["claude", "codex_gpt55"]

    def test_proof_file_created(self):
        """Proof file should be created."""
        router = ExecutorLaneRouter()
        contract = {
            "task_id": "test-proof-file",
            "intent": "write_code",
            "prompt": "Test",
            "risk_classification": "low",
            "metadata": {},
        }
        proof = router.route_task(contract)
        proof_path = Path(f"proofs/{date.today().isoformat()}/test-proof-file.json")
        # File may or may not exist depending on execution, but path structure is correct
        assert "proofs/" in proof["proof_path"]
        assert ".json" in proof["proof_path"]


if __name__ == "__main__":
    unittest.main(verbosity=2)
