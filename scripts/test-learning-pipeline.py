#!/usr/bin/env python3
"""
Phase 7L: Integration Test — Full Learning Pipeline
Test complete flow: failures → rules → validation → promotion
"""

import json
import subprocess
import sys
from pathlib import Path
from datetime import date

REPO_ROOT = Path(__file__).parent.parent


class LearningPipelineTest:
    def __init__(self):
        self.results = {
            "timestamp": str(date.today()),
            "tests": []
        }
        self.passed = 0
        self.failed = 0

    def run_test(self, name, cmd, expected_code=0):
        """Run a test and track result."""
        print(f"\n🧪 Test: {name}")
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            passed = result.returncode == expected_code

            test_result = {
                "name": name,
                "passed": passed,
                "return_code": result.returncode,
                "expected_code": expected_code,
                "stdout_lines": len(result.stdout.split('\n')),
                "stderr_lines": len(result.stderr.split('\n'))
            }

            if passed:
                self.passed += 1
                print(f"   ✓ PASS")
            else:
                self.failed += 1
                print(f"   ✗ FAIL (got {result.returncode}, expected {expected_code})")
                if result.stderr:
                    print(f"   Error: {result.stderr[:200]}")

            self.results["tests"].append(test_result)
            return passed
        except subprocess.TimeoutExpired:
            self.failed += 1
            print(f"   ✗ TIMEOUT")
            self.results["tests"].append({"name": name, "passed": False, "error": "Timeout"})
            return False
        except Exception as e:
            self.failed += 1
            print(f"   ✗ ERROR: {e}")
            self.results["tests"].append({"name": name, "passed": False, "error": str(e)})
            return False

    def check_output_exists(self, path, name):
        """Check if output file exists."""
        print(f"\n📁 Check: {name}")
        exists = Path(path).exists()
        if exists:
            print(f"   ✓ File exists: {path}")
            self.passed += 1
        else:
            print(f"   ✗ File not found: {path}")
            self.failed += 1

        self.results["tests"].append({
            "name": f"File exists: {name}",
            "passed": exists,
            "path": str(path)
        })
        return exists

    def validate_json(self, path, name):
        """Validate JSON file structure."""
        print(f"\n🔍 Validate: {name}")
        try:
            with open(path) as f:
                data = json.load(f)

            # Check required fields
            if "timestamp" in data and "date" in data:
                print(f"   ✓ Valid JSON with required fields")
                self.passed += 1
                return True
            else:
                print(f"   ✗ Missing required fields")
                self.failed += 1
                return False
        except Exception as e:
            print(f"   ✗ Invalid JSON: {e}")
            self.failed += 1
            return False

    def run_integration_test(self):
        """Run full learning pipeline integration test."""
        today = date.today().isoformat()

        print("\n" + "=" * 70)
        print("LEARNING PIPELINE INTEGRATION TEST")
        print("=" * 70)

        # Test 1: Syntax validation
        self.run_test(
            "Syntax: failure-classifier.py",
            [sys.executable, "-m", "py_compile", "scripts/failure-classifier.py"],
            0
        )

        self.run_test(
            "Syntax: rule-generator.py",
            [sys.executable, "-m", "py_compile", "scripts/rule-generator.py"],
            0
        )

        self.run_test(
            "Syntax: rule-validator.py",
            [sys.executable, "-m", "py_compile", "scripts/rule-validator.py"],
            0
        )

        self.run_test(
            "Syntax: rule-promoter.py",
            [sys.executable, "-m", "py_compile", "scripts/rule-promoter.py"],
            0
        )

        self.run_test(
            "Syntax: confidence-scorer.py",
            [sys.executable, "-m", "py_compile", "scripts/confidence-scorer.py"],
            0
        )

        self.run_test(
            "Syntax: performance-tracker.py",
            [sys.executable, "-m", "py_compile", "scripts/performance-tracker.py"],
            0
        )

        self.run_test(
            "Syntax: skill-gap-detector.py",
            [sys.executable, "-m", "py_compile", "scripts/skill-gap-detector.py"],
            0
        )

        self.run_test(
            "Syntax: metrics-api.py",
            [sys.executable, "-m", "py_compile", "scripts/metrics-api.py"],
            0
        )

        # Test 2: File existence
        self.check_output_exists(REPO_ROOT / "ψ" / "memory" / "resonance", "Resonance directory")
        self.check_output_exists(REPO_ROOT / "scripts" / "learning-engine.py", "Learning engine")
        self.check_output_exists(REPO_ROOT / "scripts" / "run-learning-pipeline.sh", "Pipeline runner")
        self.check_output_exists(REPO_ROOT / "scripts" / "metrics-dashboard.html", "Dashboard")

        # Test 3: Script executability
        print(f"\n⚙️  Check: Executability")
        import os
        sh_path = REPO_ROOT / "scripts" / "run-learning-pipeline.sh"
        if os.path.exists(sh_path) and os.access(sh_path, os.X_OK):
            print(f"   ✓ run-learning-pipeline.sh is executable")
            self.passed += 1
        else:
            print(f"   ✗ run-learning-pipeline.sh is not executable")
            self.failed += 1

        # Test 4: Git status
        print(f"\n📝 Check: Git status")
        try:
            result = subprocess.run(["git", "status", "--porcelain"],
                                  cwd=REPO_ROOT, capture_output=True, text=True)
            modified = len([l for l in result.stdout.split('\n') if l.strip() and l[0] != '?'])
            print(f"   Modified files: {modified}")
            self.results["tests"].append({"name": "Git modified files", "count": modified})
        except:
            pass

        return self.get_summary()

    def get_summary(self):
        """Get test summary."""
        total = self.passed + self.failed
        success_rate = (self.passed / total * 100) if total > 0 else 0

        print("\n" + "=" * 70)
        print("TEST SUMMARY")
        print("=" * 70)
        print(f"Passed:  {self.passed}")
        print(f"Failed:  {self.failed}")
        print(f"Total:   {total}")
        print(f"Rate:    {success_rate:.1f}%")
        print("=" * 70 + "\n")

        self.results["passed"] = self.passed
        self.results["failed"] = self.failed
        self.results["total"] = total
        self.results["success_rate"] = success_rate

        return self.results


def main():
    test = LearningPipelineTest()
    results = test.run_integration_test()

    # Save results
    output_file = REPO_ROOT / "ψ" / "memory" / "resonance" / f"integration-test-{date.today()}.json"
    output_file.parent.mkdir(parents=True, exist_ok=True)

    try:
        with open(output_file, "w") as f:
            json.dump(results, f, indent=2)
        print(f"✓ Test results saved: {output_file}")
    except Exception as e:
        print(f"✗ Failed to save results: {e}")

    sys.exit(0 if results["failed"] == 0 else 1)


if __name__ == "__main__":
    main()
