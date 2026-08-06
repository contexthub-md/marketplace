---
name: mission-forge
description: Forge a raw idea into a complete, executable ContextHub mission -- research it, review the codebase with OCXP, validate every reference, then create the mission with SMART goals, research docs, phases, specced todos, agent assignments, and worktree setup in one call. Use when the user says "forge a mission", "turn this idea into a mission", "plan and create a mission for X", "scope this into tasks and build the mission", or hands you a feature/refactor idea and wants a ready-to-execute mission plan (not just a plan document).
---

# Mission Forge

Turn an idea into a complete, executable ContextHub mission. This skill runs the full pipeline -- research, OCXP codebase review, reference validation, SMART goal synthesis, task breakdown, agent + worktree assignment -- then creates the entire mission (goals, docs, phases, todos, references) in ONE call via `ch_create_mission_with_plan`.

Where `/contexthub:plan` produces a plan you read, and `/contexthub:mission` creates an empty mission shell, mission-forge does both and more: it emits a fully-specced, dependency-ordered, agent-assigned mission that a team can start executing immediately.

There are TWO ways to land a mission, and you pick one per mission (they are mutually exclusive -- see the warning in step 8):

- **Mode 1 -- Simple / on-the-spot (default).** You research and author the plan yourself, then land it settled and execute-ready in ONE call with `ch_create_mission_with_plan`. This is the whole workflow below and is the right path when you can already specify the phases and tasks with confidence.
- **Mode 2 -- Complex / AgentCore-generated.** You create the mission WITHOUT a plan and let AgentCore analyse it -- research, docs, and the phased Weaver plan. One call too: `ch_create_mission(..., pipeline_mode="plan")` (stops at `review`) or `pipeline_mode="process"` (runs straight through to a generated plan). Use this when the mission is large, fuzzy, or needs deep research before anyone can name the tasks. See "Mode 2" below.

## Read the schema before you call anything

`references/mission-plan-schema.md` is the code-verified schema for both modes. **Read it before
your first create call.** Do NOT infer the payload shape from the tool docstrings -- they are shorter
than the truth, and the gaps are silent: unknown keys are dropped without error, `dod_gate` command
uses `run` (not `command`), a todo-level `references` is never read, `spec` has exactly ten fields,
`repo_id` defaults to the project's first linked repo, and a plan validation error leaves an orphan
planless mission behind. Guessing costs a mission and loses your task specs.

## Prerequisites

An active project with indexed repositories is required. If you get `OCXP_UNAVAILABLE` or `NO_PROJECT`, run `/contexthub:connect` first. Research still works without OCXP, but you cannot validate references or assess blast radius -- do not forge a mission on an unindexed project.

## Workflow

Given: "$ARGUMENTS" (an idea, feature request, refactor goal, or problem statement)

### 0. Choose the mode

After orienting (step 1) and enough OCXP review to judge scope, decide which mode fits:

- **Can you already specify the phases and tasks with confidence after OCXP review?** -> **Mode 1**: author the plan yourself and land it with `ch_create_mission_with_plan` in one call (execute-ready). Follow steps 1--9.
- **Is it large, fuzzy, or does it need deep research first?** -> **Mode 2**: create the mission with a rich description and `pipeline_mode="plan"` (or `"process"`) so AgentCore analyses it and generates the plan. Follow steps 1--4 to ground yourself, then jump to "Mode 2".

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

Record the OCXP entity IDs and file paths you touch -- you cite them as `spec.references[]` (type `spec`/`file` with the entity path as `target`).

### 4. Validate every external and internal reference

Do NOT proceed on failed references -- a hallucinated path wastes an agent's entire task.

- **Internal**: if any `ch_ocxp_standards_check` reference FAILS, use `ch_ocxp_search` to find the correct path, fix it, and report `Corrected: X -> Y` to the user.
- **External**: confirm any library/API/CLI/AWS usage against current docs via `ch_discover_context(context_type="docs-library")`. Note any corrections.

### 5. Synthesize research docs

Assemble the findings + OCXP results + decisions into markdown documents. These become the `docs=[]` argument (the tool writes them via the same path convention as `/contexthub:context`):
- `docs/research/<topic>.md` -- KB + library + web findings with source refs.
- `docs/ocxp-findings.md` -- validated entities, blast radius, corrected paths, audit score.

