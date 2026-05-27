# Forge Omega Oracle — Soul-Brews Studio Study Runbook

This runbook turns the Soul-Brews Studio pattern into a visible Forge/Omega monitor using maw + tmux.

## What the run does

It runs three visible task panes plus one monitor pane:

1. Pattern mapping
   - `maw-js`, `maw-ui`, `maw-plugins`, `oracle-framework-advanced`
   - output: a concise mapping of the Soul-Brews stack to MarcuzX Forge

2. Monitor / tmux design
   - output: a practical Forge Omega monitor layout and how to view task panes

3. README / launcher spec
   - output: the exact command + prompt the user can reuse later

4. Monitor pane
   - tails progress files so the user can watch the work live

## One-command launch

From the `tham-oracle` folder, run:

```bash
bash scripts/forge-omega-oracle-study.sh
```

Optional fresh session name:

```bash
MAW_ORACLE_SESSION=forge-omega-oracle-study bash scripts/forge-omega-oracle-study.sh
```

## What you will see

- a tmux session with 4 panes
- each task pane titled and labeled
- a progress file under `reports/progress/`
- a session summary printed at the end

## The three task prompts

### Task 1 — Soul-Brews pattern mapping

Use the Soul-Brews Studio repositories to extract the reusable operating model.
Focus on:

- `maw-js` as the command/orchestration core
- `maw-ui` as the visual control plane
- `maw-plugins` as the extensibility layer
- `oracle-framework-advanced` as the doctrine / ψ/ / safety shell

Return:
- what each repo does
- which parts are directly transferable to MarcuzX Forge
- which parts should not be copied blindly

### Task 2 — Forge Omega monitor design

Design the tmux / maw monitor surface for Forge Omega.
Focus on:

- visible task panes for each agent
- a monitor pane that tails progress
- stable session naming
- clear pane labels
- readable proof output

Return:
- recommended pane layout
- recommended naming convention
- how to verify the panes are alive

### Task 3 — README / reuse package

Create the reusable README and command text so the user only needs to:

1. open Linux
2. `cd` into `tham-oracle`
3. run one command

Return:
- the final README text
- the exact launcher command
- the exact prompt block
- the attach command for tmux

## Suggested follow-up

After the run completes, review:

- `reports/progress/forge-omega-pattern-mapping.md`
- `reports/progress/forge-omega-monitor-design.md`
- `reports/progress/forge-omega-launcher-spec.md`

## Attach / inspect

```bash
tmux attach -t forge-omega-oracle
```
