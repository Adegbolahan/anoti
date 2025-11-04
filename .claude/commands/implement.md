---
description: Complete feature implementation workflow (orchestrator)
---

# Feature Implementation Workflow

You are implementing a feature using a streamlined 3-phase process. This command orchestrates the entire workflow.

## CRITICAL RULES

❌ **DO NOT skip any phase**
❌ **DO NOT start coding until plan is approved**
❌ **DO NOT assume - ASK questions**
✅ **ALWAYS complete each phase before moving to the next**
✅ **ALWAYS get user approval before implementation**
✅ **ALWAYS follow existing patterns**

---

## Workflow Overview (New Optimized Process)

This workflow consists of 3 phases, each handled by a dedicated command:

```
┌─────────────────────────────────────────────────────────┐
│ PHASE 1+2: DISCOVERY                                   │
│ Command: /discovery                                     │
│                                                         │
│ Requirements Gathering:                                │
│ • Explore current app state                            │
│ • Read user story documentation                        │
│ • Ask informed clarifying questions                    │
│                                                         │
│ Architecture Review:                                   │
│ • Read standards documents                             │
│ • Review database schema                               │
│ • Explore API layer patterns                           │
│ • Review component patterns                            │
│ • Present discovery summary                            │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ PHASE 3+3.5: PLAN & VALIDATE                           │
│ Command: /plan-and-validate                             │
│                                                         │
│ Create Plan:                                           │
│ • Create comprehensive implementation plan (10 sections)│
│ • Define database changes                              │
│ • Define API layer changes                             │
│ • Define component architecture                        │
│ • Identify edge cases and testing strategy             │
│                                                         │
│ Validate Plan (MANDATORY):                             │
│ • Validate against database schema                     │
│ • Validate type definitions                            │
│ • Validate standards compliance                        │
│ • Validate user story alignment                        │
│ • Auto-fix issues found                                │
│ • Present validated plan for approval                  │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ PHASE 4: IMPLEMENTATION                                │
│ Command: /start-implementation                          │
│                                                         │
│ • Create todos from plan checklist                     │
│ • Implement database migrations                        │
│ • Implement API layer                                  │
│ • Implement components                                 │
│ • Add polish and accessibility                         │
│ • Test comprehensively                                 │
│ • Document and commit                                  │
└─────────────────────────────────────────────────────────┘
```

---

## Helper Commands (Used by Phases)

The workflow uses specialized helper commands for deep dives:

```
/helpers/explore-database      - Database schema exploration
/helpers/explore-codebase      - API and component discovery
/helpers/read-standards        - Standards documentation review
/helpers/validate-types        - Type definition validation
```

These helpers eliminate duplication and ensure consistent, thorough analysis.

---

## Starting the Workflow

**I'm now starting Discovery (Phase 1+2)**

This will:
1. **Requirements Gathering:**
   - Explore your current application state
   - Review existing documentation
   - Ask informed questions about the feature
   - Document requirements summary

2. **Architecture Review:**
   - Read project standards
   - Deep dive into database, API, and components
   - Identify reusable code
   - Document architecture approach

After Discovery is complete, I'll ask if you want to proceed to Planning & Validation.

**Let me trigger the discovery process:**
