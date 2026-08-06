# Mission + plan creation: the real schema

Authoritative, code-verified reference for landing a ContextHub mission. Read this BEFORE calling
`ch_create_mission_with_plan` or `ch_create_mission` -- every rule below was learned by a call that
failed or silently dropped data. Do not infer the schema from tool docstrings; they are shorter than
the truth.

Sources (contexthub-brain): `backend/api/features/core/mcp_server/tools/missions.py`,
`backend/api/features/core/weaver/domain.py`, `backend/api/features/core/weaver/router.py`,
`agentcore/src/flows/weaver/input_readiness.py`, `agentcore/src/flows/mission/pipeline.py`.

## Pick the path first

| | Path A -- bring your own plan | Path B -- let AgentCore analyse |
|---|---|---|
| Tool | `ch_create_mission_with_plan` | `ch_create_mission(pipeline_mode="plan"\|"process")`, or `ch_generate_mission_plan` on an existing mission |
| Research | none, deterministic, no LLM | AgentCore researches, writes docs, generates phases/todos |
| Lands at | mission `execute`, plan `ready` -- runnable immediately | mission `process` -> `review` (mode `plan`) or straight through to a generated plan (mode `process`) |
| Use when | you can already name the phases and todos | the work is large or fuzzy and the shape needs research first |

They are mutually exclusive per mission. Setting a Path A mission to `approved` fires
`prepare_weaver_plan` and OVERWRITES the hand-authored plan
(`features/core/missions/router.py`, `status == APPROVED` branch).

---

# Path A -- `ch_create_mission_with_plan`

Params: `title` (required), `phases` (required), `description`, `docs`, `execution_mode`
(`single` | `team` | `manager`), `goals`, `priority`, `project_id`, `scope`, `workspace`.

## Non-obvious behaviours, all verified

**IDs are assigned, not accepted.** The tool overwrites phase ids with `P{n}` and todo ids with
`P{n}.{m}` by list position. Any `id` you pass is ignored. The ids in the response are authoritative.

**The mission is created BEFORE the plan is validated.** Order is: mission row -> mission branches ->
docs (a `MISSION.md` is auto-templated if your `docs` list has none) -> build and validate the plan.
So a schema error returns `PLAN_ERROR`, rolls the mission back to status `open`, and leaves an
**orphan planless mission** behind, docs included. `ch_get_mission_plan` on it 404s. Each retry of a
bad payload leaves another orphan -- fix the payload, then delete or reuse the orphan.

**Unknown keys are silently dropped, they do not error.** Every field is read with `.get()` and no
model sets `extra="forbid"`. A `spec` carrying `problem`, `root_cause`, `context`, `verification`, or
`known_limits` lands with those keys gone and no warning. Same for a todo-level `references` array.

**`references` only exists inside `spec`.** A todo-level `references` key is never read. Put typed
references at `spec.references`.

**`repo_id` silently defaults to the project's FIRST linked repo** when a todo omits it. On a
multi-repo project that quietly points work at the wrong repo. Set `repo_id` on every todo.

## Phase dict -- keys that are actually read

```
name                  str
goal                  str        # required in practice for manager mode / goal_gated
acceptance_criteria   list[str]  # PROSE ONLY. Machine checks do NOT go here.
completion            "task_list" (default) | "goal_gated"
dod_gate              list[DodCheck]   # see below; the checks the engine actually runs
depends_on            list        # phase deps; "blocked_by" is accepted as a synonym
exit_criteria         list[str]
rollback_strategy     str
observability         list[str]
approval_mode         "auto" (default) | "manual" | "supervised"
trust_score           float
config                {model, skills, required_tools, required_mcps, permission_mode, system_prompt}
execution_target      {kind, instance_type, instance_id, instance_affinity, user_id, display_name}
todos                 list[todo dict]
```

`depends_on` and `blocked_by` are both accepted at phase level and both persist to the model's
`blocked_by`. Values may be `"P1"` or the int `1`. Omit the key entirely and the phase has no gate --
phases then run unordered, which is almost never what a multi-phase mission wants.

## Todo dict -- keys that are actually read

```
role              str    # default "implementer"
description       str
repo_id           str    # SET THIS -- see the silent default above
repo_branch       str
task_type         "standard" (default) | "weaved"
ownership_type    "agent" (default) | "agent_human" | "human"
depends_on        list   # "P1.2" (cross-phase ok) or an int = todo index within this phase
file_paths        list[str]
estimate          int minutes, or "30m" / "2h" (coerced)
spec              dict   # see below
execution_target  dict
trust_score       float
metadata          dict   # free-form; the per-todo model tier hint rides here
```