Each doc is `{path, content}`. Reference these docs from tasks (type `research`/`doc` with the doc path as `target`) so every agent lands on the same source of truth. If your `docs` list has no `MISSION.md`, one is auto-templated from title + description + goals + a phase summary (pure templating, no LLM).

### 6. Parse into SMART goals and exact tasks

**Goals** -- write them Specific, Measurable, Achievable, Relevant, Time-bound. Vague goals produce vague tasks.

**Phases and todos** -- break the plan into phases, each with ordered todos. Field-by-field truth is in
`references/mission-plan-schema.md`; the load-bearing points:

- `role` -- the kind of agent that owns it (e.g. `backend`, `infra`, `frontend`, `review`, `test`).
- `repo_id` + `repo_branch` -- which repo and branch it develops on. **Always set `repo_id`**: omitting it silently defaults the todo to the project's FIRST linked repo.
- `spec` -- exactly ten fields: `{name, location, spec_type, summary, inputs, outputs, behavior, constraints, edge_cases, references}`. Any other key (`problem`, `root_cause`, `verification`, ...) is silently discarded -- fold that content into `summary` and `edge_cases`. Pull `behavior`/`constraints`/`edge_cases` from the OCXP spec and `ch_ocxp_constraints`.
- `spec.references[]` -- typed OBJECTS `{type, label, target, description?, section?}`; `type` is one of `file | url | kb_result | research | spec | doc | decision`. A bare string fails the whole call. Note there is no todo-level `references` key -- it is never read.
- `depends_on` -- express dependencies by task order/label, NOT by invented IDs (see Tips). At phase level this sets the phase gate; omit it and phases run unordered.
- `dod_gate` (per phase, with `completion: "goal_gated"`) -- the machine checks the engine runs. The command variant is `{"check": "command", "run": "...", "expect_exit": 0}`; `"command"` as the field name fails validation. Prose criteria go in `acceptance_criteria` (prose only) or a `{"check": "prose", "text": ...}` entry.
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
  execution_mode="single" | "team" | "manager",
  goals=[<SMART goals>],
  docs=[{path, content}, ...],
  phases=[{name, goal, acceptance_criteria:[...],
           completion:"task_list"|"goal_gated",
           dod_gate:[{check:"command", run:"...", expect_exit:0}],
           depends_on:["P1"],
           todos:[{role, description, repo_id, repo_branch,
                   task_type:"standard"|"weaved",
                   ownership_type:"agent"|"agent_human"|"human",
                   spec:{name, location, spec_type, summary, inputs, outputs,
                         behavior, constraints, edge_cases,
                         references:[{type, label, target, description}]},
                   depends_on, execution_target:{kind, ...}}]}],
  scope, workspace)
