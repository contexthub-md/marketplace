---
name: resume
description: Resume a previous ContextHub session -- load context, recap where you left off, and propose next steps. Use when the user says "resume", "where was I", "continue from last time", "pick up where I left off", or starts a new conversation on a project they've worked on before.
---

# Resume a ContextHub Session

Pick up where you left off by loading a previous session's context, decisions, and progress.

## Workflow

Given: "$ARGUMENTS" (session ID, or empty for guided selection)

### 1. Find the Session

If a session ID was provided, use it directly.

Otherwise, call `ch_list_sessions(limit=5)` and show the user recent sessions:

```
1. [2h ago] "Implement MQTT bridge" (12 messages)
2. [1d ago] "Debug auth flow" (8 messages)
3. [3d ago] "API refactor planning" (24 messages)
```

Ask which to resume.

### 2. Load Context

Call `ch_get_session_messages(session_id)` to load the conversation history.

Then call `ch_get_memory_context` to get the current project/mission state, including decisions and open memos.

### 3. Recap

Give the user a tight summary (under 10 lines):

- **Last session**: what was being worked on (from the messages)
- **Decisions**: bullet list of relevant recorded decisions
- **Open items**: unfinished work, open memos, stalled progress

### 4. Propose Next Steps

Suggest 2-3 concrete next actions based on where things left off. Ask which to pursue.

### 5. Continue

As the session continues:
- Record new decisions with `ch_record_decision`
- Search for older context with `ch_search_memory` if needed
- Update mission progress with `ch_update_mission`

## Rules

- Recap in under 10 lines -- distill, don't replay the transcript
- Show session titles and timestamps, not raw IDs
- Focus on what changed and what's pending, not everything that happened

## Examples

```
/contexthub:resume
/contexthub:resume abc-123-session-id
```