Unresolved dependencies are a hard `VALIDATION_ERROR` naming each one -- that check is reliable, so
lean on it rather than eyeballing ids.

## `spec` -- exactly ten fields, nothing else survives

```
name  location  spec_type  summary  inputs  outputs  behavior  constraints  edge_cases  references
```

`inputs`/`outputs`/`behavior`/`constraints`/`edge_cases` are `list[str]`. There is nowhere to put a
root cause, a verification procedure, or a known limitation -- fold those into `summary` (problem +
root cause) and `edge_cases` (prefix lines `VERIFY:` / `EDGE:`) or they are lost.

`spec.references` entries:

```json
{"type": "file", "label": "ch_create_memo", "target": "backend/.../memos.py:133-200", "description": "optional", "section": "optional markdown heading"}
```

`type` is one of `file | url | kb_result | research | spec | doc | decision`. An unrecognised type is
silently coerced to `file`. A **bare string** instead of an object throws inside the builder -> the
whole call fails with `PLAN_ERROR` and orphans the mission.

## `dod_gate` -- the wire contract, and the trap

Discriminated on `check`. This union is duplicated byte-identically in three places -- brain
`weaver/domain.py`, agentcore `flows/weaver/models.py`, and weaver-hub `src-tauri/src/mission/plan.rs`.

```json
{"check": "command",       "run": "make predeploy-check", "expect_exit": 0, "repo": null}
{"check": "file_exists",   "path": "src/x.rs"}
{"check": "file_contains", "path": "src/x.rs", "contains": "fn foo"}
{"check": "prose",         "text": "human-graded criterion, recorded not run"}
```

**The command field is `run`, not `command`.** `{"check": "command", "command": "..."}` fails with
`dod_gate.0.command.run Field required` -- and orphans the mission. There is no `commit_ancestor`
check; commit evidence is enforced separately by `report_todo_complete`. A `prose`-only goal-gated
phase never auto-passes; it waits for a recorded verdict.

**`file_exists` / `file_contains` MUST set `repo` on a multi-repo mission.** With `repo` unset the path
resolves against the mission worktree ROOT, which holds only repo DIRECTORIES -- the check can never
pass and the phase is unpassable by construction. This stuck two phases in a live mission. A `command`
check in the same gate that does set `repo` will pass and mask it.

## Always read the plan back

```
ch_get_mission_plan(mission_id, detail="full")          # or phase_id="P1" to keep it small
```

Confirm `phase_count` / `todo_count`, that every phase has the `blocked_by` you intended, and that
the specs still contain what you wrote. This read-back is the only way to see silent drops.

## Repairing a landed plan

`ch_edit_mission_plan(mission_id, phase_id[, todo_id], action="update", updates={...},
status=..., expected_revision=...)`. A partial `updates` dict is safe -- only the keys you send are
written, the rest of the phase/todo is untouched.

| Editable on a phase | Editable on a todo |
|---|---|
| `name`, `order`, `blocked_by`, `config`, `todos`, `execution_target`, `approval_mode`, `goal`, `acceptance_criteria`, `completion`, `dod_gate`, `exit_criteria`, `rollback_strategy`, `observability` | `role`, `description`, `file_paths`, `blocked_by`, `estimate`, `context_keys`, `spec`, `execution_target`, `repo_id`, `repo_branch`, `task_type`, `ownership_type` |

