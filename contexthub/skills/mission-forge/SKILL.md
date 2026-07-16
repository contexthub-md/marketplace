---
name: mission-forge
description: Forge a raw idea into a complete, executable ContextHub mission -- research it, review the codebase with OCXP, validate every reference, then create the mission with SMART goals, research docs, phases, specced todos, agent assignments, and worktree setup in one call. Use when the user says "forge a mission", "turn this idea into a mission", "plan and create a mission for X", "scope this into tasks and build the mission", or hands you a feature/refactor idea and wants a ready-to-execute mission plan (not just a plan document).
---

# Mission Forge

Turn an idea into a complete, executable ContextHub mission. This skill runs the full pipeline -- research, OCXP codebase review, reference validation, SMART goal synthesis, task breakdown, agent + worktree assignment -- then creates the entire mission (goals, docs, phases, todos, references) in ONE call via `ch_create_mission_with_plan`.

Where `/contexthub:plan` produces a plan you read, and `/contexthub:mission` creates an empty mission shell, mission-forge does both and more: it emits a fully-specced, dependency-ordered, agent-assigned mission that a team can start executing immediately.

There are TWO ways to land a mission, and you pick one per mission (they are mutually exclusive -- see the warning in step 8):

- **Mode 1 -- Simple / on-the-spot (default).** You research and author the plan yourself, then land it settled and execute-ready in one call with `ch_create_mission_with_plan`. This is the whole workflow below and is the right path when you can already specify the phases and tasks with confidence.
- **Mode 2 -- Complex / AgentCore-generated.** You write a rich mission description and let AgentCore do the research, write the docs, and generate the phased Weaver plan. Use this when the mission is large, fuzzy, or needs deep research before anyone can name the tasks. See "Mode 2" below.

## Prerequisites

An active project with indexed repositories is required. If you get `OCXP_UNAVAILABLE` or `NO_PROJECT`, run `/contexthub:connect` first. Research still works without OCXP, but you cannot validate references or assess blast radius -- do not forge a mission on an unindexed project.

## Workflow

Given: "$ARGUMENTS" (an idea, feature request, refactor goal, or problem statement)

### 0. Choose the mode

After orienting (step 1) and enough OCXP review to judge scope, decide which mode fits:

- **Can you already specify the phases and tasks with confidence after OCXP review?** -> **Mode 1**: author the plan yourself and land it with `ch_create_mission_with_plan` (execute-ready). Follow steps 1--9.
- **Is it large, fuzzy, or does it need deep research first?** -> **Mode 2**: create the mission with a rich description and move it to `approved` so AgentCore generates the plan. Follow steps 1--4 to ground yourself, then jump to "Mode 2".

Mode 1 is the default and the bulk of this skill. The steps below are Mode 1 unless noted.

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

**Testing discipline (mandatory in every code-touching task spec)** -- when a todo creates or changes an endpoint, MCP tool, or any behavioral code, its `spec.constraints` MUST require the owning agent to:

1. **Respect the existing test structure.** Add a clean new regression test OR adjust the existing tests -- match the project's test layout and conventions. Never leave an endpoint, tool, or behavior untested.
2. **Prove each behavioral claim RED then GREEN.** Every behavioral claim needs a test that fails BEFORE the change and passes AFTER it; the task must state the before/after evidence. A test written after the fix that never ran red is not evidence.
3. **Consult the testing SOPs FIRST.** Before writing tests, call `ch_list_sops` and `ch_read_sop` for the relevant ones (e.g. `definition-of-done-dev-dogfood`, `release-readiness-gate`, `pre-deploy-regression`, `api-contract-sync`) to learn the actual test flow. Do not act from memory on test or deploy flow. Cite the SOP as a `DOC` reference on the task.
4. **Cover new MCP tools and REST endpoints in `api-tests`.** For a new MCP tool or REST endpoint specifically, register/cover it in the project's `api-tests` system (release scorecard tool sweep + hurl contract coverage) IN ADDITION TO unit tests -- not instead of them.

Write these as explicit `constraints` and `edge_cases` on each affected todo so the requirement travels with the task, and add a dedicated test/verification todo (`role: "test"`, `depends_on` the implementation) where the coverage is substantial.

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

This lands the mission at status `execute` with the Weaver plan marked `ready` -- it is settled and ready to run. It does NOT trigger AgentCore generation: because you authored the plan, there is nothing to "process." Point the team straight at execution (step 9).

**WARNING -- the modes are mutually exclusive per mission.** Never call `ch_create_mission_with_plan` and then move the same mission to `approved`. Setting status `approved` fires the AgentCore pipeline, which regenerates and OVERWRITES your hand-authored plan. If you authored the plan here, leave it at `execute` and run it. If you want AgentCore to generate the plan, use Mode 2 from the start and do NOT hand-author.

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

## Mode 2 -- complex / AgentCore-generated

Use this when the mission is large, fuzzy, or under-specified -- when you want AgentCore to do the research, write the mission docs, and GENERATE the phased Weaver plan rather than authoring it by hand. Do NOT hand-author the plan in this mode.

Still do steps 1--4 first: connect, research, and review the codebase enough to write a strong, well-grounded description. The quality of what AgentCore generates is bounded by the description you give it -- invest here rather than in task specs.

1. **Create the mission with a rich description.** Call `ch_create_mission(title, description, project_id, workspace, priority, goals=[...])`. Make the `description`/`explanation` thorough: the problem, the desired outcome, the constraints, the relevant repos and areas of the codebase, and any OCXP findings or references you gathered in steps 2--4. Include the SMART goals. This description is the brief AgentCore researches against.

2. **Move it through the lifecycle to trigger generation.** Set the mission status to `review`, then to `approved`, via `ch_update_mission(mission_id, status="approved", ...)`. Setting status `approved` is what fires the AgentCore pipeline (`prepare_weaver_plan`): it gathers context, researches, writes the mission docs, and generates the phased Weaver plan.

3. **Run and review.** After generation, the plan can be run/executed via AgentCore and viewed in Obsidian. Review the generated docs and plan before execution.

Do NOT also call `ch_create_mission_with_plan` for this mission -- that is Mode 1, and mixing the two overwrites work (see the warning in step 8).

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
- Every code-touching task carries testing discipline in its `constraints`: existing test structure respected, each behavioral claim RED-before/GREEN-after with stated evidence, testing SOPs (`ch_list_sops`/`ch_read_sop`) consulted first, and new MCP tools/REST endpoints covered in `api-tests` (scorecard sweep + hurl contract) on top of unit tests.
- Pass `project_id` and `workspace` on every call, including the final `ch_create_mission_with_plan`.
- Pick ONE mode per mission. Mode 1 (`ch_create_mission_with_plan`) lands execute-ready with your hand-authored plan and skips AgentCore. Mode 2 (rich description -> `ch_update_mission` status `approved`) lets AgentCore generate the plan. Never move a Mode 1 mission to `approved` -- it regenerates over your plan.
- Run `ch_ocxp_diff` per agent branch after implementation to verify the structural change matches the task spec.
