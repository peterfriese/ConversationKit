---
id: apple-flowdeck-validation
name: Apple FlowDeck Validation & Automation
author: FlowDeck
platform: apple
path: flowdeck
tools:
  - flowdeck
default: true
description: FlowDeck CLI validation, simulator UI automation, and verification standards
---

# FlowDeck Validation & Automation Standards

- **Config-First**: Check `flowdeck config get --json` first. Use bare commands (`flowdeck build`, `flowdeck test`, `flowdeck run`) when a saved target exists.
- **Close the Loop**: A change that builds but breaks the UI is incomplete. Start a UI session (`flowdeck ui simulator session start`), read `latest_screenshot` and `latest-tree.json`, and visually verify the screen before signing off.
- **Always Verify After UI Actions**: After every `tap`, `type`, or `scroll`, wait ~1 second and re-read `latest.jpg` to confirm the screen changed.
- **macOS Automation in the Background**: Always pass `--background` on `flowdeck ui mac` commands. Never move the user's cursor or steal window focus.
- **No Apple Log CLIs**: Never use `xcrun simctl log` or `log show`. FlowDeck captures all `print()` and `OSLog` output via `flowdeck run --log` or `flowdeck logs <id>`.
- **Package Resolution Escalation**: If SPM packages fail to resolve, follow the escalation chain: `update` ➔ `resolve` ➔ `clear` ➔ `clean`.
