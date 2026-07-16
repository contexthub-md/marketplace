---
name: mission-forge
description: Forge a raw idea into a complete, executable ContextHub mission -- research it, review the codebase with OCXP, validate every reference, then create the mission with SMART goals, research docs, phases, specced todos, agent assignments, and worktree setup in one call. Use when the user says "forge a mission", "turn this idea into a mission", "plan and create a mission for X", "scope this into tasks and build the mission", or hands you a feature/refactor idea and wants a ready-to-execute mission plan (not just a plan document).
---

# Mission Forge

Turn an idea into a complete, executable ContextHub mission. This skill runs the full pipeline -- research, OCXP codebase review, reference validation, SMART goal synthesis, task breakdown, agent + worktree assignment -- then creates the entire mission (goals, docs, phases, todos, references) in ONE call via `ch_create_mission_with_plan`.

Where `/contexthub:plan` produces a plan you read, and `/contexthub:mission` creates an empty mission shell, mission-forge does both and more: it emits a fully-specced, dependency-ordered, agent-assigned mission that a team can start executing immediately.

## Prerequisites

An active project with indexed repositories is required. If you get `OCXP_UNAVAILABLE` or `NO_PROJECT`, run `/contexthub:connect` first. Research still works without OCXP, but you cannot validate references or assess blast radius -- do not forge a mission on an unindexed project.

## Workflow

Given: "$ARGUMENTS" (an idea, feature request, refactor goal, or problem statement)

### 1. Connect and orient

Call `ch_get_memory_context` first to load project, active missions, memos, and prior decisions. If it returns `NO_PROJECT`, tell the user to run `/contexthub:connect` and stop. Note the `project_id` and `workspace` -- you pass them to every tool below and to the final create call.

### 2. Research the idea

Fan out `ch_discover_context` across sources to ground the idea in real knowledge (mirrors `/contexthub:research`):
- **Project KB**: `ch_discover_context(query=<idea>, content_type="docs", include_answer=true, max_results=5)`
- **Library docs** (Context7): `ch_discover_context(query=<library/API>, context_type="docs-library", max_results=5)`
- **Web** (Tavily): `ch_discover_context(query=<idea>, provider="tavily", max_results=5)`

For AWS specifics (services, IAM, CLI, SDK), pull the current AWS / library docs through Context7 via `ch_discover_context(context_type="docs-library")`. Capture every finding with its source reference -- these become research docs and task `references[]` in later steps.

### 3. OCXP review of the codebase

Ground the idea in the actual code graph (mirrors `/contexthub:plan`):

1. `ch_ocxp_warmup` -- module tree, entry points, key types.
2. `ch_ocxp_plan` with the idea, `mode: "modify"`, `scope` + `focus_repo` to prevent cross-repo leakage, `output_mode: "default"`. This returns navigation waypoints AND a YAML implementation spec in one call.
3. `ch_ocxp_standards_check` -- extract EVERY function name, file path, and infrastructure reference from the spec and validate each against the code graph.
4. `ch_ocxp_audit` -- feed the spec in to confirm it follows codebase rules and patterns; review the score.
5. `ch_ocxp_references` -- for each key entity, get the blast radius (what calls/imports/uses it, cross-repo edges).

Record the OCXP entity IDs and file paths you touch -- you cite them as task `references[]` (type `SPEC`/`FILE` with the entity path as `target`).

### 4. Validate every external and internal reference

Do NOT proceed on failed references -- a hallucinated path wastes an agent's entire task.

- **Internal**: if any `ch_ocxp_standards_check` reference FAILS, use `ch_ocxp_search` to find the correct path, fix it, and report `Corrected: X -> Y` to the user.
- **External**: confirm any library/API/CLI/AWS usage against current docs via `ch_discover_context(context_type="docs-library")`. Note any corrections.

### 5. Synthesize research docs

Assemble the findings + OCXP results + decisions into markdown documents. These become the `docs=[]` argument (the tool writes them via the same path convention as `/contexthub:context`):
- `docs/research/<topic>.md` -- KB + library + web findings with source refs.
- `docs/ocxp-findings.md` -- validated entities, blast radius, corrected paths, audit score.

Each doc is `{path, content}`. Reference these docs from tasks (type `RESEARCH`/`DOC` with the doc path as `target`) so every agent lands on the same source of truth.

### 6. Parse into SMART goals and exact tasks

**Goals** -- write them Specific, Measurable, Achievable, Relevant, Time-bound. Vague goals produce vague tasks.

