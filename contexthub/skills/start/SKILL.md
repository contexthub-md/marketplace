---
name: start
description: Orientation map for working with ContextHub -- which ch_* tool or /contexthub skill to use for a given intent. Use when you are new to a ContextHub project, unsure which ContextHub tool/skill fits a task, deciding between similar-sounding tools (search vs discover vs memory, ocxp search vs query vs grep, record_decision vs create_memo vs write_context), or the user mentions ContextHub / ch_ tools / "what can ContextHub do". Use FIRST when orienting in a ContextHub project.
---

# ContextHub Start -- Router & Orientation

ContextHub is your project memory + code-intelligence layer: ~73 `ch_*` MCP tools and a set of `/contexthub:*` skills. This skill is the MAP -- it tells you which one to reach for. Skills stay lazy-loaded; invoke the right one per intent rather than loading everything.

## First moves (any ContextHub project)

1. `ch_get_memory_context` -- call FIRST to orient (bundles project, mission, memos, sessions, decisions, auto-SOPs).
2. If you get `NO_PROJECT` / not connected -> `/contexthub:connect`.
3. Prefer `detail="summary"` on data tools; escalate only when needed.

## Intent -> what to use

| You want to... | Use |
|----------------|-----|
| Get oriented / "what's going on here" | `ch_get_memory_context`, then `/contexthub:status` |
| Project health: what needs attention | `ch_get_compass` (or `/contexthub:status`) |
| Understand the codebase / find where X is implemented / trace calls | `/contexthub:explore` |
| Plan a change / assess blast radius before coding | `/contexthub:plan` |
| Audit code quality / dead code / coverage | `/contexthub:analyze` |
| Search OUR project's reference docs (indexed library/framework repos) | `/contexthub:kb` |
| Multi-source research (web + external library docs + KB) | `/contexthub:research` |
| Recall a past decision ("what did we decide about X?") | `ch_search_memory` |
| Persist a session decision / working note you'll want to recall | `ch_record_decision` |
| Check which accepted architecture decisions (ADRs) govern files before editing | `/contexthub:adr-follow` |
| Record an architectural choice as a proposed ADR (a human accepts it) | `/contexthub:adr-capture` |
| Fix ADR anchors after moving, renaming or deleting governed code | `/contexthub:adr-anchors` |
| Flag an issue/bug/finding to track | `ch_create_memo` |
| Attach/save a document to a mission or project | `/contexthub:context` (`ch_write_context`) |
| Create / update / track a mission | `/contexthub:mission` |
| Read a mission's phases/todos (the Weaver plan) | `ch_get_mission_plan` |
| Fix a phase/todo in a landed plan, or add/delete/reorder one | `ch_edit_mission_plan` |
| Pause/resume/kill a running plan, or approve the review gate | `ch_control_mission_plan` |
| List/read a mission's attached resources, or build a todo's context bundle | `ch_get_mission_resources` |
| Start dev on a mission (branch + index) | `/contexthub:mission-dev` |
| Import a GitHub repo | `/contexthub:import` |
| Write a runbook / deployment guide / SOP | `/contexthub:sop` or `/contexthub:sop-writer` |
| Deploy / merge / release | list + read the SOPs (`ch_list_sops` -> `ch_read_sop`) |
| Resume a previous session | `/contexthub:resume` |
| Post-run feedback / retro | `/contexthub:reflect` |

When unsure of a content type or what's available, query live (`ch_list_context_types`, `ch_list_projects`, `ch_list_missions`) rather than guessing -- the catalog changes.

## Tiebreakers for similar-sounding tools

**Recall / context (the 4 that sound alike):**
- `ch_get_memory_context` -- session orientation BUNDLE (start here).
- `ch_get_compass` -- project HEALTH dashboard (missions/memos/attention).
- `ch_search_memory` -- recall past **decisions/findings** (semantic, LTM).
- `ch_discover_context` -- search **knowledge**: project KB, docs, web, library docs.

**Code search (OCXP):**
- `ch_ocxp_search` -- by **meaning** ("auth middleware").
- `ch_ocxp_query` -- by **type/relationship** ("all Repository classes", "callers of X").
- `ch_ocxp_grep` -- **literal** string / regex.
- `ch_ocxp_route` -- task -> ordered **waypoints** to implement it.
- Always `ch_ocxp_warmup` first; OCXP needs an active project UUID (`ch_set_project`).

**Writing things down (3 that sound alike):**
- `ch_record_decision` -- a durable session DECISION or note you'll want to recall later. Architectural decisions with lasting effect go to ADRs instead (`/contexthub:adr-capture`, proposed only; a human accepts).
- `ch_create_memo` -- a trackable ISSUE/finding/alert (has status, gets resolved).
- `ch_write_context` -- a DOCUMENT (mission/project doc). Never use a memo as a doc; never raw-S3.

**Weaver plan (structured phases/todos, not raw docs):**
- `ch_get_mission_plan` -- READ the plan. Note the `revision` and pass it back as `expected_revision`.
- `ch_edit_mission_plan` -- WRITE. `action="update"` (default) edits fields on a phase/todo;
  `add_phase`, `delete_phase`, `reorder_phases`, `add_todo`, `delete_todo`, `reorder_todos` change
  structure. Gating fields (`goal`, `dod_gate`, `completion`, a todo's `repo_id`) ARE editable.
- `ch_control_mission_plan` -- RUN control: pause/resume/kill, approve/reject the review gate, batch
  phase/todo status updates.
- `ch_get_mission_resources` -- a mission's attached resources: list, read one, or assemble a todo's
  context bundle (`token_budget`).

**Show vs get:**
- `ch_show_*` -- renders a zero-token UI panel (user wants to SEE it).
- `ch_get_*` -- returns data for YOU to reason on.

**Skill vs the tool it wraps:** skills (`/contexthub:discover`, `/contexthub:kb`, `/contexthub:research`) orchestrate multi-step workflows over the tools; call the tool directly only for a one-shot.

## Skill lane clarifier (these three overlap)

- `/contexthub:kb` -- our project's OWN indexed reference repos (e.g. Strands, EMQX docs).
- `/contexthub:research` -- broadest: web (Tavily) + external library docs (Context7) + KB.
- `/contexthub:discover` -- general semantic search over project knowledge.

## Examples

```
/contexthub:start                      # show me the map
/contexthub:start how do I attach a doc to a mission
/contexthub:start search code vs search docs vs search memory
```
