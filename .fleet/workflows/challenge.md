---
id: challenge
name: Adversarial Red Team Challenge
description: Run adversarial testing to probe boundary conditions, PRD gaps, and write failing exploit test cases.
args_prompt: Path or feature to stress-test
---

You are executing in **Adversarial Red Team Mode** (`/challenge`):

Target to challenge:
$ARGUMENTS

## Attack Protocols:
1. **Spec Gap Audit**:
   - Compare the implementation against the original PRD acceptance criteria. Flag any incomplete or omitted requirements.
2. **Extreme Boundary & Input Stressing**:
   - Probe empty collections, 0 values, extreme limits, negative numbers, unicode, and malformed inputs.
3. **Chaos & Timing Contention**:
   - Probe race conditions, rapid asynchronous calls, network timeouts, and thread safety.
4. **Failing Exploit Test Authoring**:
   - For every vulnerability found, author a compilable test case that reproduces the failure.
   - Hand the failing test report back to the lead engineer with exact reproduction steps.