```

Returns `{mission_id, doc_paths, plan_version, phase_count, todo_count}`. Report these back to the user. The tool assigns canonical `P{n}` / `P{n}.{m}` task IDs and remaps your loose `depends_on` -- so the IDs in the result are authoritative.

This lands the mission at status `execute` with the Weaver plan marked `ready` -- it is settled and ready to run. It does NOT trigger AgentCore generation: because you authored the plan, there is nothing to "process." Point the team straight at execution (step 9).

**Then read the plan back -- always.** Call `ch_get_mission_plan(mission_id, detail="full")` (or per
phase to keep it small) and check phase/todo counts, every phase's `blocked_by`, and that the specs
still say what you wrote. Silent drops are invisible in the create response.

**If it returns `PLAN_ERROR`:** the mission and its docs were already written before the plan was
validated, so an orphan planless mission is now sitting at status `open`. Fix the payload, then reuse
or delete that orphan -- do not retry blind and leave a trail of them. Repair a landed plan with
`ch_edit_mission_plan` (partial `updates` are safe): the gating fields including `goal`,
`acceptance_criteria`, `completion`, `dod_gate`, and a todo's `repo_id` are all editable, and `action=`
adds/deletes/reorders phases and todos. See the schema reference for the full surface and the 422/409
it raises.

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

1. **Create the mission and start the pipeline in ONE call.** `ch_create_mission(title, description, project_id, workspace, priority, goals=[...], pipeline_mode="plan")`.
   - `pipeline_mode="plan"` runs the AgentCore mission pipeline (MISSION.md, research, docs) and stops at `review` for a human to approve -- the default choice, you see the research before a plan is generated.
   - `pipeline_mode="process"` continues straight into weaver-plan generation with no approve step. Use when you do not want a human gate mid-flight.
   - `pipeline_mode="open"` (the default) only registers the mission -- no AgentCore call, no analysis. Do not use it here.
   - `project_id` is REQUIRED for `plan`/`process`; the tool rejects up front rather than stranding the mission at intake.

2. **Write the description for the readiness gate, because it IS the brief.** AgentCore receives `"# {title}\n\n{description}"` and nothing else -- invest everything here: the problem, the desired outcome, the constraints, the relevant repos and areas of the codebase, and the OCXP findings and references from steps 2--4. AgentCore's input-readiness gate needs 4 of 6 checks (goals, title, description, content > 100 chars, impl-plan phases, `docs/implementation-plan.md`), so **always pass `goals` and a description well over 100 characters** -- that clears the gate at 4/6 on its own. A bare title plus one line scores 3/6 and generation stops.

3. **Poll, then review.** `ch_get_mission(mission_id)` reports `status` and `weaver_plan_status` (`generating -> gathering -> structuring -> storing -> ready | failed`). For `pipeline_mode="plan"`, approve when the research looks right -- `ch_update_mission(mission_id, status="approved")` fires plan generation. To (re)generate on a mission that already has content, call `ch_generate_mission_plan(mission_id)` directly. Review the generated docs and plan in Obsidian before execution.

Do NOT also call `ch_create_mission_with_plan` for this mission -- that is Mode 1, and mixing the two overwrites work (see the warning in step 8).

## Examples

```
/contexthub:mission-forge add rate limiting to the ask API
/contexthub:mission-forge migrate the docs KB from AOSS to S3 Vectors
/contexthub:mission-forge refactor the auth module into a shared crate
/contexthub:mission-forge build a webhook consumer that auto-indexes pushed branches
```

## Tips

- Read `references/mission-plan-schema.md` before the first create call. Every trap in it cost a real mission: `dod_gate` uses `run` not `command`; unknown `spec` keys vanish silently; `references` must be typed objects and must live inside `spec`; `repo_id` silently defaults to the first linked repo; a validation error orphans a planless mission.
- Always read the plan back with `ch_get_mission_plan` after creating. The create response reports counts, not content -- dropped specs are invisible until you look.
- Always run `ch_ocxp_standards_check` and `ch_ocxp_audit` before forging -- an unvalidated reference in a task spec becomes an agent's dead end.
- Cite OCXP entity IDs/paths in `spec.references[]` (type `spec`/`file`) so each agent starts from ground truth, not a re-derived guess. The wire values are lowercase; an unrecognised type is silently coerced to `file`.
- The LLM emits loose task ordering; `ch_create_mission_with_plan` assigns canonical `P{n}`/`P{n}.{m}` IDs and remaps `depends_on`. Refer to dependencies by order/label, never by invented IDs.
- One owner per FILE per worktree. Two agents editing the same file concurrently will collide -- serialize with `depends_on` or split the file boundary.
- Match model to cognitive demand in each task: Opus for architecture/review, Sonnet for spec-driven code, Haiku for mechanical work.
- Research docs are load-bearing: every task should reference at least one `research`/`doc` and one `spec`/`file`. A task with no references is under-specified.
- Every code-touching task carries testing discipline in its `constraints`: existing test structure respected, each behavioral claim RED-before/GREEN-after with stated evidence, testing SOPs (`ch_list_sops`/`ch_read_sop`) consulted first, and new MCP tools/REST endpoints covered in `api-tests` (scorecard sweep + hurl contract) on top of unit tests.
- Pass `project_id` and `workspace` on every call, including the final `ch_create_mission_with_plan`.
- Pick ONE mode per mission. Mode 1 (`ch_create_mission_with_plan`) lands execute-ready with your hand-authored plan and skips AgentCore. Mode 2 (`ch_create_mission` with `pipeline_mode="plan"`/`"process"`, or `ch_generate_mission_plan` on an existing mission) lets AgentCore generate the plan. Never move a Mode 1 mission to `approved` -- it regenerates over your plan.
- Run `ch_ocxp_diff` per agent branch after implementation to verify the structural change matches the task spec.
