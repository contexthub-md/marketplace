---
name: connect
description: Connect to a ContextHub project -- guided setup for workspace, project, and mission context. Use this FIRST before any other ContextHub tools. Also use when the user says "connect", "set up project", "switch project", "select workspace", or when you get a NO_PROJECT error from any ch_* tool. For importing new repos from GitHub, use /contexthub:import instead.
---

# Connect to a ContextHub Project

Set up the workspace, project, and mission context that all other ContextHub tools depend on. This is the first thing to do in any ContextHub session.

## Why This Matters

Every ContextHub tool (ch_get_mission, ch_discover_context, ch_ocxp_*, etc.) needs an active project context. Without it, tools return NO_PROJECT errors. This skill walks through setup so everything works smoothly.

## Workflow

Given: "$ARGUMENTS" (project name, project UUID, or empty for guided setup)

### Detect Input Type

- **Empty** ($ARGUMENTS is blank): run the full interactive wizard below
- **UUID** (36-char string with hyphens like `a1b2c3d4-...`): skip to Direct Connect
- **Name** (anything else): skip to Connect by Name

---

### Full Interactive Wizard (no arguments)

#### 1. Workspace

Call `ch_list_workspaces`.

- If exactly 1 workspace: auto-select it silently
- If multiple: show a numbered list and ask the user to pick
- Default is typically "dev"

#### 2. Project

Call `ch_list_projects`.

- **If projects exist**: show a numbered list with name and description. Ask the user to pick one.
- **If exactly 1 project**: auto-select it, but tell the user which one was selected.
- **If no projects exist**: tell the user "No projects found. Import a GitHub repo first with `/contexthub:import <github-url>`." and stop.

#### 3. Mission (Optional)

Call `ch_list_missions` with the selected project.

- If missions exist: show a numbered list with [status] title. Ask: "Pick a mission to focus on, or skip."
- If no missions: skip this step, inform the user.

#### 4. Lock Context + Session

Call `ch_set_context` with the selected workspace, project_id, and optionally mission_id.
Then call `ch_connect_session` to create a persistent session.

#### 5. Confirm

Show a clean summary:

```
Workspace: <name>
Project:   <name> (N repos, M missions)
Mission:   <title> or "none"
Session:   connected
```

Then say: "Ready. All ContextHub tools will use this context."

---

### Connect by Name

When $ARGUMENTS is a project name (e.g. "brain"):

1. Call `ch_list_workspaces` and auto-select
2. Call `ch_list_projects` and search for a project whose name matches $ARGUMENTS (case-insensitive)
3. **If found**: call `ch_set_context(workspace, project_id)` + `ch_connect_session`, then confirm
4. **If not found**: show the available project list and say "No project named '$ARGUMENTS' found. Pick one from above, or import a repo with `/contexthub:import`."

### Direct Connect by UUID

When $ARGUMENTS looks like a UUID:

1. Call `ch_list_workspaces` and auto-select
2. Call `ch_set_project($ARGUMENTS)` directly
3. Call `ch_connect_session`, then confirm

## Rules

- Show names to the user, not UUIDs
- Auto-select silently when only 1 option, but confirm what was selected
- Wait for user response between steps (except auto-select)
- Keep it concise -- no walls of text
- This skill connects to **existing projects only**. For importing new repos from GitHub, direct the user to `/contexthub:import`

## Examples

```
/contexthub:connect
/contexthub:connect brain
/contexthub:connect a1b2c3d4-e5f6-7890-abcd-ef1234567890
```
