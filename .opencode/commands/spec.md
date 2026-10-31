---
description: >-
  Execute the full spec-driven pipeline (PRD -> Council of Critics -> User Gate
  -> Implementation -> Adversarial QA -> Review).
agent: chief-of-staff
---
You are executing in **Spec-Driven Pipeline Mode** (`/spec`):

Epic scope:
$ARGUMENTS

## Pipeline Sequence:
1. **Stage 1: Product Definition (PRD)**
   - Dispatch to `@product-manager` to draft a comprehensive PRD in `docs/specs/` using `PRD_TEMPLATE.md`.
2. **Stage 2: Architecture & Contracts (ADR)**
   - Dispatch to `@senior-architect` to design data models, API schemas, and ADR in `docs/architecture/` using `ADR_TEMPLATE.md`.
3. **Stage 3: Council of Critics Plan Review**
   - Review the plan across 4 lenses: Feasibility, Scope Guardian, Coherence, and Risk.
   - Consolidate feedback into Must-Fix and Should-Fix.
4. **Stage 4: 🛑 User Approval Gate**
   - **PAUSE** and present the specification and architectural contract to the user.
   - Await explicit user sign-off before writing implementation code.
5. **Stage 5: Parallel Implementation**
   - Dispatch implementation to the respective surface lead engineers.
6. **Stage 6: Adversarial & QA Verification**
   - Run verification test commands for all modified surfaces.
   - Dispatch `@adversarial-tester` to stress-test edge cases and verify Acceptance Criteria.
   - Have `@code-reviewer` audit the unified diffs.
7. **Stage 7: Trajectory & Learnings**
   - Have `@journal-agent` log the milestone in `docs/journal/`.
   - Have `@learnings-agent` document architectural takeaways in `docs/learnings/`.
