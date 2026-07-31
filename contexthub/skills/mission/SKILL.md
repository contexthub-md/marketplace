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

Three shapes -- pick one deliberately. They are mutually exclusive per mission: landing a plan by
hand and then moving the mission to `approved` makes AgentCore regenerate over your plan.

**1. Register only (no plan, no analysis).** `ch_create_mission` with:
- `title`: What needs to be done
- `description`: Details and acceptance criteria
- `project_id`: Which project this belongs to
- `priority`: low, medium, high, critical

`pipeline_mode` defaults to `"open"` -- this registers a mission shell and calls no AgentCore.

**2. No plan, let AgentCore analyse it.** Same call plus `pipeline_mode="plan"` (research + docs, stops
at `review` for a human) or `pipeline_mode="process"` (continues into weaver-plan generation with no
approve step). `project_id` is required. AgentCore's brief is `"# {title}\n\n{description}"` and
nothing else, and its readiness gate needs 4 of 6 checks -- so pass `goals` and a description over 100
characters or generation stops. Poll `ch_get_mission` for `weaver_plan_status`
(`generating -> gathering -> structuring -> storing -> ready | failed`). To generate on a mission that
already has content, call `ch_generate_mission_plan(mission_id)`.

**3. Mission + full plan in one call.** `ch_create_mission_with_plan(title, phases, ...)` -- lands at
status `execute` with the plan `ready`, deterministic, no AgentCore. Before writing the payload read
`../mission-forge/references/mission-plan-schema.md`: the phase/todo/spec/dod_gate schema is not
guessable from the docstring, unknown keys are dropped silently, and a validation error orphans a
planless mission. For the full research-and-author pipeline use `/contexthub:mission-forge`.

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
