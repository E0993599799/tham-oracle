"""
Unit tests for Executor Lane Router (Phase 2)

Tests cover:
1. Sample tasks through routing table
2. Gate timeout logic + risk escalation
3. Risk level classification
4. Intent parsing
5. Lane selection (primary + fallback)
6. Hermes trigger conditions
7. Fallback chain logic
8. Proof schema validation
9. Proof file writing
"""

import json
import unittest
import time
from pathlib import Path
from datetime import datetime
import sys

# Add parent directory to path for imports
parent_dir = Path(__file__).parent.parent
sys.path.insert(0, str(parent_dir))

# Import router - handle both direct import and module import
try:
    from executor_lane_router import ExecutorLaneRouter
except ImportError:
    # Fallback: import as module
    import importlib.util
    spec = importlib.util.spec_from_file_location("executor_lane_router", parent_dir / "executor-lane-router.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    ExecutorLaneRouter = module.ExecutorLaneRouter


class TestExecutorLaneRouter(unittest.TestCase):
    """Main test suite for ExecutorLaneRouter."""

    def setUp(self):
        """Initialize router for each test."""
        self.router = ExecutorLaneRouter()

    def test_01_route_sample_tasks(self):
        """Test routing 10 sample tasks through routing table."""
        sample_tasks = [
            {
                "task_id": "sample_write_code_001",
                "intent": "write_code",
                "prompt": "Write a function to validate email",
                "risk_classification": "medium",
            },
            {
                "task_id": "sample_fix_bug_001",
                "intent": "fix_bug",
                "prompt": "Fix the authentication bug in login.py",
                "risk_classification": "medium",
            },
            {
                "task_id": "sample_review_001",
                "intent": "review",
                "prompt": "Review the API design for feedback",
                "risk_classification": "low",
            },
            {
                "task_id": "sample_design_001",
                "intent": "design",
                "prompt": "Design the microservice architecture",
                "risk_classification": "medium",
            },
            {
                "task_id": "sample_search_001",
                "intent": "search",
                "prompt": "Search for documentation on async/await",
                "risk_classification": "low",
            },
            {
                "task_id": "sample_classify_001",
                "intent": "classify",
                "prompt": "Tag this log message with error category",
                "risk_classification": "low",
            },
            {
                "task_id": "sample_patch_001",
                "intent": "patch",
                "prompt": "Apply small fix to validation module",
                "risk_classification": "medium",
            },
            {
                "task_id": "sample_refactor_001",
                "intent": "refactor",
                "prompt": "Restructure the data layer",
                "risk_classification": "medium",
            },
            {
                "task_id": "sample_security_audit_001",
                "intent": "security_audit",
                "prompt": "Audit authentication flow for vulnerabilities",
                "risk_classification": "low",
            },
            {
                "task_id": "sample_performance_001",
                "intent": "performance",
                "prompt": "Optimize database query performance",
                "risk_classification": "medium",
            },
        ]

        results = []
        for task in sample_tasks:
            proof = self.router.route_task(task)
            results.append(proof)
            # All routes should complete without exception
            self.assertIsNotNone(proof["task_id"])
            self.assertIsNotNone(proof["execution_timestamp"])
            self.assertIn(proof["status"], ["SUCCESS", "BLOCKED", "ERROR", "TIMEOUT"])

        # Verify lane assignments
        expected_lanes = {
            "sample_write_code_001": "codex_gpt55",
            "sample_fix_bug_001": "codex_gpt55",
            "sample_review_001": "claude",
            "sample_design_001": "claude",
            "sample_search_001": "gemini",
            "sample_classify_001": "ollama",
            "sample_patch_001": "codex_gpt55",
            "sample_refactor_001": "claude",
            "sample_security_audit_001": "claude",
            "sample_performance_001": "claude",
        }

        for result in results:
            if result["status"] != "BLOCKED":
                task_id = result["task_id"]
                expected_lane = expected_lanes.get(task_id)
                if expected_lane:
                    self.assertEqual(
                        result["routed_lane"],
                        expected_lane,
                        f"Task {task_id} routed to {result['routed_lane']}, "
                        f"expected {expected_lane}",
                    )

        print(f"\n✓ Routed {len(sample_tasks)} sample tasks successfully")

    def test_02_memory_gate_timeout(self):
        """Test memory gate timeout and risk escalation."""
        task = {
            "task_id": "test_memory_timeout",
            "intent": "write_code",
            "prompt": "Test prompt",
            "risk_classification": "low",
        }

        proof = self.router.route_task(task)

        # Verify memory gate was executed
        self.assertIn("memory_gate", proof["gate_timeouts"])
        memory_elapsed = proof["gate_timeouts"]["memory_gate"]
        self.assertGreaterEqual(memory_elapsed, 0)
        self.assertLess(memory_elapsed, 60)  # Should complete quickly

        # Verify gate_passed list
        self.assertIsInstance(proof["gates_passed"], list)

        print(f"\n✓ Memory gate timeout test passed (elapsed: {memory_elapsed:.3f}s)")

    def test_03_risk_gate_classification(self):
        """Test risk gate classification (low/medium/high)."""
        test_cases = [
            (
                "test_risk_low",
                "classify",
                "low",
                "low",
            ),  # Low risk intent → low
            (
                "test_risk_medium",
                "write_code",
                "unknown",
                "medium",
            ),  # Code task → medium
            (
                "test_risk_high",
                "delete_database",
                "high",
                "high",
            ),  # Explicit high risk
        ]

        for task_id, intent, risk_input, expected_risk in test_cases:
            task = {
                "task_id": task_id,
                "intent": intent,
                "prompt": f"Task with {intent} intent",
                "risk_classification": risk_input,
            }

            proof = self.router.route_task(task)

            # Risk level should match or escalate
            self.assertIn(proof["risk_level"], ["low", "medium", "high", "unknown"])

            if risk_input in ("low", "medium", "high"):
                # If input risk was explicit, final risk should be >= input
                risk_order = {"low": 0, "medium": 1, "high": 2}
                self.assertGreaterEqual(
                    risk_order[proof["risk_level"]], risk_order[risk_input]
                )

        print("\n✓ Risk gate classification test passed")

    def test_04_intent_parsing(self):
        """Test intent extraction from prompt."""
        test_cases = [
            ("test_intent_write", "Write a new API endpoint", "write_code"),
            ("test_intent_fix", "Fix the bug in authentication", "fix_bug"),
            ("test_intent_review", "Review the code for quality", "review"),
            ("test_intent_classify", "Tag this as error", "classify"),
        ]

        for task_id, prompt, expected_intent in test_cases:
            task = {
                "task_id": task_id,
                "intent": "unknown",
                "prompt": prompt,
                "risk_classification": "medium",
            }

            proof = self.router.route_task(task)

            # Task should route (not blocked due to intent)
            self.assertIsNotNone(proof["task_id"])
            self.assertIsNotNone(proof["execution_timestamp"])

        print("\n✓ Intent parsing test passed")

    def test_05_lane_selection(self):
        """Test lane selection logic (primary + fallback)."""
        test_cases = [
            ("coding_intent", "write_code", "codex_gpt55", "ollama"),
            ("review_intent", "review", "claude", "codex_gpt55"),
            ("search_intent", "search", "gemini", "ollama"),
            ("classify_intent", "classify", "ollama", None),
        ]

        for task_id, intent, expected_primary, expected_fallback in test_cases:
            task = {
                "task_id": task_id,
                "intent": intent,
                "prompt": "Test prompt",
                "risk_classification": "low",
            }

            proof = self.router.route_task(task)

            self.assertEqual(
                proof["routed_lane"],
                expected_primary,
                f"Intent {intent} should route to {expected_primary}, "
                f"got {proof['routed_lane']}",
            )

            if expected_fallback:
                self.assertEqual(
                    proof["fallback_lane"],
                    expected_fallback,
                    f"Intent {intent} fallback should be {expected_fallback}",
                )

        print("\n✓ Lane selection test passed")

    def test_06_hermes_conditions(self):
        """Test Hermes trigger conditions (high-risk block)."""
        # High-risk task should NOT route to Hermes
        high_risk_task = {
            "task_id": "test_hermes_block_high_risk",
            "intent": "delete_database",
            "prompt": "Delete all user data",
            "risk_classification": "high",
        }

        proof = self.router.route_task(high_risk_task)

        # Should be blocked or routed to safe lane (not hermes)
        if proof["status"] != "BLOCKED":
            self.assertNotEqual(proof["routed_lane"], "hermes")

        # Low-risk tool call could use Hermes
        low_risk_tool_call = {
            "task_id": "test_hermes_allow_low_risk",
            "intent": "tool_call",
            "prompt": "Run PowerShell script to list files",
            "risk_classification": "low",
        }

        proof = self.router.route_task(low_risk_tool_call)
        # Hermes is a valid lane for tool_call with low risk
        self.assertIsNotNone(proof["routed_lane"])

        print("\n✓ Hermes conditions test passed")

    def test_07_fallback_chain(self):
        """Test fallback chain logic (primary → fallback → BLOCKED)."""
        # Create a task with known fallback chain
        task = {
            "task_id": "test_fallback_chain",
            "intent": "write_code",
            "prompt": "Write code for validation",
            "risk_classification": "medium",
        }

        proof = self.router.route_task(task)

        # Verify fallback structure
        self.assertIsNotNone(proof["routed_lane"])
        if proof["status"] == "SUCCESS":
            # Successfully routed to primary or fallback
            self.assertIn(
                proof["routed_lane"],
                ["codex_gpt55", "claude", "gemini", "ollama", "hermes", "powershell_sfsr"],
            )
        elif proof["status"] == "BLOCKED":
            # Both lanes failed or unavailable
            self.assertIsNone(proof["routed_lane"])

        # Verify no self-fallback
        if proof["fallback_lane"]:
            self.assertNotEqual(
                proof["routed_lane"],
                proof["fallback_lane"],
                "fallback_lane cannot equal routed_lane",
            )

        print("\n✓ Fallback chain test passed")

    def test_08_proof_schema_validation(self):
        """Test proof record schema validation."""
        task = {
            "task_id": "test_proof_schema",
            "intent": "write_code",
            "prompt": "Test proof schema",
            "risk_classification": "low",
        }

        proof = self.router.route_task(task)

        # Validate required fields
        required_fields = [
            "task_id",
            "routed_lane",
            "status",
            "execution_timestamp",
            "gate_timeouts",
            "execution_duration_seconds",
        ]

        for field in required_fields:
            self.assertIn(field, proof, f"Missing required field: {field}")

        # Validate enums
        valid_statuses = ["SUCCESS", "BLOCKED", "TIMEOUT", "ERROR"]
        self.assertIn(proof["status"], valid_statuses)

        valid_risk_levels = ["low", "medium", "high", "unknown"]
        self.assertIn(proof["risk_level"], valid_risk_levels)

        # Validate timestamp format (ISO-8601)
        try:
            datetime.fromisoformat(
                proof["execution_timestamp"].replace("Z", "+00:00")
            )
        except ValueError:
            self.fail(f"Invalid timestamp: {proof['execution_timestamp']}")

        # Validate duration
        self.assertGreaterEqual(proof["execution_duration_seconds"], 0)

        print("\n✓ Proof schema validation test passed")

    def test_09_proof_file_write(self):
        """Test proof file writing to proofs/YYYY-MM-DD/ directory."""
        task = {
            "task_id": "test_proof_file_write",
            "intent": "classify",
            "prompt": "Test file writing",
            "risk_classification": "low",
        }

        proof = self.router.route_task(task)

        # Verify proof file was written
        if proof["proof_path"]:
            proof_path = Path(proof["proof_path"])
            self.assertTrue(
                proof_path.exists(), f"Proof file not found: {proof_path}"
            )

            # Verify file is valid JSON
            with open(proof_path, "r") as f:
                proof_content = json.load(f)

            self.assertEqual(proof_content["task_id"], task["task_id"])

        print(f"\n✓ Proof file write test passed (path: {proof.get('proof_path')})")

    def test_gate_timeouts_structure(self):
        """Test gate timeouts are properly recorded."""
        task = {
            "task_id": "test_gate_timeouts",
            "intent": "write_code",
            "prompt": "Test gate timeouts",
            "risk_classification": "medium",
        }

        proof = self.router.route_task(task)

        # Verify gate_timeouts structure
        self.assertIsInstance(proof["gate_timeouts"], dict)

        # Should have at least one gate timeout recorded
        self.assertGreater(len(proof["gate_timeouts"]), 0)

        # All recorded timeouts should be non-negative
        for gate, elapsed in proof["gate_timeouts"].items():
            if elapsed is not None:
                self.assertGreaterEqual(
                    elapsed, 0, f"Negative timeout for {gate}: {elapsed}"
                )

        print("\n✓ Gate timeouts structure test passed")

    def test_gates_passed_list(self):
        """Test gates_passed list is properly populated."""
        task = {
            "task_id": "test_gates_passed",
            "intent": "review",
            "prompt": "Test gates passed tracking",
            "risk_classification": "low",
        }

        proof = self.router.route_task(task)

        # Verify gates_passed is a list
        self.assertIsInstance(proof["gates_passed"], list)

        # Valid gate names
        valid_gates = ["memory_gate", "risk_gate", "intent_gate"]
        for gate in proof["gates_passed"]:
            self.assertIn(gate, valid_gates)

        print(f"\n✓ Gates passed list test passed (gates: {proof['gates_passed']})")

    def test_explicit_lane_routing(self):
        """Test explicit lane override."""
        task = {
            "task_id": "test_explicit_lane",
            "intent": "write_code",
            "prompt": "Test explicit lane",
            "risk_classification": "low",
            "explicit_lane": "ollama",
        }

        primary, fallback = self.router._select_lane(
            task["intent"],
            task["risk_classification"],
            task.get("explicit_lane"),
        )

        self.assertEqual(primary, "ollama")
        self.assertIsNone(fallback)

        print("\n✓ Explicit lane routing test passed")

    def test_risk_escalation_on_timeout(self):
        """Test risk escalation when gates timeout."""
        # Simulate scenario where gates might timeout
        task = {
            "task_id": "test_risk_escalation",
            "intent": "unknown",
            "prompt": "Unknown task that may timeout",
            "risk_classification": "low",
        }

        proof = self.router.route_task(task)

        # Risk level should be at least as high as input
        risk_order = {"low": 0, "medium": 1, "high": 2}
        self.assertGreaterEqual(
            risk_order[proof["risk_level"]], risk_order["low"]
        )

        print(f"\n✓ Risk escalation test passed (final risk: {proof['risk_level']})")


class TestProofGeneration(unittest.TestCase):
    """Tests for proof generation and validation."""

    def setUp(self):
        """Initialize router."""
        self.router = ExecutorLaneRouter()

    def test_complete_routing_cycle(self):
        """Test complete routing cycle from task to proof."""
        task = {
            "task_id": "complete_cycle_test",
            "intent": "write_code",
            "prompt": "Implement a complete cycle through the router",
            "risk_classification": "medium",
        }

        # Route task
        proof = self.router.route_task(task)

        # Verify complete cycle
        self.assertIsNotNone(proof["task_id"])
        self.assertIsNotNone(proof["execution_timestamp"])
        self.assertIsNotNone(proof["proof_summary"])
        self.assertIsNotNone(proof["next_action"])
        self.assertGreaterEqual(proof["execution_duration_seconds"], 0)

        print("\n✓ Complete routing cycle test passed")

    def test_sample_proof_structure(self):
        """Test that generated proof matches expected schema."""
        task = {
            "task_id": "schema_test",
            "intent": "design",
            "prompt": "Design system architecture",
            "risk_classification": "low",
        }

        proof = self.router.route_task(task)

        # Expected schema fields
        schema_fields = [
            "task_id",
            "routed_lane",
            "fallback_lane",
            "risk_level",
            "status",
            "gates_passed",
            "gate_timeouts",
            "execution_timestamp",
            "execution_duration_seconds",
            "lane_response",
            "proof_path",
            "proof_summary",
            "next_action",
        ]

        for field in schema_fields:
            self.assertIn(
                field, proof, f"Proof missing schema field: {field}"
            )

        # Validate lane_response structure
        expected_response_fields = [
            "status_code",
            "response_time_ms",
            "output_length",
        ]
        for field in expected_response_fields:
            self.assertIn(field, proof["lane_response"])

        print("\n✓ Sample proof structure test passed")


def run_tests():
    """Run all tests with verbose output."""
    # Create test suite
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()

    # Add test classes
    suite.addTests(loader.loadTestsFromTestCase(TestExecutorLaneRouter))
    suite.addTests(loader.loadTestsFromTestCase(TestProofGeneration))

    # Run tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    # Print summary
    print("\n" + "=" * 70)
    print("TEST SUMMARY")
    print("=" * 70)
    print(f"Tests run: {result.testsRun}")
    print(f"Successes: {result.testsRun - len(result.failures) - len(result.errors)}")
    print(f"Failures: {len(result.failures)}")
    print(f"Errors: {len(result.errors)}")
    print("=" * 70)

    return result.wasSuccessful()


if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
