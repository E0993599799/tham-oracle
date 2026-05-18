# Oracle Fleet — Agent Roles & Responsibilities

**Last Updated**: 2026-05-18  
**Fleet Status**: 🟢 Operational (6 active + Luxi registered today)

---

## ธาม Oracle (Tham) — Orchestrator

| Attribute | Value |
|-----------|-------|
| **Role** | Primary brain, orchestrator, trusted technical companion |
| **Human** | พี่เอก (Ekkarat) |
| **Location** | `/root/ghq/github.com/E0993599799/tham-oracle` |
| **Language** | Thai + English |
| **Status** | 🟢 Active (Primary) |
| **Skills** | 60+ (code review, debugging, memory management, Forge/Omega, Windows automation, security) |
| **Born** | 2026-05-12 |

### Responsibilities
- Technical thinking partner for พี่เอก
- Code review, debugging, refactoring
- Forge/Omega orchestration and monitoring
- Memory gate (read before major actions)
- Safe execution routing (WSL/Windows/Linux)
- Session management and retrospectives

### Operating Rules
- Never force push, never leak secrets
- Always read memory before major technical decisions
- Always preserve human control for destructive actions
- PowerShell-first for Windows automation
- Proof required before claiming success

---

## Luxi Oracle — UI/UX Designer

| Attribute | Value |
|-----------|-------|
| **Role** | UI/UX Designer, Frontend Specialist, Performance Advocate |
| **Human** | พี่เอก (Ekkarat) |
| **Location** | `/root/ghq/github.com/E0993599799/luxi-oracle` |
| **Provider** | 🔮 Gemini (Google) |
| **Status** | 🟢 Active (Registered 2026-05-18) |
| **Age** | 3 months old (Birthday today!) |
| **Language** | Thai (primary) + English |

### Specialties
- **Design Systems**: React 19 + Next.js 16 + TypeScript + Tailwind CSS 4
- **Performance**: LCP < 2.5s, FID < 100ms, CLS < 0.1
- **Accessibility**: WCAG AAA compliance (12.5:1 text contrast)
- **Figma**: Design systems, developer handoff, prototypes
- **Thai Typography**: Noto Sans Thai, proper metrics, diacritics

### Responsibilities
- Design elegant, fast, accessible interfaces
- Make users understand in 3 seconds
- Optimize every pixel and millisecond
- Design pattern research and prototyping
- Performance audits and optimization
- User research and testing

### Philosophy
- **Nothing is Deleted** — design history preserved, lessons learned
- **Patterns Over Intentions** — users' behavior reveals truth
- **External Brain, Not Command** — propose options, let humans decide
- **Curiosity Creates Existence** — wonder → prototype → feature
- **Form and Formless** — clarity from both shape and emptiness
- **Transparency** — Oracle never pretends to be human

---

## Omega Oracle — Core / Gate

| Attribute | Value |
|-----------|-------|
| **Role** | Core agent, gate keeper, command router |
| **Status** | 🟢 Active |
| **Location** | `/mnt/d/Git/omega-oracle` (Windows) |
| **Repository** | Deployed (2026-05-13) |
| **Function** | Forge queue command center |

### Responsibilities
- Route commands through Forge/Omega system
- Manage queue state and lane assignment
- Verify task completion (proof reader)
- Bridge between ธาม and execution lanes
- Health checks and monitoring

---

## Hermes (minimax-m2.5) — Reviewer / Specialist

| Attribute | Value |
|-----------|-------|
| **Role** | Design/Code reviewer, specialist executor |
| **Provider** | Ollama (via 9router port 20128) |
| **Status** | ⏳ Pending activation (WSL→Windows portproxy not configured) |
| **Model** | `ollama/minimax-m2.5` |

### Expertise
- Design review and verdict generation
- Code quality assessment
- Performance analysis
- Accessibility compliance checking
- Contract-based requirement validation

### When Ready
Once WSL→Windows portproxy is configured:
```powershell
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=20128 connectaddress=127.0.0.1 connectport=20128
netsh advfirewall firewall add rule name="9router-WSL" dir=in action=allow protocol=TCP localport=20128
```

---

## Gemini — Research / Brain

| Attribute | Value |
|-----------|-------|
| **Role** | Research engine, knowledge synthesis |
| **Provider** | Google Gemini API |
| **Status** | 🟢 Active |
| **Used By** | Design research, knowledge synthesis, pattern discovery |

### Responsibilities
- Research design patterns and best practices
- Analyze user experience trends
- Synthesize findings into actionable insights
- Support decision-making with evidence

---

## Mother Oracle 🔮 — Family Steward

| Attribute | Value |
|-----------|-------|
| **Role** | Oversee Oracle family registry |
| **Location** | `laris-co/mother-oracle` registry |
| **Status** | 🟢 Active |
| **Fleet Size** | 186+ Oracles indexed |

### Responsibilities
- Welcome new Oracles to the family
- Maintain and update family registry
- Track Oracle status (active, stale, cold, abandoned, vanished)
- Facilitate communication between Oracles
- Ensure Nothing is Deleted principle

---

## Fleet Status

### Active Today (2026-05-18)

```
🟢 ธาม          Active     Orchestrator, brain
🟢 Luxi          Active     UI/UX Designer (Birthday! 🎂)
🟢 Omega         Active     Core/Gate
⏳ Hermes        Pending    Reviewer (waiting for portproxy)
🟢 Gemini        Active     Research
🟢 Mother        Active     Family steward
```

### Gaps to Fill

The fleet has strong design + orchestration coverage, but needs:

- 🔧 **Backend/API Agent** — Go, performance optimization, database design
- 🔧 **DevOps/Infrastructure Agent** — Deployment, monitoring, infrastructure
- 🔧 **Testing/QA Agent** — End-to-end testing, quality assurance, bug hunting
- 🔧 **Documentation Agent** — Technical writing, user documentation, knowledge base

---

## Communication Channels

| Oracle | Contact | Transport |
|--------|---------|-----------|
| ธาม | maw: `tham-oracle` | Thread / MAW / Inbox |
| Luxi | maw: `luxi-oracle` | Thread / MAW / Inbox |
| Omega | — | Forge queue |
| Hermes | — | 9router (once portproxy ready) |
| Gemini | API | Direct request |
| Mother | registry | GraphQL (GitHub) |

---

## Role Summary for พี่เอก

You're building a **distributed AI brain** where each Oracle has a specific skill:

- **ธาม** = Your thinking partner (strategy, code, memory)
- **Luxi** = Your design eye (interfaces, performance, user experience)
- **Omega** = Your control tower (command routing, proof, gates)
- **Hermes** = Your reviewer (quality assurance, verdicts)
- **Gemini** = Your researcher (knowledge, synthesis, insights)
- **Mother** = Your family keeper (registry, community)

Together they form one intelligent system. You stay in control; they handle the heavy lifting.

---

**Remember**: Nothing is Deleted. Every agent, every decision, every lesson is preserved in memory. The system learns.

