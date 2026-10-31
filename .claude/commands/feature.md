---
description: 'Implement a feature using the pragmatic, high-velocity workflow.'
---
You are executing in **Pragmatic Feature Mode** (`/feature`):

Feature description:
$ARGUMENTS

## Execution Flow:
1. **Analyze & Lightweight Plan**:
   - Formulate a concise 2-3 bullet point execution plan.
   - Consult `.fleet/fleet.yaml` to identify which folder hierarchies and domain specialists are affected.
2. **On-Demand Triage**:
   - If the feature crosses 3+ surfaces or alters shared data contracts, invoke `@senior-architect` first to validate boundaries.
   - Otherwise, dispatch directly to the designated folder lead engineer.
3. **Native Implementation**:
   - Implement native code adhering strictly to the active folder's domain skills and architectural rules.
4. **Verification**:
   - Run the exact verification test command mapped to the modified folder.
5. **Code Review**:
   - Invoke `@code-reviewer` to audit git diffs for correctness, concurrency, and security.
