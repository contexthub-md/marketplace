---
name: mission
description: Mission management -- list, create, update, and track development missions. Use when working with tasks, stories, or bugs in ContextHub.
---

# Mission Management with ContextHub

Manage development missions (tasks, stories, bugs) through ContextHub.

## Workflow

Given: "$ARGUMENTS" (mission action or query)

### List Missions

Call `ch_list_missions` to see current missions.
- Filter by `status`: active, completed, paused, archived
- Filter by `project_id` to scope to a specific project

### Get Mission Details

Call `ch_get_mission` with the mission ID for full details including:
- Goals, notes, and progress
- Related memos (issues, findings)
- Current status and priority

### Create a Mission

Call `ch_create_mission` with:
- `title`: What needs to be done
- `description`: Details and acceptance criteria
- `project_id`: Which project this belongs to
- `priority`: low, medium, high, critical

### Update Progress

Call `ch_update_mission` to:
- Change `status`: active, completed, paused, archived
- Set `progress`: 0-100 percentage
- Update `priority` or add `notes`

### Record Decisions

When important decisions are made during mission work, persist them with `ch_record_decision`:
- `content`: the decision text
- `decision_type`: architecture, scope, priority, technical, process
- `mission_id`: links the decision to the mission

Recorded decisions are searchable across future sessions via `ch_search_memory`.

## Examples

```
/contexthub:mission list active missions for project brain
/contexthub:mission create "Fix EMQX reconnection logic" priority=high
/contexthub:mission update M-001 status=completed progress=100
```
