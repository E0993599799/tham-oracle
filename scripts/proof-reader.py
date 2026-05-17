#!/usr/bin/env python3
"""
Proof Reader — Independent Verification
Validates proof completeness and accuracy without relying on self-reports.
"""

import json
import subprocess
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple

REPO_ROOT = Path(__file__).parent.parent


class ProofReader:
    """Independent proof verification without self-reporting."""

    def __init__(self):
        self.repo_root = REPO_ROOT
        self.proofs_dir = self.repo_root / "ψ" / "memory" / "proofs"

    def verify_proof(self, proof_file: Path) -> Dict:
        """Verify proof independently via multiple methods."""
        methods = []
        all_verified = True

        # Method 1: JSON validity check
        json_valid = self._verify_json(proof_file)
        methods.append({"name": "JSON Validity", "result": json_valid})
        if not json_valid:
            all_verified = False

        # Method 2: Required fields check
        fields_ok, missing = self._verify_required_fields(proof_file)
        methods.append({"name": "Required Fields", "result": fields_ok, "missing": missing})
        if not fields_ok:
            all_verified = False

        # Method 3: File existence check (for file-based proofs)
        file_exists, file_path = self._verify_file_exists(proof_file)
        methods.append({"name": "File Existence", "result": file_exists, "path": file_path})

        # Method 4: Git history check (for code changes)
        git_verified = self._verify_git_history(proof_file)
        methods.append({"name": "Git History", "result": git_verified})

        # Method 5: Hash verification (for content integrity)
        hash_ok = self._verify_hash(proof_file)
        methods.append({"name": "Content Hash", "result": hash_ok})
        if not hash_ok:
            all_verified = False

        return {
            "proof_file": str(proof_file),
            "verified": all_verified,
            "methods": methods,
            "timestamp": datetime.now().isoformat(),
        }

    def _verify_json(self, proof_file: Path) -> bool:
        """Check if proof file is valid JSON."""
        try:
            with open(proof_file) as f:
                json.load(f)
            return True
        except (json.JSONDecodeError, IOError):
            return False

    def _verify_required_fields(self, proof_file: Path) -> Tuple[bool, List[str]]:
        """Check for required proof fields."""
        required = {"proof_id", "contract_id", "status", "evidence"}
        try:
            with open(proof_file) as f:
                data = json.load(f)
            missing = list(required - set(data.keys()))
            return len(missing) == 0, missing
        except:
            return False, list(required)

    def _verify_file_exists(self, proof_file: Path) -> Tuple[bool, str]:
        """Verify referenced files actually exist."""
        try:
            with open(proof_file) as f:
                proof = json.load(f)
            evidence = proof.get("evidence", {})

            # Check if any artifact_path exists
            artifact_path = evidence.get("artifact_path") or evidence.get("file_path")
            if artifact_path:
                full_path = self.repo_root / artifact_path
                return full_path.exists(), str(full_path)
            return True, "N/A"
        except:
            return False, ""

    def _verify_git_history(self, proof_file: Path) -> bool:
        """Verify proof against git history (for commits)."""
        try:
            with open(proof_file) as f:
                proof = json.load(f)

            evidence = proof.get("evidence", {})
            commit_hash = evidence.get("commit_hash")

            if not commit_hash:
                return True  # Not a git proof, skip

            # Verify commit exists in git
            result = subprocess.run(
                ["git", "cat-file", "-t", commit_hash],
                cwd=self.repo_root,
                capture_output=True,
                timeout=5,
            )
            return result.returncode == 0
        except:
            return False

    def _verify_hash(self, proof_file: Path) -> bool:
        """Verify content hash for integrity."""
        import hashlib
        try:
            with open(proof_file) as f:
                proof = json.load(f)

            stored_hash = proof.get("content_hash")
            if not stored_hash:
                return True  # No hash to verify

            # Recompute hash from evidence
            evidence_str = json.dumps(proof.get("evidence", {}), sort_keys=True)
            computed_hash = hashlib.sha256(evidence_str.encode()).hexdigest()

            return computed_hash == stored_hash
        except:
            return False

    def verify_all(self) -> Dict:
        """Verify all proofs in the system."""
        results = []
        verified_count = 0

        if self.proofs_dir.exists():
            for proof_file in self.proofs_dir.glob("*.json"):
                result = self.verify_proof(proof_file)
                results.append(result)
                if result["verified"]:
                    verified_count += 1

        return {
            "total_proofs": len(results),
            "verified": verified_count,
            "verification_rate": (verified_count / len(results) * 100) if results else 100,
            "results": results,
            "timestamp": datetime.now().isoformat(),
        }


def main():
    reader = ProofReader()
    summary = reader.verify_all()

    print("\n" + "=" * 60)
    print("PROOF READER — INDEPENDENT VERIFICATION")
    print("=" * 60)
    print(f"Total proofs: {summary['total_proofs']}")
    print(f"Verified: {summary['verified']}/{summary['total_proofs']}")
    print(f"Verification rate: {summary['verification_rate']:.1f}%")
    print("=" * 60 + "\n")

    # Save results
    output_file = REPO_ROOT / "ψ" / "memory" / "resonance" / "proof-verification.json"
    output_file.parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, "w") as f:
        json.dump(summary, f, indent=2)
    print(f"✓ Results saved to: {output_file}")


if __name__ == "__main__":
    main()