**Phases and todos** -- break the plan into phases, each with ordered todos. Every todo MUST carry:
- `role` -- the kind of agent that owns it (e.g. `backend`, `infra`, `frontend`, `review`, `test`).
- `repo_id` + `repo_branch` -- which repo and branch it develops on.
- `spec` -- a real `{name, location, spec_type, summary, inputs, outputs, behavior, constraints, edge_cases}`, not a placeholder. Pull `behavior`/`constraints`/`edge_cases` from the OCXP spec and `ch_ocxp_constraints`.
- `references[]` -- LINK to OCXP findings (type `SPEC` or `FILE`, `target` = entity path) and to the research docs (type `RESEARCH` or `DOC`, `target` = doc path). Reference `type` is one of `FILE | URL | KB_RESULT | RESEARCH | SPEC | DOC | DECISION`.
- `depends_on` -- express dependencies by task order/label, NOT by invented IDs (see Tips).
- `execution_target` -- `{kind: "pool" | "direct" | "person", ...}`.

### 7. Assign agents and worktrees inside the tasks

For each todo, encode WHO runs it and WHERE it develops:
- Agent = `role` + `execution_target.kind`. Note model routing in the spec/description: **Opus** for architecture, wiring, and review; **Sonnet** for standard code generation to a clear spec; **Haiku** for mechanical work (rename, format, run tests).
- Branch convention: integration branch `mission/{mission_id}`; per-agent branches `mission/{mission_id}/<role>-<n>`; worktrees under `.worktrees/{short_mission_id}/<repo>/`.
- One owner per FILE per worktree -- never assign two concurrent todos that edit the same file.
- Set `depends_on` so serial work (e.g. review after implementation) is ordered and independent work can run in parallel.

### 8. Create the mission in one call

```
ch_create_mission_with_plan(
  title, description, project_id, priority,
  goals=[<SMART goals>],
  docs=[{path, content}, ...],
  phases=[{name, todos:[{role, description, repo_id, repo_branch,
           spec:{...}, references:[{type, label, target, description}],
           depends_on, execution_target:{kind, ...}}]}],
  scope, workspace)
```

Returns `{mission_id, doc_paths, plan_version, phase_count, todo_count}`. Report these back to the user. The tool assigns canonical `P{n}` / `P{n}.{m}` task IDs and remaps your loose `depends_on` -- so the IDs in the result are authoritative.

### 9. Set up worktrees

After creation, the branches `mission/{mission_id}` are auto-created on all linked repos (see `/contexthub:mission-dev`). Give the per-agent worktree commands:

```bash
git fetch origin
git worktree add .worktrees/{short_mission_id}/<repo>/<role>-<n> \
  -b mission/{mission_id}/<role>-<n> origin/mission/{mission_id}
```

Then index each agent branch so OCXP can serve code intelligence on the in-flight changes:

```
ch_trigger_index(branch="mission/{mission_id}/<role>-<n>")
```

Agents search their own changes with `ch_ocxp_grep(pattern=..., branch=...)` / `ch_ocxp_search(query=..., branch=...)` before merging up to `mission/{mission_id}`, which PRs to `main`.

## Examples

```
/contexthub:mission-forge add rate limiting to the ask API
/contexthub:mission-forge migrate the docs KB from AOSS to S3 Vectors
/contexthub:mission-forge refactor the auth module into a shared crate
/contexthub:mission-forge build a webhook consumer that auto-indexes pushed branches
```

## Tips

- Always run `ch_ocxp_standards_check` and `ch_ocxp_audit` before forging -- an unvalidated reference in a task spec becomes an agent's dead end.
- Cite OCXP entity IDs/paths in `references[]` (type `SPEC`/`FILE`) so each agent starts from ground truth, not a re-derived guess.
- The LLM emits loose task ordering; `ch_create_mission_with_plan` assigns canonical `P{n}`/`P{n}.{m}` IDs and remaps `depends_on`. Refer to dependencies by order/label, never by invented IDs.
- One owner per FILE per worktree. Two agents editing the same file concurrently will collide -- serialize with `depends_on` or split the file boundary.
- Match model to cognitive demand in each task: Opus for architecture/review, Sonnet for spec-driven code, Haiku for mechanical work.
- Research docs are load-bearing: every task should reference at least one `RESEARCH`/`DOC` and one `SPEC`/`FILE`. A task with no references is under-specified.
- Pass `project_id` and `workspace` on every call, including the final `ch_create_mission_with_plan`.
- Run `ch_ocxp_diff` per agent branch after implementation to verify the structural change matches the task spec.
