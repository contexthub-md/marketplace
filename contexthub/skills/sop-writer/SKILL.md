---
name: sop-writer
description: Create high-quality, research-backed SOPs by exploring the codebase with OCXP, validating every step, and saving with proper metadata. Use when the user says "create SOP", "write a runbook", "document this process", "make a procedure for X", or wants to formalize any workflow into a reusable, validated SOP. Also use when dispatched autonomously to generate SOPs for a topic.
---

# SOP Writer

Create production-quality Standard Operating Procedures grounded in actual code, validated against the codebase, and saved with staleness tracking.

Every SOP you create will be discovered automatically by agents via `ch_get_memory_context` (when auto_include is true) and tracked for staleness when referenced files change.

## Workflow

Given: "$ARGUMENTS" (topic or description of the procedure to document)

### Phase 1: Scope

Before writing anything, understand what's needed:

1. Check for duplicates: call `ch_list_sops` to see if an SOP already exists for this topic. If one exists, ask the user if they want to update it or create a new one.

2. Check memory: call `ch_search_memory` with the topic to find related decisions or past context.

3. Clarify scope with the user (one question at a time):
   - What specific procedure should this cover?
   - Who is the audience -- human operators, AI agents, or both?
   - What category fits best: process, architecture, testing, infrastructure, security, general?

If dispatched as an autonomous agent, infer scope from the topic and available context.

### Phase 2: Research

Ground the SOP in real code. Never write steps from memory alone.

1. `ch_ocxp_warmup` -- orient on the codebase
2. `ch_ocxp_route(topic)` -- find relevant files for the procedure
3. `ch_ocxp_grep` -- search for specific scripts, Makefile targets, CI/CD configs, commands
4. `ch_ocxp_file_read` -- read the actual source to extract exact commands, flags, and parameters
5. Keep a running list of every file path you reference -- these become `depends_on`

If OCXP is unavailable, use `ch_discover_context` to search the knowledge base instead.

### Phase 3: Draft

Write the SOP using this template. Every section matters -- do not skip any.

```markdown
# [Title]
Duration: ~X minutes

## Overview
One paragraph explaining what this procedure does, when to use it, and what it achieves.

## Prerequisites
- Specific tools, access, or state required before starting
- MUST be verifiable (the agent can check these before proceeding)

## Steps

### 1. [Step Name]
[tool: shell | API | UI | kubectl | terraform | git]

Description of what to do and why.

Command or action to take.

Expected: What success looks like (specific output, status, or state change).

### 2. [Next Step]
...

## Verification
How to confirm the entire procedure succeeded. Specific commands or checks with expected results.

## Rollback
What to do if something goes wrong. Step-by-step recovery procedure.

## Troubleshooting

| Problem | Check | Fix |
|---------|-------|-----|
| Common issue 1 | How to diagnose | How to resolve |
| Common issue 2 | How to diagnose | How to resolve |
```

Guidelines for writing steps:
- Each step MUST have a tool annotation (what system/tool is used)
- Each step MUST have an "Expected" line (how to verify it worked)
- Use exact commands from the source code, not approximations
- Include the full command with all flags -- agents follow literally
- If a step has conditions, state them explicitly: "If X, do Y. Otherwise, do Z."
- Use RFC 2119 keywords (MUST, SHOULD, MAY) for constraints that matter

### Phase 4: Validate

Before presenting to the user, verify your work:

1. For each file path referenced, call `ch_ocxp_file_exists` to confirm it exists
2. For Makefile targets, grep for the target name in the Makefile
3. For API endpoints, verify they exist in the router
4. For scripts, verify the file path is correct
5. Flag any step you cannot verify -- mark it with "[UNVERIFIED]" so the user knows

### Phase 5: Save

Present the draft to the user for review (skip if running autonomously).

On approval, save with `ch_create_sop`:
- `title`: clear, action-oriented name
- `content`: the full markdown SOP
- `category`: from Phase 1 scoping
- `priority`: 90 for critical procedures (deploy, rollback), 70 for standard, 50 for reference
- `auto_include`: true for procedures agents should always know about, false for reference-only
- `depends_on`: comma-separated file paths collected during research
- `prompt`: one-line guardrail for agents following this SOP (e.g., "Always verify health before and after")
- `metadata`: JSON string linking the SOP to repos and environments. Always include this:
  ```json
  {"repos": ["owner/repo"], "audience": "both", "environments": ["dev", "prod"]}
  ```
  - `repos` (required): which repositories this SOP applies to. Use `owner/repo` format matching `ch_list_projects` repo IDs.
  - `audience` (required): `"agents"` (machine-only), `"humans"` (manual only), or `"both"`
  - `environments` (optional): which environments the procedure covers: `"dev"`, `"prod"`, `"localstack"`
  - `triggers` (optional): SOP IDs to run after this SOP completes (chain forward)
  - `after` (optional): SOP ID that must run before this one (chain backward)

After saving, confirm the SOP ID and tell the user it will appear in `ch_get_memory_context` if auto_include is true.

## Quality Checklist

Before saving, verify the SOP meets these criteria:
- [ ] Every step has a tool annotation
- [ ] Every step has an Expected output
- [ ] All file paths verified via OCXP
- [ ] Prerequisites are specific and checkable
- [ ] Verification section has concrete success criteria
- [ ] Rollback section exists with recovery steps
- [ ] Troubleshooting table covers at least 2 common issues
- [ ] depends_on includes all referenced files
- [ ] metadata.repos lists all referenced repositories
- [ ] metadata.audience is set (agents, humans, or both)

## Examples

```
/contexthub:sop-writer deploy to production process
/contexthub:sop-writer incident response runbook for API outages
/contexthub:sop-writer how to add a new MCP tool
/contexthub:sop-writer database migration procedure
```
