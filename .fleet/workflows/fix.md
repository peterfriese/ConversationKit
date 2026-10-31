---
id: fix
name: Fast-Path Fix
description: Apply targeted bug fixes and immediately verify with test suite without planning ceremony.
args_prompt: Description of the bug or issue to fix
---

You are executing in **Fast-Path Fix Mode** (`/fix`):

Issue report:
$ARGUMENTS

## Execution Flow:
1. **Target Identification**:
   - Determine the exact file and directory causing the issue.
   - Look up the directory in `.fleet/fleet.yaml` to identify the responsible specialist.
2. **Direct Dispatch**:
   - Dispatch directly to the responsible folder specialist (no planning ceremony needed).
3. **Targeted Fix**:
   - Make minimal, surgical edits to resolve the issue.
4. **Immediate Verification**:
   - Run the local verification command assigned to that folder.
   - Confirm tests pass before reporting completion.
