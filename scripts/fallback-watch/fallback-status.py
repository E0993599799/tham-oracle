#!/usr/bin/env python3
"""
Tham Oracle — Fallback Status Reader
Used by dashboard API and Telegram bot to check if Codex fallback is active.
"""
import json, os, sys
from datetime import datetime

FALLBACK_STATE = "/tmp/tham-fallback-active.json"

def get_fallback_status() -> dict:
    if not os.path.exists(FALLBACK_STATE):
        return {"active": False, "reason": None, "tokens_remaining": None}
    try:
        with open(FALLBACK_STATE) as f:
            state = json.load(f)
        return state
    except Exception:
        return {"active": False, "reason": "read_error"}

def is_fallback_active() -> bool:
    return get_fallback_status().get("active", False)

if __name__ == "__main__":
    state = get_fallback_status()
    if state.get("active"):
        print(f"⚠️  FALLBACK ACTIVE — {state.get('reason','?')}")
        print(f"   Tokens remaining: {state.get('tokens_remaining','?')}")
        print(f"   Activated: {state.get('activated_at','?')}")
        print(f"   Provider: {state.get('fallback_provider','codex_gpt55_9router')}")
    else:
        print("✅ Fallback inactive — Claude active")
        if state.get("recovered_at"):
            print(f"   Recovered: {state.get('recovered_at')}")
