#!/usr/bin/env node

/**
 * Antigravity Fleet Gatekeeper Hook
 * Deterministic mechanical gatekeeping for FleetKit workspaces.
 */

import fs from 'node:fs';
import path from 'node:path';

function findWorkspaceRoot(payload) {
  const customPath = payload?.workspacePaths?.[0] || payload?.workspace_paths?.[0];
  if (customPath) {
    return path.resolve(customPath);
  }
  if (process.env.WORKSPACE_ROOT) {
    return path.resolve(process.env.WORKSPACE_ROOT);
  }
  let cur = process.cwd();
  while (cur !== path.dirname(cur)) {
    if (fs.existsSync(path.join(cur, ".fleet"))) {
      return cur;
    }
    cur = path.dirname(cur);
  }
  if (fs.existsSync(path.join(cur, ".fleet"))) {
    return cur;
  }
  return process.cwd();
}

function isRootOrchestrator(payload) {
  const transcriptPath = payload?.transcriptPath || payload?.transcript_path;
  if (transcriptPath && fs.existsSync(transcriptPath)) {
    try {
      const content = fs.readFileSync(transcriptPath, "utf-8");
      const lines = content.split("\n");
      for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed) {
          continue;
        }
        try {
          const parsed = JSON.parse(trimmed);
          if (parsed?.type === "USER_INPUT" || parsed?.source === "USER_EXPLICIT") {
            return true;
          }
        } catch {
          if (/^\{[^}]*"(?:type|source)"\s*:\s*"(?:USER_INPUT|USER_EXPLICIT)"/.test(trimmed)) {
            return true;
          }
        }
      }
      return false;
    } catch {
      return true;
    }
  }
  if (payload?.subagentId || payload?.isSubagent || payload?.agentMode === "subagent") {
    return false;
  }
  return true;
}

