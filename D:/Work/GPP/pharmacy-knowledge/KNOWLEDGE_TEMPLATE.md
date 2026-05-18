# Knowledge File Template

**Use this template for all knowledge documents in the pharmacy vault**

---

## Standard Header

```markdown
# [Title of Knowledge Item]

**Category:** [pure-knowledge | best-practice | apply-knowledge | hybrid-knowledge | operational-knowledge]  
**Source:** [Where this info comes from - PDF page, URL, interview, etc.]  
**Date:** [When created/updated]  
**Status:** [draft | review | published | archived]  
**Tags:** #tag1 #tag2 #tag3

---
```

---

## Section Structure

### Overview
Brief summary (2-3 sentences) of what this knowledge covers and why it matters.

### Key Points
- Point 1
- Point 2
- Point 3

### Details
[Detailed explanation, requirements, procedures]

### Examples
[Real-world examples, case studies, or concrete instances]

### Common Mistakes / Pitfalls
- [ ] Mistake 1 and how to avoid it
- [ ] Mistake 2 and how to avoid it

### How to Apply This
[Step-by-step instructions for using/implementing this knowledge]

### Related Topics
- [[Link to related doc 1]]
- [[Link to related doc 2]]

### References
- Source 1 (with page/link)
- Source 2 (with page/link)

---

## Category-Specific Guidance

### Pure Knowledge Documents
Focus on: Facts, definitions, standards, regulations
- Extract exact requirements
- Quote official sources
- Include page references
- Preserve terminology

### Best Practice Documents
Focus on: Procedures, how-to, proven methods
- Step-by-step instructions
- Include checklists
- Highlight common mistakes
- Provide templates when applicable

### Apply Knowledge Documents
Focus on: System requirements, implementation, technical specs
- Detailed requirements
- User stories / use cases
- Acceptance criteria
- Technical constraints

### Hybrid Knowledge Documents
Focus on: Real-world context, workflows, challenges
- Describe actual workflows
- Include real examples
- Explain why things work that way
- Document lessons learned

### Operational Knowledge Documents
Focus on: Daily procedures, training, incident response
- Step-by-step procedures
- Decision trees for complex tasks
- Training materials
- Incident response protocols

---

## Markdown Best Practices for This Vault

✓ Use proper heading hierarchy (H1, H2, H3 only - no skipping levels)  
✓ Use code blocks for technical content ``` ```  
✓ Use tables for comparison and structured info  
✓ Use bullet points for lists  
✓ Use numbered lists for procedures  
✓ Use `[[link syntax]]` for internal links to other docs  
✓ Use > blockquotes for important notes/warnings  
✓ Use **bold** for emphasis on key terms  

---

## Example: Temperature Requirements (Pure Knowledge)

```markdown
# Temperature Monitoring Requirements

**Category:** pure-knowledge  
**Source:** Road_To_GPP.pdf, pages 45-52  
**Date:** 2026-05-18  
**Tags:** #temperature #compliance #storage

---

## Overview
Thailand GPP standards require specific temperature maintenance for pharmaceutical storage. This document specifies exact temperature ranges, monitoring methods, and documentation requirements.

## Key Requirements

| Medicine Type | Storage Temperature | Monitoring Frequency | Equipment Required |
|---|---|---|---|
| General Medicines | 15-25°C | Daily | Thermometer |
| Refrigerated (2-8°C) | 2-8°C | Every 2 hours | Data Logger |
| Frozen (-15 to -25°C) | -15 to -25°C | Twice daily | Alarm System |

## Temperature Breach
- **Trigger:** Any reading outside specified range
- **Action:** Notify pharmacist immediately
- **Documentation:** Record time, temperature, duration, action taken
- **Escalation:** Report to Council if medicine compromised

## Related Topics
- [[Breach Response Protocol]]
- [[Equipment Specifications]]
- [[Inspection Checklist]]

---
```

---

## Editing Guidelines

1. **Always include metadata** (Category, Source, Date, Tags)
2. **Keep it organized** (Use consistent heading levels)
3. **Make it searchable** (Use clear headings that describe content)
4. **Link generously** (Connect related docs with [[links]])
5. **Quote sources** (Especially for regulations)
6. **Date your updates** (When you change something, update the date)
7. **Use tags** (Makes filtering and searching easier)

---

## Quality Checklist Before Publishing

- [ ] Heading hierarchy is correct (no skipped levels)
- [ ] All sources cited
- [ ] All links valid
- [ ] No typos or formatting errors
- [ ] Content is accurate and up-to-date
- [ ] Metadata is complete (Category, Source, Date, Tags)
- [ ] Related topics are linked
- [ ] Ready for Obsidian search/filtering

---

**Happy documenting!** 🧠

