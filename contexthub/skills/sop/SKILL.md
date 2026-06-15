---
name: sop
description: Create and manage SOPs (Standard Operating Procedures) -- deployment guides, runbooks, architecture decisions, and reusable procedures linked to a project. Use when the user says "create SOP", "write a runbook", "document the process", "deployment guide", "standard procedure", or wants to formalize a workflow into a reusable document.
---

# SOP Management with ContextHub

Create, list, and read Standard Operating Procedures (SOPs) linked to a ContextHub project. SOPs are stored as markdown in S3 and linked to the project for agent context -- other agents can find and follow them automatically.

## When to Create an SOP

SOPs are for **reusable, step-by-step procedures** that agents or humans follow repeatedly:
- Deployment and release processes
- Incident response runbooks
- Architecture decision records
- Testing and QA checklists
- Security procedures
- Infrastructure setup guides

For one-off findings or issues, use `ch_create_memo` instead. For decisions without step-by-step procedures, use `ch_record_decision`.

## Workflow

Given: "$ARGUMENTS" (SOP action or topic)

### Create an SOP

Call `ch_create_sop` with:
- `title`: Clear, action-oriented name (e.g. "Deploy to Production")
- `content`: Full markdown with numbered steps, commands, and verification checks
- `category`: process, architecture, testing, infrastructure, security, general
- `priority`: 0-100 (higher = more relevant in agent context, default 50)
- `auto_include`: true to automatically include in agent context
- `depends_on`: comma-separated file paths the SOP references (enables staleness tracking)

Write SOPs in this structure:
```markdown
# [Title]

## Overview
One paragraph explaining what this procedure does and when to use it.

## Prerequisites
- What must be true before starting

## Steps
1. First step with exact commands
2. Second step with verification
3. ...

## Verification
How to confirm the procedure succeeded.

## Rollback
What to do if something goes wrong.
```

### List SOPs

Call `ch_list_sops` to see all SOPs linked to the active project. Shows title, category, status, priority, and staleness.

### Read an SOP

Call `ch_read_sop(sop_id)` to get the full markdown content of a specific SOP.

### SOP Lifecycle

- **draft**: Work in progress, not yet validated
- **active**: Validated and ready to follow
- **archived**: Outdated, kept for reference

SOPs track `depends_on` file paths. When referenced code changes, the SOP is automatically marked as **stale** so it can be refreshed.

## Examples

```
/contexthub:sop create deployment guide for production releases
/contexthub:sop list
/contexthub:sop read deploy-to-production
/contexthub:sop create incident response runbook for API outages
```
