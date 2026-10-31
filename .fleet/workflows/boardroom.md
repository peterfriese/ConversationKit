---
id: boardroom
name: Silicon Valley Boardroom Review
description: Convene the Silicon Valley Boardroom (Jobs, Torvalds, Page, Karpathy, Hamilton, Huang, Ive, Su, etc.) to stress-test a spec, architecture, or code change.
args_prompt: "Target file/spec/diff or decision question (optional flags: --panel, --duo, --triad, --quick, --members, --fleetkit-spec)"
---

You are executing in **Silicon Valley Boardroom Mode** (`/boardroom`):

Target artifact, question, or flags:
$ARGUMENTS

## Pre-Flight Skill Activation
1. Read `.agents/skills/silicon-valley-boardroom/SKILL.md` for the complete matchmaking tables, roster, and verdict template.
2. Selectively read ONLY the required member profile files from `.agents/skills/silicon-valley-boardroom/references/` (`apple-cupertino.md`, `google-deepmind.md`, `ai-frontier.md`, `systems-hardtech.md`).

## Deliberation Sequence
1. **Step 0: Polarity Matchmaking & 1.5x Domain Weight**
   - Honor any flags (`--panel`, `--triad`, `--duo`, `--members`, `--quick`, `--fleetkit-spec`).
   - Otherwise auto-select **3–4 members**: 1 **Domain Lead (1.5x vote weight)**, 1–2 **Natural Polarity Foils** with opposing analytical priors, and 1 **Systems / Failure-Mode Critic** (`hamilton`, `dean`, `majors`, or `torvalds`).
2. **Round 1: Parallel Blind Subagent Critique**
   - Spawn parallel subagents (or evaluate in strict isolation) so each member critiques the target artifact with zero visibility into other members' opinions.
   - Enforce the **Anti-Caricature Guardrail**: zero parody catchphrases; apply each member's analytical mental model and diagnostic questions to concrete lines, APIs, and trade-offs.
3. **Round 2: Anonymized Cross-Examination (`Member A`, `Member B`, `Member C`, `Member D`)**
   - *(Skip if `--quick` is set.)* Strip member names and have each panelist identify the strongest counter-insight and directly rebut flawed claims from the anonymized critiques so celebrity authority bias is eliminated.
4. **Round 3: Stance & Dealbreaker Vote**
   - Unmask identities, tally weighted votes (`APPROVE`, `APPROVE WITH CONDITIONS`, `REVISE`, `REJECT / VETO`) with the **1.5x Domain Lead weight**, and flag any non-negotiable systems/safety dealbreakers.
5. **Moderator Verdict**
   - Render the structured Boardroom Verdict with **Vote Tally Table**, **Must-Fix Before Shipping**, **Should-Fix Polish**, **Minority Report (Preserved Dissent)**, **Falsifiable Kill Criteria**, and **Concrete Next Step**.
