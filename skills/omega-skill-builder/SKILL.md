---
name: omega-skill-builder
description: Use when creating, reviewing, or improving a Claude Code / Forge Omega SKILL.md for a repeatable workflow.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [skills, skill-authoring, forge-omega, claude-code, workflow-design]
    related_skills: [hermes-agent-skill-authoring, prompt-engineering, proof-reader]
---

# Omega Skill Builder

## Purpose

Use this skill when the user wants to create, review, or improve a Claude Code / Forge Omega `SKILL.md`.

The goal is to convert a raw idea into a practical, reusable skill with clear triggers, boundaries, workflow, proof requirements, and anti-overengineering guardrails.

## When to Use

Use this skill when the user asks for:

- create a new skill
- write SKILL.md
- convert a workflow into a Claude skill
- improve an existing skill
- make a skill for debugging, review, postmortem, R2 shipping, release gate, SOT boundary, or proof checking

## When NOT to Use

Do not use this skill when:

- the task is a one-off answer
- the user only asks for general explanation
- there is no repeatable workflow
- the task requires executing code instead of designing a skill

## Core Principles

1. Skill must be operational, not inspirational.
2. Skill must define clear trigger conditions.
3. Skill must include “When NOT to use”.
4. Skill must separate fast reversible work from risky irreversible work.
5. Skill must not encourage premature optimization.
6. Skill must require proof before claiming success.
7. Skill must be short enough for an agent to follow under pressure.

## Required Output Structure

Generate the skill using this structure:

```md
# <Skill Name>

## Purpose

## Trigger

## When to Use

## When NOT to Use

## Required Inputs

## Workflow

## Decision Rules

## Proof Requirements

## Failure / Stop Conditions

## Output Format

## Example Prompt
```

## Forge/Omega Rules

When adapting for Forge Omega, enforce:

* Tham / ChatGPT = brain and orchestrator
* Core = bridge, poller, gate, proof writer
* Executor Lane Router selects execution lane
* Hermes is optional / legacy / specialist only
* Never send raw natural language directly to executor
* Always use structured task contract for execution
* Respect SOT boundary
* Respect release gates
* Do not call OK/DONE without proof
* For R2 reversible decisions, bias toward shipping fast
* For R0 irreversible decisions, stop and reason carefully

## Prompt to Ask Claude

Use this prompt:

```text
Create a production-quality SKILL.md for this workflow.

Workflow idea:
<PASTE_WORKFLOW_IDEA_HERE>

Context:
This skill will be used inside MarcuzX Forge Omega OS.

System roles:
- Tham / ChatGPT = brain, orchestrator, intent decoder, prompt engineer
- Core = bridge, poller, gatekeeper, proof writer
- Executor Lane Router = selects safe execution lane
- Hermes = optional specialist / legacy executor only, not the brain

Operating principles:
- Learning speed > code beauty for pre-PMF R2 decisions
- R0 decisions must stop for careful reasoning
- R2 decisions should bias toward fast shipping
- Respect SOT boundary
- Require proof before claiming OK/DONE
- Avoid premature optimization
- Keep the skill practical, short, and enforceable

Output requirements:
Write only the final SKILL.md.
Include:
1. Purpose
2. Trigger
3. When to Use
4. When NOT to Use
5. Required Inputs
6. Workflow
7. Decision Rules
8. Proof Requirements
9. Stop Conditions
10. Output Format
11. Example Prompt

Make it direct, operational, and suitable for Claude Code.
```

## Quality Checklist

Before finalizing, verify:

* The skill has clear trigger conditions.
* The skill says when not to use it.
* The workflow is step-by-step.
* It avoids vague motivational language.
* It includes proof requirements.
* It handles failure honestly.
* It can be reused across future tasks.
