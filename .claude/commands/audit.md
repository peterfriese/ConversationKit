---
description: >-
  Run an architecture, code quality, and concurrency audit in a single pass
  without modifying files.
---
You are executing in **Multi-Agent Audit Mode** (`/audit`):

Scope to audit:
$ARGUMENTS

## Audit Guidelines:
1. **Read-Only Inspection**:
   - Do NOT edit or write code files during this audit.
2. **Review Checklist**:
   - **Architectural Alignment**: Do files follow the declared folder boundaries and responsibility matrix in `.fleet/fleet.yaml`?
   - **Concurrency Safety**: Are types crossing boundaries safely Sendable? Are locks or actors properly isolated?
   - **Performance & Memory**: Are there unnecessary allocations, leaks, or blocking operations in critical threads?
   - **Security**: Any hardcoded secrets, unsafe deserialization, or unvalidated inputs?
3. **Structured Verdict**:
   - Group findings by severity: Critical, Warning, Recommendation.
   - Include exact file paths and line numbers.
