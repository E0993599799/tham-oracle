#!/usr/bin/env python3
"""
Phase 9C: Secret Detector
Scan for 20+ secret patterns: API keys, tokens, passwords, private keys, .env content

Usage:
    python3 secret-detector.py --scan <file_or_text>
    python3 secret-detector.py --contract <json_file>
    python3 secret-detector.py --test
"""

import sys
import json
import re
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple


class SecretDetector:
    """Scan for secret patterns"""

    # 20+ secret patterns
    SECRET_PATTERNS = {
        "api_key_generic": {
            "pattern": r"api[_-]?key\s*[=:]\s*['\"]([a-zA-Z0-9\-_.]+)['\"]",
            "type": "API Key (Generic)",
        },
        "api_key_aws": {
            "pattern": r"(AKIA[0-9A-Z]{16})",
            "type": "AWS Access Key",
        },
        "api_key_github": {
            "pattern": r"ghp_[a-zA-Z0-9]{36,255}",
            "type": "GitHub Personal Token",
        },
        "api_key_openai": {
            "pattern": r"sk-[a-zA-Z0-9]{20,}",
            "type": "OpenAI API Key",
        },
        "token_bearer": {
            "pattern": r"bearer\s+[a-zA-Z0-9\.\-_]{20,}",
            "type": "Bearer Token",
        },
        "token_jwt": {
            "pattern": r"eyJ[a-zA-Z0-9_\-\.]+\.eyJ[a-zA-Z0-9_\-\.]+\.[a-zA-Z0-9_\-\.]+",
            "type": "JWT Token",
        },
        "password_in_url": {
            "pattern": r"(https?://[^:]+:[^@]+@|postgres://[^:]+:[^@]+@)",
            "type": "Password in URL",
        },
        "password_equals": {
            "pattern": r"password\s*[=:]\s*['\"]([^'\"]+)['\"]",
            "type": "Password (Explicit)",
        },
        "private_key_rsa": {
            "pattern": r"-----BEGIN RSA PRIVATE KEY-----",
            "type": "RSA Private Key",
        },
        "private_key_pem": {
            "pattern": r"-----BEGIN PRIVATE KEY-----",
            "type": "Private Key (PEM)",
        },
        "private_key_openssh": {
            "pattern": r"-----BEGIN OPENSSH PRIVATE KEY-----",
            "type": "OpenSSH Private Key",
        },
        "database_password": {
            "pattern": r"(db|database)[_-]?password\s*[=:]\s*['\"]([^'\"]+)['\"]",
            "type": "Database Password",
        },
        "database_url": {
            "pattern": r"(mysql|postgres|mongodb)://([^:]+):([^@]+)@",
            "type": "Database URL with Credentials",
        },
        "env_secret_var": {
            "pattern": r"(SECRET|APIKEY|TOKEN|PASSWD|PASSWORD|CREDENTIAL)\s*[=:]\s*['\"]?[a-zA-Z0-9\-_.+/=]{16,}['\"]?",
            "type": "Secret Environment Variable",
        },
        "aws_secret_key": {
            "pattern": r"aws[_-]?secret[_-]?access[_-]?key\s*[=:]\s*['\"]([a-zA-Z0-9/+=]{40})['\"]",
            "type": "AWS Secret Access Key",
        },
        "google_api_key": {
            "pattern": r"AIza[0-9A-Za-z\-_]{35}",
            "type": "Google API Key",
        },
        "slack_token": {
            "pattern": r"xox[baprs]-[0-9a-zA-Z]{10,48}",
            "type": "Slack Token",
        },
        "stripe_key": {
            "pattern": r"sk_(?:live|test)_[0-9a-zA-Z]{20,32}",
            "type": "Stripe Key",
        },
        "telegram_token": {
            "pattern": r"\d+:[A-Za-z0-9_-]{34,40}",
            "type": "Telegram Bot Token",
        },
        "private_key_generic": {
            "pattern": r"-----BEGIN.*PRIVATE.*KEY-----",
            "type": "Private Key (Generic)",
        },
        "env_file_content": {
            "pattern": r"\.env.*=.*(?=\n|$)",
            "type": ".env File Content",
        },
    }

    def __init__(self):
        self.detected_secrets = []

    def scan_text(self, text: str) -> Dict:
        """Scan text for secret patterns"""
        self.detected_secrets = []
        clean = True

        for key, pattern_info in self.SECRET_PATTERNS.items():
            matches = re.finditer(pattern_info["pattern"], text, re.IGNORECASE | re.MULTILINE)

            for match in matches:
                clean = False
                start = max(0, match.start() - 20)
                end = min(len(text), match.end() + 20)
                context = text[start:end].replace("\n", " ")

                # Mask the actual secret
                secret_value = match.group(0)
                masked = self._mask_secret(secret_value)

                self.detected_secrets.append({
                    "type": pattern_info["type"],
                    "pattern_key": key,
                    "masked_value": masked,
                    "context": context,
                    "match_length": len(secret_value),
                })

        return {
            "clean": clean,
            "detected_secrets": self.detected_secrets,
            "secret_count": len(self.detected_secrets),
            "timestamp": datetime.utcnow().isoformat(),
        }

    def scan_file(self, file_path: Path) -> Dict:
        """Scan file for secrets"""
        if not file_path.exists():
            return {
                "clean": False,
                "error": f"File not found: {file_path}",
                "detected_secrets": [],
            }

        try:
            with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
        except Exception as e:
            return {
                "clean": False,
                "error": f"Cannot read file: {str(e)}",
                "detected_secrets": [],
            }

        result = self.scan_text(content)
        result["file"] = str(file_path)
        return result

    def scan_contract(self, contract: Dict) -> Dict:
        """Scan task contract for secrets"""
        contract_str = json.dumps(contract)
        result = self.scan_text(contract_str)
        result["contract_id"] = contract.get("task_id")
        return result

    def scan_staged_files(self, staged_files: List[str]) -> Dict:
        """Scan multiple staged files"""
        results = {
            "clean": True,
            "scanned_files": [],
            "total_secrets": 0,
        }

        for file_str in staged_files:
            file_path = Path(file_str)
            result = self.scan_file(file_path)

            results["scanned_files"].append(result)

            if not result["clean"]:
                results["clean"] = False
                results["total_secrets"] += result.get("secret_count", 0)

        return results

    @staticmethod
    def _mask_secret(secret: str) -> str:
        """Mask sensitive portion of secret"""
        if len(secret) <= 4:
            return "***"

        if len(secret) <= 12:
            return secret[:2] + "*" * (len(secret) - 4) + secret[-2:]

        return secret[:3] + "*" * (len(secret) - 6) + secret[-3:]


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    detector = SecretDetector()

    if sys.argv[1] == "--test":
        # Test 1: Clean text
        clean_result = detector.scan_text("This is a clean message with no secrets")
        assert clean_result["clean"], "Clean text should pass"
        assert clean_result["secret_count"] == 0
        print("✓ Clean text test passed")

        # Test 2: AWS Key detection
        aws_key = "AKIAIOSFODNN7EXAMPLE"
        aws_result = detector.scan_text(f"aws_key = {aws_key}")
        assert not aws_result["clean"], "Should detect AWS key"
        assert any("AWS" in s["type"] for s in aws_result["detected_secrets"])
        print("✓ AWS Key detection test passed")

        # Test 3: API Key detection
        api_key = "api_key = 'sk-1234567890abcdef1234567890'"
        api_result = detector.scan_text(api_key)
        assert not api_result["clean"], "Should detect API key"
        print("✓ API Key detection test passed")

        # Test 4: JWT Token detection
        jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
        jwt_result = detector.scan_text(jwt)
        assert not jwt_result["clean"], "Should detect JWT"
        assert any("JWT" in s["type"] for s in jwt_result["detected_secrets"])
        print("✓ JWT Token detection test passed")

        # Test 5: Password in URL
        db_url = "postgres://user:mypassword123@localhost:5432/db"
        db_result = detector.scan_text(db_url)
        assert not db_result["clean"], "Should detect password in URL"
        print("✓ Password in URL detection test passed")

        # Test 6: Masking
        secret = "super_secret_password_12345"
        masked = detector._mask_secret(secret)
        assert secret not in masked, "Secret should be masked"
        assert masked.count("*") > 0, "Should contain mask characters"
        print("✓ Secret masking test passed")

        print("\n✓ All 6 tests passed")
        sys.exit(0)

    elif sys.argv[1] == "--scan":
        if len(sys.argv) < 3:
            print("Usage: python3 secret-detector.py --scan <file_or_text>")
            sys.exit(1)

        path_or_text = sys.argv[2]
        file_path = Path(path_or_text)

        if file_path.exists():
            result = detector.scan_file(file_path)
        else:
            result = detector.scan_text(path_or_text)

        print(json.dumps(result, indent=2))
        sys.exit(0 if result["clean"] else 1)

    elif sys.argv[1] == "--contract":
        if len(sys.argv) < 3:
            print("Usage: python3 secret-detector.py --contract <json_file>")
            sys.exit(1)

        contract_file = Path(sys.argv[2])
        if not contract_file.exists():
            print(f"Error: Contract file not found: {contract_file}")
            sys.exit(1)

        with open(contract_file) as f:
            contract = json.load(f)

        result = detector.scan_contract(contract)
        print(json.dumps(result, indent=2))
        sys.exit(0 if result["clean"] else 1)

    else:
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
