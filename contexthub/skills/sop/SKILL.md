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

For quick creation, call `ch_create_sop` directly with title, content, and category.

For **high-quality, research-backed SOPs**, use `/contexthub:sop-writer <topic>` instead -- it researches the codebase via OCXP, validates every step, and follows a structured template with tool annotations, expected outputs, and troubleshooting tables.

You can also dispatch the `contexthub:sop-writer` agent autonomously for batch SOP creation.

### List SOPs

Call `ch_list_sops` to see all SOPs linked to the active project. Shows title, category, status, priority, and staleness.

### Read an SOP

Call `ch_read_sop(sop_id)` to get the full markdown content of a specific SOP.

### SOP Lifecycle

- **draft**: Work in progress, not yet validated
- **active**: Validated and ready to follow
- **archived**: Outdated, kept for reference

SOPs track `depends_on` file paths. When referenced code changes, the SOP is automatically marked as **stale** so it can be refreshed.

## Metadata Standard

Always include metadata when creating SOPs to link them to repos and environments:

```
ch_create_sop(
  ...,
  metadata='{"repos":["sonic-web-dev/contexthub-brain"],"audience":"both","environments":["dev","prod"]}'
)
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `repos` | Yes | string[] | Repositories this SOP applies to (`owner/repo` format) |
| `audience` | Yes | string | `"agents"`, `"humans"`, or `"both"` |
| `environments` | No | string[] | `"dev"`, `"prod"`, `"localstack"` |

Agents use metadata to find the right SOP for their context. Always set `repos` to the specific repos the SOP references.

## Examples

```
/contexthub:sop list
/contexthub:sop read deploy-to-production
/contexthub:sop-writer deployment guide for production releases
/contexthub:sop-writer incident response runbook for API outages
```