The gating fields are editable -- a wrong `dod_gate`, `goal`, or `repo_id` is a repair, not a reason to
recreate the mission. **One exception:** `ownership_type` is a TODO field only. Brain's `WeaverPhase`
model has no such field (weaver-hub's Rust `Phase` struct does), so there is nothing to set on a phase.

Sending a phase's whole `todos` array still rebuilds every entry as `WeaverTodo(**t)`, so each dict
must carry at least `id`, `role`, and `description` and anything you omit reverts to its default
(`status` back to `pending`). There is no longer a reason to reach for it: edit the one todo, or
reorder with the action below.

## Structural actions

`action` selects the operation. It defaults to `"update"`, which is byte-identical to the old
field-edit behaviour -- existing callers are unaffected.

| action | what it does |
|---|---|
| `update` (default) | writes `updates` onto the phase, or onto the todo when `todo_id` is given |
| `add_phase` / `add_todo` | appends a new phase, or a todo to `phase_id` |
| `delete_phase` / `delete_todo` | removes one |
| `reorder_phases` / `reorder_todos` | rewrites the order from an id list |

Generated ids come off a persisted high-water mark, never `len(array)`, so a deleted id is never
reused. Ids match `^P\d+$` (phase) and `^P\d+\.\d+$` (todo) -- weaver-hub's `sync_plan_status` git
scan depends on that shape.

## What the edit path rejects

- **422 on a malformed `dod_gate`**, and nothing is persisted. The command check's field is `run`
  here too; `command` is a 422.
- **422 on `completion: "goal_gated"` when that would leave an EMPTY `dod_gate`.** An empty gate can
  never pass, so the phase could never complete -- and silently downgrading it to `task_list` would
  make the phase read COMPLETE with its checks never run (a phantom completion).
- Switching a phase `goal_gated` -> `task_list` **RETAINS** `dod_gate` (inert while `task_list`).
  Nothing is destroyed.
- **422 listing the valid values** on an unknown `completion` (`task_list|goal_gated`), `task_type`
  (`standard|weaved`), or `ownership_type` (`agent|agent_human|human`).
- **422 on a reorder list that is not a COMPLETE permutation** of the current ids -- omitting an id
  does not delete it, the whole call is rejected.
- **409 NAMING the blocking referent** on a delete that would leave a dangling
  `blocked_by`/`depends_on` edge. It never cascades: a dangling edge is dropped silently at both ends
  (Brain sanitises on every construction, weaver-hub's loader strips unknown edges on load), so a
  cascade would delete work nobody asked to delete.
- **409 on deleting a Running phase or an `in_progress` todo.** Stop it first.
- Deleting the **last** todo in a phase IS allowed -- the phase completes on the next pass rather than
  becoming uncompletable.

## `expected_revision` -- optimistic concurrency

Pass the `revision` you read from `ch_get_mission_plan` and a stale write is rejected with 409 instead
of clobbering a concurrent writer. Omit it and the write is last-write-wins.

It is honoured on the phase/todo field PUTs and on every structural action, but the **status-only path
is deliberately UNGUARDED** -- Weaver persists its own run record and holds no revision. Passing
`expected_revision` together with a status-only update returns a clear validation error rather than
silently ignoring the guard.

**Edit validates strictly where create did not.** The edit path builds `TodoSpec(**spec)`, so a bare
string in `spec.references` returns HTTP 422 (`Input should be a valid dictionary or instance of
SpecReference`). A plan that "created fine" can 422 on the first edit -- that asymmetry is usually how
create-time loss is discovered.

---

# Path B -- create the mission, let AgentCore analyse

## `ch_create_mission(pipeline_mode=...)`

- `open` (default) -- register only, no AgentCore call.
- `plan` -- registers, then runs the AgentCore mission pipeline (MISSION.md, research, docs) and
  stops at `review` for a human.
- `process` -- the same, continuing into weaver-plan generation with no manual approve step.

`project_id` is **required** for `plan` and `process`; the tool rejects up front rather than leaving a
mission stuck at intake.

The brief AgentCore researches is `"# {title}\n\n{description}"` -- nothing else. Invest in
`description`; task specs are AgentCore's job in this path, not yours. `requested_outputs` defaults to
`["implementation-plan"]`.

Poll `ch_get_mission(mission_id)` for `status` and `weaver_plan_status`:
`generating -> gathering -> structuring -> storing -> ready | failed`.

## Clear the input-readiness gate or generation stops

`agentcore/src/flows/weaver/input_readiness.py` scores six checks and needs **>= 0.60 (4 of 6)**:

`has_goals`, `has_title`, `has_description`, `has_mission_content` (content > 100 chars),
`has_impl_plan_phases`, `has_implementation_plan_file` (`docs/implementation-plan.md`).

A bare title + short description scores 3/6 and is **not ready**. The cheap way to clear it at
creation time: pass `goals` AND a `description` longer than 100 characters -- title + description +
goals + content-length = 4/6. The last two checks come from a completed research phase, so a mission
created `pipeline_mode="plan"` earns them on the way through.

## `ch_generate_mission_plan(mission_id)`

Triggers plan generation on a mission that already has content (from `pipeline_mode="plan"`/`process`,
or docs you wrote). Fails the readiness gate if the mission is thin. Use this to re-generate, or to
generate after enriching a mission created with `pipeline_mode="open"`.

`ch_update_mission(mission_id, status="approved")` fires the same generation (and sets
`weaver_plan_status="generating"`). Never do this to a Path A mission.
