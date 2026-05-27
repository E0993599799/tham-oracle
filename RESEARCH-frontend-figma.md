# Research: Frontend Skills + Figma Integration
**Agent**: bob (Codex Lane)
**Task**: TASK-004
**Date**: 2026-05-21

## 1. Findings: Frontend Best Practices (Repo-Grounded)
Based on the dt-obs-frontends skill references in the repository, the "best practice" for frontend development in this ecosystem is heavily centered around **Observability and RUM (Real User Monitoring)**.

### Key Observability Patterns
- **Hybrid Monitoring**: Use metric-based queries (	imeseries) for trend analysis and alerting, and event-based queries (etch user.events) for deep diagnostics.
- **Dimensional Filtering**: Prioritize filtering by rontend.name, device.type, rowser.name, and geo.country.iso_code to isolate issues.
- **Error Analysis**: 
    - Monitor error rates as a percentage of total requests.
    - Track JavaScript exceptions and failing API requests separately.
    - Implement spike detection (e.g., >50% increase in error rate) to catch regression deployments.

### Phase 5 Implementation Strategy (Actionable)
For the Phase 5 frontend rollout, the following observability hooks should be integrated:
1. **RUM Integration**: Ensure every new component/page in Phase 5 is tagged with a consistent rontend.name.
2. **Error Boundary Mapping**: Map frontend error boundaries directly to the DQL patterns found in FrontendErrors.md to allow immediate triage from the UI.
3. **Performance Baselines**: Establish baseline dt.frontend.request.duration for new features before full release.

## 2. Figma Integration Options
*Note: Web access is restricted. Recommendations are based on industry standard patterns for Codex/AI-driven workflows and existing repo structure.*

### Recommended Integration Paths for Phase 5
Since this repo follows an "Agentic Orchestration" pattern (Tham -> Workers), the Figma integration should not be a manual export but a **data-driven pipeline**.

- **Option A: Figma REST API (Structured Data)**
    - **Workflow**: Use the Figma API to fetch JSON representations of frames/components.
    - **Agent Role**: A Gemini-based "Inspector" agent reads the JSON and suggests CSS/Tailwind mappings.
    - **Benefit**: High precision, supports design tokens.

- **Option B: Figma-to-Code Generative Pipeline**
    - **Workflow**: Export Figma screenshots/SVGs and use a vision-capable model (like Gemini) to generate initial React/Tailwind scaffolding.
    - **Agent Role**: Codex agents refine the generated code to match the dt-obs-frontends standards.
    - **Benefit**: Faster prototyping.

### Actionable Recommendation for Phase 5
Implement a **Token-Based Bridge**:
1. Define a design-tokens.json in the repo.
2. Use a script/agent to sync Figma Variables $\rightarrow$ design-tokens.json $\rightarrow$ Tailwind Config.
3. This ensures "Truth" remains in Figma while the "Implementation" remains governed by the orchestrator.

## 3. Assumptions & Risks
- **Assumption**: Phase 5 involves building new UI components based on new designs.
- **Risk**: Over-reliance on automated Figma-to-Code tools may lead to "div soup" that violates the observability standards (e.g., missing tracking IDs).
- **Mitigation**: Mandatory review of generated code against FrontendBasics.md patterns.

## 4. Next Actions
- [ ] Define the specific Figma project/files target for Phase 5.
- [ ] Create a prototype design-tokens.json structure.
- [ ] Verify if a Figma API Token can be safely stored in the project's secret management (per rra-safety-hooks).
