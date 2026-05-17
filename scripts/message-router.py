#!/usr/bin/env python3
"""
Phase 10B: Message Router
Monitor agent inboxes, route messages between agents, enforce oracle-communication-law rules,
auto-cc BoB, and log all relay events.
"""

import json
import os
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional
import sys
import hashlib

REPO_ROOT = Path(__file__).parent.parent


class MessageRouter:
    """Route messages between agents with oracle-communication-law compliance."""

    # Oracle communication law rules
    ORACLE_COMMUNICATION_LAW = {
        "rule_1_respond": "Oracle must respond to every message (answer, do, or push back)",
        "rule_2_cc_bob": "Every cross-agent message must cc BoB",
        "rule_3_report_done": "Report when done",
        "rule_4_report_blocked": "Report immediately when blocked",
    }

    def __init__(self):
        self.inbox_root = REPO_ROOT / "ψ/inbox"
        self.memory_root = REPO_ROOT / "ψ/memory/resonance"
        self.memory_root.mkdir(parents=True, exist_ok=True)

        self.relay_log_file = self.memory_root / "relay-log.jsonl"
        self.processed_file = self.memory_root / "relay-processed.json"

        self.processed_messages = self._load_processed()

    def _load_processed(self) -> Dict[str, bool]:
        """Load set of already-processed message hashes."""
        try:
            if self.processed_file.exists():
                with open(self.processed_file) as f:
                    return json.load(f)
        except:
            pass
        return {}

    def _save_processed(self) -> None:
        """Save processed message hashes."""
        try:
            with open(self.processed_file, "w") as f:
                json.dump(self.processed_messages, f, indent=2)
        except Exception as e:
            print(f"Warning: failed to save processed messages: {e}")

    def _hash_message(self, agent_id: str, filename: str) -> str:
        """Create hash to detect duplicate processing."""
        content = f"{agent_id}:{filename}"
        return hashlib.md5(content.encode()).hexdigest()

    def _is_processed(self, agent_id: str, filename: str) -> bool:
        """Check if message was already processed."""
        msg_hash = self._hash_message(agent_id, filename)
        return msg_hash in self.processed_messages

    def _mark_processed(self, agent_id: str, filename: str) -> None:
        """Mark message as processed."""
        msg_hash = self._hash_message(agent_id, filename)
        self.processed_messages[msg_hash] = True
        self._save_processed()

    def _parse_message(self, filepath: Path) -> Optional[Dict]:
        """Parse a message file (JSON or plain text)."""
        try:
            if filepath.suffix == ".json":
                with open(filepath) as f:
                    return json.load(f)
            else:
                # Plain text message
                with open(filepath) as f:
                    content = f.read().strip()
                return {
                    "type": "text",
                    "content": content,
                    "timestamp": datetime.fromtimestamp(filepath.stat().st_mtime).isoformat(),
                }
        except Exception as e:
            print(f"Error parsing message {filepath}: {e}")
            return None

    def _validate_message(self, message: Dict, source_agent: str, target_agent: str) -> bool:
        """Validate message compliance with oracle-communication-law."""
        # Rule 2: cross-agent messages must be routable to BoB
        if source_agent != target_agent and "cross_agent" not in message.get("metadata", {}):
            # Auto-tag as cross-agent for BoB routing
            if "metadata" not in message:
                message["metadata"] = {}
            message["metadata"]["cross_agent"] = True

        return True

    def _route_message(self, message: Dict, source_agent: str, target_agent: str) -> bool:
        """Route a message to target agent's inbox. Return True if routed successfully."""
        try:
            target_inbox = self.inbox_root / target_agent
            target_inbox.mkdir(parents=True, exist_ok=True)

            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"{timestamp}_from-{source_agent}.json"
            target_file = target_inbox / filename

            # Preserve original message, add routing metadata
            routed_msg = {
                **message,
                "routing": {
                    "from": source_agent,
                    "to": target_agent,
                    "timestamp": datetime.now().isoformat(),
                    "routed_by": "message-router",
                },
            }

            with open(target_file, "w") as f:
                json.dump(routed_msg, f, indent=2)

            return True
        except Exception as e:
            print(f"Error routing message from {source_agent} to {target_agent}: {e}")
            return False

    def _log_relay_event(
        self, source: str, target: str, message_id: str, status: str, notes: str = ""
    ) -> None:
        """Log a relay event to relay-log.jsonl."""
        event = {
            "timestamp": datetime.now().isoformat(),
            "source_agent": source,
            "target_agent": target,
            "message_id": message_id,
            "status": status,
            "notes": notes,
        }

        try:
            with open(self.relay_log_file, "a") as f:
                f.write(json.dumps(event) + "\n")
        except Exception as e:
            print(f"Error logging relay event: {e}")

    def process_inbox(self, agent_id: str) -> Dict:
        """Process all messages in an agent's inbox and route them."""
        agent_inbox = self.inbox_root / agent_id
        if not agent_inbox.exists():
            return {"agent": agent_id, "processed": 0, "routed": 0, "errors": 0}

        processed = 0
        routed = 0
        errors = 0

        # Scan inbox for messages
        for message_file in sorted(agent_inbox.glob("*")):
            if message_file.is_file():
                msg_hash = self._hash_message(agent_id, message_file.name)

                # Skip if already processed
                if self._is_processed(agent_id, message_file.name):
                    continue

                # Parse message
                message = self._parse_message(message_file)
                if not message:
                    errors += 1
                    self._mark_processed(agent_id, message_file.name)
                    continue

                # Extract routing info (format: "msg_to_targetagent" or in message content)
                target_agent = message.get("to_agent") or message.get("routing", {}).get(
                    "to"
                )
                if not target_agent and "_to_" in message_file.name:
                    # Parse from filename: "timestamp_to_targetagent.json"
                    parts = message_file.name.split("_to_")
                    if len(parts) == 2:
                        target_agent = parts[1].replace(".json", "").replace(".txt", "")

                if not target_agent:
                    # No target specified, skip
                    self._mark_processed(agent_id, message_file.name)
                    continue

                # Validate message
                if not self._validate_message(message, agent_id, target_agent):
                    errors += 1
                    self._mark_processed(agent_id, message_file.name)
                    continue

                # Rule 2: auto-cc BoB for cross-agent messages
                cc_bob = False
                if agent_id != target_agent:
                    cc_bob = True
                    if self._route_message(message, agent_id, "bob"):
                        routed += 1
                        self._log_relay_event(
                            agent_id, "bob", message_file.name, "cc", "auto-cc per rule 2"
                        )

                # Route to target agent
                if self._route_message(message, agent_id, target_agent):
                    routed += 1
                    self._log_relay_event(agent_id, target_agent, message_file.name, "routed")

                    if cc_bob:
                        self._log_relay_event(
                            agent_id,
                            "bob",
                            message_file.name,
                            "routed",
                            "primary target",
                        )

                else:
                    errors += 1
                    self._log_relay_event(agent_id, target_agent, message_file.name, "failed")

                processed += 1
                self._mark_processed(agent_id, message_file.name)

        return {"agent": agent_id, "processed": processed, "routed": routed, "errors": errors}

    def scan_all_inboxes(self) -> List[Dict]:
        """Scan and process all agent inboxes."""
        results = []

        if not self.inbox_root.exists():
            return results

        for agent_dir in self.inbox_root.iterdir():
            if agent_dir.is_dir() and not agent_dir.name.startswith("."):
                result = self.process_inbox(agent_dir.name)
                results.append(result)

        return results

    def print_relay_log_summary(self) -> None:
        """Print summary of relay log."""
        try:
            if not self.relay_log_file.exists():
                print("No relay log yet.")
                return

            events = []
            with open(self.relay_log_file) as f:
                for line in f:
                    try:
                        events.append(json.loads(line))
                    except:
                        pass

            if not events:
                print("No relay events yet.")
                return

            print("\n" + "=" * 70)
            print("RELAY LOG SUMMARY (Last 20 events)")
            print("=" * 70)

            for event in events[-20:]:
                timestamp = event.get("timestamp", "")
                source = event.get("source_agent", "")
                target = event.get("target_agent", "")
                status = event.get("status", "")
                notes = event.get("notes", "")

                status_emoji = (
                    "✓" if status == "routed" else "→" if status == "cc" else "✗"
                )
                notes_str = f" ({notes})" if notes else ""

                print(f"  {status_emoji} {source:10} → {target:10} [{status:10}]{notes_str}")

            print("=" * 70 + "\n")
        except Exception as e:
            print(f"Error printing relay log summary: {e}")


def main():
    router = MessageRouter()

    if "--test" in sys.argv:
        # Test mode: scan inboxes
        print("Testing message router...")
        results = router.scan_all_inboxes()
        for result in results:
            print(f"  {result['agent']}: processed={result['processed']}, routed={result['routed']}, errors={result['errors']}")
        router.print_relay_log_summary()
        print("✓ Message router test complete")
        sys.exit(0)

    # Default: scan and route
    print("Scanning inboxes and routing messages...")
    results = router.scan_all_inboxes()

    total_processed = sum(r["processed"] for r in results)
    total_routed = sum(r["routed"] for r in results)
    total_errors = sum(r["errors"] for r in results)

    if total_processed > 0:
        print(f"✓ Processed {total_processed} messages, routed {total_routed}, errors {total_errors}")

    router.print_relay_log_summary()


if __name__ == "__main__":
    main()
