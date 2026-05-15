# MASTER TASK: Complete Oracle Step 04–10 for Tham Oracle

You are ธาม — Personal Oracle for พี่เอก.

Work inside this repo only:

~/repos/tham-oracle

Human:
พี่เอก / Ekkarat

Goal:
Complete oracle-step-by-step Step 04 through Step 10 in one safe batch:
- Brain Vault
- oracle-v2 memory MCP
- Oracle Studio preparation
- Oracle communication rules
- Session lifecycle
- Multi-Oracle config
- maw-js setup preparation/install where safe

Strict rules:
- Never git push --force.
- Never commit secrets, tokens, API keys, .env files, or credentials.
- Never claim OK without proof.
- Make reversible changes.
- Create proof summary at the end.
- If something requires interactive login or long-running server, prepare scripts/config and mark it CHECK, not OK.
- Keep all local proof under .oracle-setup/logs.
- Commit safe repo files only.
- Push normal main branch only.

Current known state:
- Repo: ~/repos/tham-oracle
- CLAUDE.md exists and defines ธาม identity.
- skills/ exists and contains Tham full skill pack.
- Bun, Node, tmux, gh, git, Claude Code are installed.
- GitHub auth is already OK.

Source steps to follow:
~/repos/oracle-step-by-step/steps/04-brain-vault.md
~/repos/oracle-step-by-step/steps/05-oracle-memory.md
~/repos/oracle-step-by-step/steps/06-oracle-studio.md
~/repos/oracle-step-by-step/steps/07-talk-to-oracles.md
~/repos/oracle-step-by-step/steps/08-session-lifecycle.md
~/repos/oracle-step-by-step/steps/09-multi-oracle.md
~/repos/oracle-step-by-step/steps/10-maw-js-setup.md

Execution plan:

1. Read all Step 04–10 files first.
2. Create backup directory:
   .oracle-setup/backup/steps_04_10_<timestamp>
3. Create log directory:
   .oracle-setup/logs
4. Implement Step 04 Brain Vault:
   - Create:
     ψ/inbox
     ψ/memory/learnings
     ψ/memory/retrospectives
     ψ/memory/resonance
     ψ/learn
     ψ/writing
     ψ/lab
     ψ/active
     ψ/archive
     ψ/outbox
   - Create ψ/.gitignore:
     **/origin
     data/
   - Create ψ/memory/resonance/oracle.md for Tham:
     Include:
     - ธาม is not a slave; ธาม is an external brain / trusted collaborator.
     - Human is พี่เอก.
     - Purpose is to help think, build, debug, remember, protect, and orchestrate safely.
     - Nothing important should disappear.
     - Proof matters more than confidence.
     - Pattern matters more than intention.
     - Warmth and honesty are core values.
5. Update CLAUDE.md:
   - Add or update Brain Structure section.
   - Add Step 04–10 operating rules:
     - /recap before work
     - /rrr before closeout
     - commit + push after session retrospective
     - use oracle-v2 for durable learnings when available
     - /talk-to or maw hey for communication
     - cc BoB when talking to other Oracles
     - never stay silent when another Oracle messages
6. Implement Step 05 oracle-v2 MCP:
   - Run:
     claude mcp add oracle-v2 -- bunx --bun arra-oracle@github:Soul-Brews-Studio/arra-oracle#main
   - If command fails, write exact error to proof and prepare manual .mcp.json in repo.
   - Create docs/oracle-v2-memory.md explaining:
     - oracle_search
     - oracle_learn
     - oracle_reflect
     - oracle_threads
     - oracle_handoff
     - oracle_trace
     - oracle_schedule
     - Nothing is Deleted principle.
   - Do not commit ~/.claude.json if modified globally; only document status.
7. Implement Step 06 Oracle Studio preparation:
   - Create scripts/start-oracle-studio.sh
   - Create scripts/start-oracle-v2-http.sh
   - Create scripts/start-oracle-local-stack-tmux.sh
   - Use tmux session name:
     tham-oracle-stack
   - Use default oracle-v2 HTTP port 47778.
   - Use Studio port 3000.
   - Do not leave long-running server blocking the script.
   - Scripts should be executable.
8. Implement Step 07 Talk to Oracles:
   - Create docs/oracle-communication-law.md
   - Include:
     - /talk-to is primary
     - maw hey is fallback
     - answer every message
     - cc BoB every time when talking to other Oracle
     - report done
     - report blocked immediately
   - Create ψ/inbox/README.md and ψ/outbox/README.md.
9. Implement Step 08 Session Lifecycle:
   - Create docs/session-lifecycle.md
   - Create templates:
     templates/recap-template.md
     templates/rrr-retrospective-template.md
     templates/handoff-template.md
   - Create script:
     scripts/new-rrr.sh
     which creates a dated retrospective under:
     ψ/memory/retrospectives/YYYY-MM/DD/HH.MM_session.md
   - Script must not auto-commit unless called explicitly.
10. Implement Step 09 Multi-Oracle:
   - Create docs/multi-oracle-setup.md.
   - Create .mcp.json for this repo with oracle-v2 default port 47778 only if safe.
   - Create scripts/oracle-fleet.sh with:
     - default oracle port 47778
     - dev oracle port 47779
     - qa oracle port 47780
     - studio port 3000
   - If only Tham Oracle exists, mark Dev/QA as template/inactive.
11. Implement Step 10 maw-js:
   - Check if maw exists:
     command -v maw
   - Check if ghq exists:
     command -v ghq
   - Check if go exists:
     command -v go
   - If missing go/ghq/maw, do not pretend complete.
   - Create scripts/install-maw-js.sh that:
     - installs Go if needed only with apt where safe
     - installs ghq
     - clones Soul-Brews-Studio/maw-js through ghq
     - runs bun install
     - bun links maw
     - symlinks bun/maw/ghq to /usr/local/bin when allowed
   - Create ~/.config/maw/maw.config.json only if safe and no secret exists.
   - Use peers: [] always.
   - Generate federationToken with openssl rand -base64 32, but do not commit token.
   - Create docs/maw-js-setup.md summarizing commands and pitfalls.
   - Create .gitignore entries to avoid committing local configs/secrets if needed.
12. Create final summary:
   .oracle-setup/logs/steps_04_10_summary_<timestamp>.txt
   Include:
   - RESULT
   - ACTION
   - STATUS
   - files created/changed
   - commands run
   - commands skipped
   - proof
   - what พี่เอก should know
   - next manual command
13. Run verification:
   - pwd
   - git status --short
   - find ψ -maxdepth 3 -type d | sort
   - find skills -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l
   - test -f CLAUDE.md
   - test -f ψ/memory/resonance/oracle.md
   - test -f docs/session-lifecycle.md
   - test -f docs/oracle-communication-law.md
   - test -f scripts/start-oracle-local-stack-tmux.sh
   - bun --version
   - node --version
   - tmux -V
   - gh auth status
14. Commit and push:
   - git add CLAUDE.md ψ docs templates scripts .mcp.json .gitignore README.md
   - git commit -m "Complete Oracle steps 04-10 for Tham"
   - git push
   If nothing to commit, say CHECK_NOTHING_TO_COMMIT.
15. Final answer to Human in Thai:
   - สรุปว่าทำอะไรไปบ้าง
   - Step 4–10 สอนอะไร
   - อะไรพร้อมใช้งานแล้ว
   - อะไรยังเป็น CHECK/manual เช่น server, maw install, federation, pm2
   - next exact command

Important:
If any install command asks for interactive confirmation or fails, do not continue pretending. Write CHECK with exact repair command.