function parseFleetYaml(workspaceRoot) {
  const fleetYamlPath = path.join(workspaceRoot, ".fleet", "fleet.yaml");
  if (!fs.existsSync(fleetYamlPath)) {
    return null;
  }
  try {
    const raw = fs.readFileSync(fleetYamlPath, "utf-8");
    const state = JSON.parse('{"hierarchy":[],"currentRule":null,"activeList":null}');
    const { hierarchy } = state;
    const lines = raw.split("\n");
    let inDefault = false;
    let inHierarchy = false;
    let defaultLead = "";
    let { currentRule, activeList } = state;
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (line.match(/^default:\s*$/)) {
        if (currentRule) {
          hierarchy.push(currentRule);
        }
        currentRule = null;
        activeList = null;
        inDefault = true;
        inHierarchy = false;
        continue;
      }
      if (line.match(/^hierarchy:\s*$/)) {
        inDefault = false;
        inHierarchy = true;
        continue;
      }
      if (inDefault && line.match(/^[a-z_]+:/i)) {
        inDefault = false;
      }
      if (inDefault) {
        const defaultLeadMatch = line.match(/^\s+lead:\s*['"]?([^'"]+)['"]?/);
        if (defaultLeadMatch) {
          defaultLead = defaultLeadMatch[1].trim();
        }
        continue;
      }
      if (inHierarchy && line.match(/^[a-z_]+:/i)) {
        if (currentRule) {
          hierarchy.push(currentRule);
        }
        currentRule = null;
        inHierarchy = false;
        activeList = null;
        continue;
      }
      if (inHierarchy) {
        const itemMatch = line.match(/^(\s*)-\s+path:\s*['"]?([^'"]+)['"]?/);
        if (itemMatch) {
          if (currentRule) {
            hierarchy.push(currentRule);
          }
          currentRule = { path: itemMatch[2], skills: [], verification: {} };
          activeList = null;
          continue;
        }
        if (currentRule) {
          const leadMatch = line.match(/lead:\s*['"]?([^'"]+)['"]?/);
          if (leadMatch) {
            currentRule.lead = leadMatch[1];
          }
          const testMatch = line.match(/test:\s*['"]?([^'"]+)['"]?/);
          if (testMatch) {
            currentRule.verification = currentRule.verification || {};
            currentRule.verification.test = testMatch[1];
          }
          const inlineSkillsMatch = line.match(/skills:\s*\[(.*?)\]/);
          if (inlineSkillsMatch) {
            const rawItems = inlineSkillsMatch[1].split(",");
            for (const item of rawItems) {
              const cleaned = item.trim().replace(/^['"]|['"]$/g, "");
              if (cleaned) {
                currentRule.skills.push(cleaned);
              }
            }
            activeList = null;
            continue;
          }
          if (line.match(/^\s+skills:\s*$/)) {
            activeList = "skills";
            continue;
          }
          if (line.match(/^\s+[a-zA-Z0-9_-]+:/)) {
            activeList = null;
            continue;
          }
          const skillItemMatch = line.match(/^\s*-\s+['"]?([^'"]+)['"]?/);
          if (skillItemMatch && activeList === "skills") {
            currentRule.skills.push(skillItemMatch[1]);
          }
        }
      }
    }
    if (currentRule) {
      hierarchy.push(currentRule);
    }
    return defaultLead ? { hierarchy, defaultLead } : { hierarchy };
  } catch {
    return null;
  }
}

function handlePreToolUse(payload, workspaceRoot = findWorkspaceRoot(payload)) {
  const toolCall = payload?.toolCall || payload?.tool || {};
  const toolName = toolCall.name || "";
  const args = toolCall.args || payload?.args || {};
  if (["write_file", "edit_file", "write_to_file", "replace_file_content", "multi_replace_file_content"].includes(toolName)) {
    const isRoot = isRootOrchestrator(payload);
    if (!isRoot) {
      return { decision: "allow" };
    }
    const targetFile = args.Path || args.TargetFile || args.target_file || args.targetFile || args.path || args.file_path || args.filePath || "";
    if (!targetFile || typeof targetFile !== "string") {
      return { decision: "allow" };
    }
    const absTarget = path.isAbsolute(targetFile) ? targetFile : path.join(workspaceRoot, targetFile);
    const relTarget = path.relative(workspaceRoot, absTarget).replace(/\\/g, "/");
    const generatedProjections = [".fleet/FLEET.md", ".fleet/README.md", ".agents/rules/fleetkit.md", ".claude/rules/fleetkit.md", ".claude/settings.json", ".cursorrules"];
    if (generatedProjections.includes(relTarget)) {
      return {
        decision: "deny",
        reason: `Direct edits to generated projection '${relTarget}' are forbidden. Edit .fleet/fleet.yaml, .fleet/rules/*.md, or .fleet/agents/*.md and run 'fleetkit sync'.`
      }
    }
    if (relTarget.startsWith(".fleet/") || relTarget === ".fleet") {
      return { decision: "allow" };
    }
    if (payload?.artifactDirectoryPath) {
      const absArtifact = path.resolve(payload.artifactDirectoryPath);
      if (absTarget.startsWith(absArtifact) || relTarget.startsWith(".brain/")) {
        return { decision: "allow" };
      }
    } else if (relTarget.startsWith(".brain/")) {
      return { decision: "allow" };
    }
    const fleetConfig = parseFleetYaml(workspaceRoot);
    let matchedLead = "@general-engineer";
    if (fleetConfig?.defaultLead) {
      const rawDefault = path.basename(fleetConfig.defaultLead, ".md").replace(/^@/, "");
      if (rawDefault && rawDefault !== "general") {
        matchedLead = `@${rawDefault}`;
      }
    }
    if (fleetConfig?.hierarchy) {
      for (const rule of fleetConfig.hierarchy) {
        const cleanPattern = rule.path.replace(/^(\.\/)?\*\*$/, "").replace(/\/\*\*$/, "").replace(/^\.$/, "").replace(/\/+$/, "");
        if (!cleanPattern || relTarget === cleanPattern || relTarget.startsWith(cleanPattern + "/")) {
          if (rule.lead) {
            matchedLead = `@${path.basename(rule.lead, ".md").replace(/^@/, "")}`;
          }
          break;
        }
      }
    }
    return {
      decision: "deny",
      reason: `Direct edit to '${relTarget}' denied. Root Orchestrator cannot directly edit source files in hierarchy route. Please register and dispatch the designated specialist (${matchedLead}) using define_subagent and invoke_subagent.`
    }
  }
  if (toolName === "define_subagent") {
    const isPascal = "Name" in args || "SystemPrompt" in args || "EnableWriteTools" in args;
    const name = args.Name || args.name || "";
    const incomingPrompt = args.SystemPrompt ?? args.system_prompt ?? "";
    const incomingWriteTools = args.EnableWriteTools ?? args.enable_write_tools;
    const agentFile = path.join(workspaceRoot, ".fleet", "agents", `${name}.md`);
    if (fs.existsSync(agentFile)) {
      const rawContent = fs.readFileSync(agentFile, "utf-8");
      const body = rawContent.replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/, "").trim();
      let rulesSection = "";
      const rulesDir = path.join(workspaceRoot, ".fleet", "rules");
      if (fs.existsSync(rulesDir)) {
        const ruleFiles = fs.readdirSync(rulesDir).filter((f) => f.endsWith(".md")).sort();
        if (ruleFiles.length > 0) {
          const inlined = ruleFiles.map((rf) => {
            const ruleRaw = fs.readFileSync(path.join(rulesDir, rf), "utf-8");
            const ruleBody = ruleRaw.replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/, "").trim();
            return ["### " + path.basename(rf, ".md"), ruleBody].join("\n");
          }).join("\n\n");
          rulesSection = ["", "", "## 📜 Active Project Rules", "", inlined].join("\n");
        }
      }
      let scopeSection = "";
      const fleetConfig = parseFleetYaml(workspaceRoot);
      if (fleetConfig?.hierarchy) {
        const matchedRules = fleetConfig.hierarchy.filter((r) => r.lead && path.basename(r.lead, ".md") === name);
        if (matchedRules.length > 0) {
          const paths = matchedRules.map((r) => `\`${r.path}\``).join(", ");
          const allSkills = Array.from(new Set(matchedRules.flatMap((r) => r.skills || [])));
          let skillsStr = "platform defaults";
          if (allSkills.length > 0) {
            skillsStr = allSkills.map((skill) => {
              const agentSkillPath = path.join(".agents", "skills", skill, "SKILL.md");
              const fleetSkillPath = path.join(".fleet", "skills", `${skill}.md`);
              if (fs.existsSync(path.join(workspaceRoot, agentSkillPath))) {
                return `\`${skill}\` (\`${agentSkillPath.replace(/\\/g, "/")}\`)`;
              } else if (fs.existsSync(path.join(workspaceRoot, fleetSkillPath))) {
                return `\`${skill}\` (\`${fleetSkillPath.replace(/\\/g, "/")}\`)`;
              } else {
                return `\`${skill}\``;
              }
            }).join(", ");
          }
          const tests = matchedRules.map((r) => r.verification?.test).filter(Boolean).join(" | ");
          scopeSection = [
            "",
            "",
            "## 🎯 Assigned Domain Scope & Verification",
            `- **Paths**: ${paths}`,
            `- **Skills**: ${skillsStr}`,
            "- **Skill Activation**: Load a skill from the `SKILL.md` files above (via `read_file` or the `skill` tool) on demand when relevant to your task.",
            `- **Verification**: \`${tests || "npm test"}\``
          ].join("\n");
        }
      }
      let composedPrompt = `${body}${rulesSection}${scopeSection}`;
      const trimmedIncoming = typeof incomingPrompt === "string" ? incomingPrompt.trim() : "";
      const firstBodyLine = body.split(/\r?\n/).find((l) => l.trim() && !l.startsWith("#"))?.trim() || "";
      const isDuplicatePersona = Boolean(trimmedIncoming && (body.includes(trimmedIncoming) || Boolean(firstBodyLine && trimmedIncoming.includes(firstBodyLine)) || trimmedIncoming === name || trimmedIncoming === "compose" || trimmedIncoming.includes(`.fleet/agents/${name}.md`) || trimmedIncoming.startsWith(".fleet/agents/")));
      if (trimmedIncoming && !isDuplicatePersona) {
        composedPrompt += ["", "", "## Additional Session Context", trimmedIncoming].join("\n");
      }
      const resolvedWriteTools = name === "code-reviewer" ? false : typeof incomingWriteTools === "boolean" ? incomingWriteTools : true;
      const overwrite = isPascal ? { SystemPrompt: composedPrompt, EnableWriteTools: resolvedWriteTools } : { system_prompt: composedPrompt, enable_write_tools: resolvedWriteTools };
      return {
        decision: "allow",
        overwrite
      }
    }
    return { decision: "allow" };
  }
  if (toolName === "invoke_subagent") {
    const typeName = args.TypeName || args.typeName || args.type || "";
    const subagents = Array.isArray(args.Subagents) ? args.Subagents : Array.isArray(args.subagents) ? args.subagents : [];
    let hasSelf = typeName === "self";
    for (const s of subagents) {
      if ((s?.TypeName || s?.typeName || s?.type) === "self") {
        hasSelf = true;
        break;
      }
    }
    if (hasSelf) {
      return {
        decision: "deny",
        reason: "TypeName: 'self' is forbidden. Roleplaying as a specialist violates the Non-Coding Orchestrator Mandate. Use define_subagent to register the specialist and invoke_subagent with the specialist TypeName."
      }
    }
    return { decision: "allow" };
  }
  return { decision: "allow" };
}

function handleStop() {
  return { decision: "allow" };
}

function main() {
  const event = process.argv[2] || 'PreToolUse';
  let inputRaw = '';
  try {
    inputRaw = fs.readFileSync(0, 'utf-8');
  } catch {
    // stdin empty
  }

  let payload = {};
  if (inputRaw.trim()) {
    try {
      payload = JSON.parse(inputRaw);
    } catch {
      payload = {};
    }
  }

  const workspaceRoot = findWorkspaceRoot(payload);

  if (event.toLowerCase() === 'stop' || payload?.event?.toLowerCase() === 'stop' || payload?.hook?.toLowerCase() === 'stop') {
    const result = handleStop();
    console.log(JSON.stringify(result));
    process.exit(0);
  }

  const result = handlePreToolUse(payload, workspaceRoot);
  console.log(JSON.stringify(result));
  process.exit(0);
}

main();
