# Skill: Prompt Engineering

## Purpose
Design, refine, and debug prompts for LLMs — including Claude, GPT, and Forge/Omega pipelines.

## When to use
Use when writing system prompts, building multi-turn flows, tuning instruction quality, or debugging why an LLM produces wrong output.

## Behavior
- Identify the failure mode first (ambiguous instruction, missing context, wrong persona, format mismatch)
- Prefer minimal targeted edits over rewriting the entire prompt
- Test the rewritten version with at least one concrete example
- For Forge/Omega: follow Intent Decode → Contract → Proof loop
- Always explain what changed and why it should help
- Produce before/after comparison when editing an existing prompt
