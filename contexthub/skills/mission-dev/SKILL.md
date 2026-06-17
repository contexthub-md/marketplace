---
name: mission-dev
description: Start developing on a mission -- creates or checks out the mission branch, sets up the workspace, and indexes the branch. Use when starting work on a mission, switching to a mission branch, or setting up a development environment for a specific mission.
---

# Mission Development Workflow

Set up a development environment for a ContextHub mission. Handles branch creation/checkout, workspace configuration, and branch indexing.

## What Happens When a Mission is Created

When `ch_create_mission` is called, the Brain API automatically:
1. Creates `mission/{mission_id}` branches on ALL repos linked to the project
2. Registers branches in the repo registry for delta indexing
3. This runs as a background task -- branches appear within ~30 seconds

## Workflow

Given: "$ARGUMENTS" (mission ID, title, or "start" to begin work)

### 1. Find or Create the Mission

If a mission ID is provided, use it directly.
If a title/description is provided, create the mission:
```
ch_create_mission(title="...", description="...", project_id="...", priority="high")
```
This auto-creates `mission/{mission_id}` branches on all linked repos.

### 2. Verify Branches Exist

Wait a few seconds for the background task, then verify:
```bash
git fetch origin
git branch -r | grep "mission/{mission_id}"
```

If branches are missing (e.g., GitHub credentials expired), create manually:
```bash
git checkout main && git pull
git checkout -b mission/{mission_id}
git push origin mission/{mission_id}
```

### 3. Check Out the Mission Branch

For each repo you're working on:
```bash
git checkout mission/{mission_id}
git pull origin mission/{mission_id}
```

### 4. Set Up Workspace

If using the `.workplaces` pattern:
```bash
# The mission branch is now your development branch
# All commits go to mission/{mission_id}
# When done, PR from mission/{mission_id} -> main
```

### 5. Index the Mission Branch (Optional)

To get OCXP code intelligence on your mission's changes:
```
ch_trigger_index(branch="mission/{mission_id}")
```

This builds a delta index on top of main -- your mission's code changes are searchable via:
```
ch_ocxp_grep(pattern="...", branch="mission/{mission_id}")
ch_ocxp_search(query="...", branch="mission/{mission_id}")
```

### 6. Develop

Work on the mission branch. Commit frequently. Use the mission ID in commit messages for traceability:
```bash
git commit -m "feat: Add PipelineMetrics struct [M-{mission_id}]"
```

### 7. Complete the Mission

When work is done:
1. Push all changes: `git push origin mission/{mission_id}`
2. Create PR: `gh pr create --base main --head mission/{mission_id}`
3. After merge, update mission: `ch_update_mission(mission_id, status="completed", progress=100)`
4. Optionally delete the branch: `ch_delete_branch_index(branch="mission/{mission_id}")`

## Quick Start

```
/contexthub:mission-dev start "Project Observability" on ContextHub project
/contexthub:mission-dev checkout 2ff27de5-e706-44cf-b216-155bf0fbe8ba
/contexthub:mission-dev index mission/2ff27de5-e706-44cf-b216-155bf0fbe8ba
```

## Key Points

- Mission branches follow the pattern `mission/{mission_id}` (UUID)
- Branches are created on ALL repos linked to the project (not just the current one)
- Delta indexing works on mission branches -- search your changes before merging
- Use `ch_update_mission` to track progress as you work
- Record important decisions with `ch_record_decision(mission_id=...)`
