---
name: status
description: Project health check -- get a compass briefing on project status, active missions, open memos, and what needs attention.
---

# Project Status with ContextHub

Get a quick orientation on where a project stands.

## Workflow

Given: "$ARGUMENTS" (project name or ID)

### 1. Get Compass

Call `ch_get_compass` with the project ID. This returns:
- **Active missions**: What work is in progress
- **Recently completed**: What was just finished
- **Open memos**: Issues and findings that need attention
- **Health summary**: Whether the project needs attention

### 2. Drill Down

Based on the compass, investigate further:
- `ch_get_mission` for details on any concerning mission
- `ch_list_memos` to review open issues
- `ch_discover_context` to search for specific context

### 3. Take Action

- `ch_create_memo` to flag new issues
- `ch_update_mission` to update progress
- `ch_resolve_memo` to close resolved issues

## Examples

```
/contexthub:status brain
/contexthub:status project-abc
```
