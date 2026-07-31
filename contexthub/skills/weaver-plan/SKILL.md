---
name: weaver-plan
description: Author a Weaver Hub Manager-mode mission plan tuned to how Weaver actually executes (goal-focused phases, design->checkpoint->implement, inbox-driven evidence-gated todos) and land it so Weaver picks it up over MQTT. Use when the target runner is Weaver Hub specifically, when dogfooding work through Weaver, or the user says "create a Weaver mission", "author a Weaver Manager-mode plan", "make this a Weaver plan". Lane vs siblings -- use `/contexthub:mission-forge` for GENERIC ContextHub mission creation (idea->mission, incl. AgentCore Mode 2); use THIS skill for Weaver-Hub-specific authoring (goal-focus rationale, the Weaver schema traps, the inbox/evidence/rehydrate execution model). Use `/contexthub:mission` for CRUD, `/contexthub:mission-dev` for git branch setup, `/contexthub:plan` for OCXP blast-radius that FEEDS this skill.
---

# Authoring Weaver-Executable Mission Plans

Turn a goal (roadmap item, spec, feature) into a mission plan that Weaver Hub executes end to end.
The output is either a **local YAML** (`plans/*.yaml`, dev shortcut) or a **Brain-landed plan** via
`ch_create_mission_with_plan` (production path -- flows over MQTT and exercises the whole pipeline).

## Lane vs `mission-forge`

`mission-forge` is the GENERIC "idea -> executable ContextHub mission" pipeline (research, OCXP,
reference validation, SMART goals, and either hand-authored or AgentCore-generated plans). Prefer it
for general mission creation. Use **`weaver-plan`** when the runner is **Weaver Hub specifically** and
you need the things `mission-forge` does not encode:

- **Goal-focused Manager-mode authoring and WHY** (rigid step-scripts make the PM fake "done").
- The **design -> HOLD-for-PASS checkpoint -> implement** phase pattern.
- **Weaver schema truth** (verify against current code): `execution_target` is Brain-side and is
  **ignored by Weaver's loader**; a per-todo model tier must ride in the todo **`metadata`** bag, not
  a typed field. (`mission-forge` tells you to populate `execution_target` -- for a Weaver run that
  field does nothing today.)
- The **inbox-driven / evidence-gated / re-hydrate-from-SSOT** execution model you must author to.

The two share `ch_create_mission_with_plan` and the OCXP-grounding step; when in doubt, forge the
mission with `mission-forge` and apply this skill's Weaver-specific rules to the phases/todos.

## Two ways to land a plan -- pick deliberately

| Path | How | What it tests | When |
|------|-----|---------------|------|
| **Local YAML** | write `plans/x.yaml` -> `start_mission(path)` | orchestrator only; **bypasses** Brain/DynamoDB/mqtt-bridge/retained-plan/context-bundles | fast iteration on orchestrator/FSM logic |
| **Brain-landed (preferred for dogfooding)** | `ch_create_mission_with_plan(...)` -> Brain writes DynamoDB -> mqtt-bridge republishes retained `weaver/{ws}/state/{mid}/plan` -> Weaver `mqtt/inbound` -> `load_from_plan_state` -> Kanban -> `mission_action(mid,"execute")` | the COMPLETE flow: retained hydration, QoS-1 plan echo, `execution_mode` over the wire, context bundles, evidence gate | validating the real system; any dogfood mission |

If the intent is "also test the complete flow," use the Brain-landed path. That is the dogfood loop.

## The one rule that dominates plan quality: GOAL-FOCUSED, not a task script

Write each phase as **GOAL + acceptance_criteria + hard guardrails**, and let the Manager-mode PM
own decomposition, delegation, and ordering. Do NOT pre-write imperative step-by-step `spec` blocks
("create config.rs with X, add crate Y, then...").

**Why (live-observed, 2026-07-18 voice mission):** the PM did its best work at goal-judgment moments
(refused wasteful cleanup on a docs-only phase, refused the wrong AWS account, held at real
checkpoints). It over-ran exactly where the plan was over-specified, and a rigid "complete this exact
todo" framing nudged it toward *reporting done* rather than *achieving the goal* -- it once fabricated
a hardware PASS. Friction correlated with rigidity; good judgment correlated with goal-latitude.

**How to apply:**
- Phase = `goal` (outcome) + `acceptance_criteria` (how we know) + guardrails.
- `file:line` go in `references:` as **starting hints the PM verifies**, never as a script. If a ref
  drifted, the PM adapts to hit the criteria.
- A todo `spec` says "meet the phase acceptance criteria; you own the mechanism" -- it does not
  enumerate edits.
- Keep HARD specifics ONLY where correctness is non-negotiable (guardrails, not steps): AWS
  account/region, "one brain / no duplicated guardrails", exact verified API findings, no-emoji /
  no-Claude-trailer, `cargo check` green, commit-per-phase.
- **Hard-gate exception:** access/safety gates (e.g. a P0 "verify AWS + model access" gate) still
  need tight, specific constraints -- goal-latitude there risks wandering onto the wrong account.
  Hybrid, tilted goal-ward.

## Mixed development: goal-based vs task-based phases (declare `completion` per phase)

Every phase declares HOW it proves done, via `completion` (default `task_list` = today's behavior):

- **`completion: goal_gated`** -- the phase is done ONLY when its Definition-of-Done gate passes.
  Use for outcome-shaped work ("the roll-up Lambda corrects drift on dev"). Write a REQUIRED `goal`
  plus `acceptance_criteria` where each item is, wherever possible, **machine-verifiable** (a command
  + expected exit, a file check, a commit-ancestor) -- not prose the agent grades itself on. The
  engine runs the gate; the agent CANNOT self-declare the phase complete.
- **`completion: task_list`** -- the phase is done when all its todos are individually complete on
  their own evidence (`report_todo_complete` commit gate). Use for concrete, known-shape work
  (a docs phase, a mechanical refactor with a fixed edit list).

**Why the split (live-observed):** self-graded "done" is how `weaver-02d2080b` reported complete
while its dogfood-on-dev criteria were never verified. Goal-gated phases make "done" provable, not
asserted. Declare the style explicitly -- do not rely on inference (a task-list phase may still
carry a descriptive goal).

**A single phase mixes todo types** regardless of style. The types are existing fields, not a new
`kind`: standard todo (default); a **test** todo = a todo whose acceptance item is a run command;
**hitl** = `ownership_type: human` (statically human-owned) or a todo the agent marks `blocked`
at runtime via `request_human_assist` (surfaces the "action needed" + alarms); **weaved** =
`task_type: weaved` (simplify/coderabbit/push).

**`/goal` DRIVES, the gate DECIDES.** Encourage the PM to use Claude Code's `/goal` to keep
converging toward the acceptance criteria without re-prompting -- but `/goal` reads the transcript,
so it is a convergence aid ONLY. The machine DoD gate is the sole authority on completion; a phase
advances (pull next task from inbox) only when the gate passes, else it returns to the work.

## The proven phase pattern: design -> human checkpoint -> implement

Every non-trivial mission follows this shape (exemplar:
`weaver-hub/.workplaces/.../plans/2026-07-19-weaver-hardening-p0p1-test.yaml`):

1. **P0 design (role: architect, model: Fable/Opus).** Produce the design doc P1 builds against.
   Output is a doc in `docs/`, **no production code**. Acceptance criteria are about the doc's
   completeness and correctness.
2. **P0.x human checkpoint (role: tester, `depends_on: [P0.1]`).** A HOLD-for-explicit-PASS todo.
   Spec: "Do NOT self-approve. Post a concise summary and HOLD for an explicit PASS or change
   requests. Never claim approval that was not given." This is the HITL gate that stops
   "goal achieved" from being self-declared.
3. **P1+ implement (role: rust-dev / frontend-dev, model: Sonnet, `blocked_by: [P0]`).** Achieve the
   acceptance criteria, implementing against the signed-off doc. Ends `cargo check` green + commit.
4. **Deploy + dogfood as its OWN phase, gated behind all code landing (`blocked_by:` every
   implement phase).** If any acceptance criterion needs a LIVE dev deploy to verify (e.g.
   "dogfood C1/C2 on dev"), do NOT attach it to the implement todos. Give it a separate phase that
   runs once, after all code is merged to dev. Otherwise each fix triggers its own PR -> merge ->
   redeploy cycle and the mission cascades PRs mid-run (weaver-02d2080b interleaved implement with
   dogfood and cascaded four PRs, 286-289, each with a redeploy + a human wait). One deploy cycle
   at the end is cheaper and clearer. (See the runtime "batch the deploy" principle -- the plan is
   where you make it structurally impossible to interleave.)

## Model-tier discipline (budget) -- assign per todo by altitude

Sonnet is good enough for ~99% of engineering **if context is validated first**; reserve the
expensive tier for the "is this correct and complete?" layer.

- **Opus / Fable** -> design, context validation, adversarial review, evidence-gate/spec design.
- **Sonnet** -> engineering execution (Rust/Svelte, tests, mechanical refactors, terraform).
- **Haiku** -> cheap mechanical sweeps (grep, file moves, status checks).

**Mechanism trap (verify against current code):** model is chosen **per execution mode** in
`weaver-hub/src-tauri/src/settings.rs` (`claude_model`, `claude_model_team`, `claude_model_manager`,
`claude_model_advisor`) via `workspace::modes::*::launcher_model` -- **NOT per todo** yet. Until a
per-todo model field lands, approximate via mode (Manager PM = Fable, executor = Sonnet, advisor =
Fable). If you set a per-todo model in the plan, put it in the todo `metadata` bag -- the MQTT wire
shape (`PlanTodo` in `mqtt/types.rs`) carries `metadata`, not a typed model field. **`execution_target`
in the MCP schema is Brain-side and is currently ignored by Weaver's loader** -- do not rely on it.

## Schema

### Local YAML (`mission::loader::load_from_yaml`)
```yaml
mission_id: "unique-id"        # reusing an id can trigger stale-state; use a fresh one
title: "..."
execution_mode: manager        # single | team | manager
repos:
  - repo_url: "https://github.com/Org/repo.git"
    branch: main
phases:
  - id: P0
    name: "..."
    order: 1
    blocked_by: []             # phase-level gate
    completion: goal_gated     # goal_gated | task_list (default task_list)
    goal: >
      The OUTCOME, in prose. REQUIRED for goal_gated phases.
    acceptance_criteria:       # DoD. Each item prose OR machine-verifiable:
      - "Prose fallback: human/agent-judged criterion."
      - { check: command, run: "make predeploy-check", expect_exit: 0 }
      - { check: file_contains, path: "src/x.rs", contains: "fn foo" }
      - { check: commit_ancestor, repo: "contexthub-brain" }   # like report_todo_complete
    references:
      - "file.rs: starting hint the PM verifies, NOT a step"
    todos:
      - id: P0.1
        description: "short"
        role: architect          # architect|rust-dev|frontend-dev|reviewer|devops|tester...
        depends_on: []
        spec: |
          GOAL, not a script. "Meet the phase acceptance criteria; you own the mechanism."
        file_paths: []
        # metadata: { model: "bedrock:us.anthropic.claude-sonnet-4-20250514" }  # per-todo tier hint
```

### Brain-landed (`ch_create_mission_with_plan`)

**Read `../mission-forge/references/mission-plan-schema.md` before writing the payload.** It is the
code-verified field list for phases, todos, `spec`, `dod_gate`, and `ch_edit_mission_plan`, plus the
silent-drop behaviours you cannot see from the response. The local YAML above and the Brain payload
are NOT the same shape -- most notably the machine checks live in `dod_gate` (Brain) rather than
inline in `acceptance_criteria` (which is prose-only on the Brain side).

`phases: [{ name, goal, acceptance_criteria, completion, dod_gate, depends_on,
todos: [{ role, description, repo_id, repo_branch, task_type, ownership_type, spec:{...},
depends_on:[...] }] }]`. Structured `spec` maps to `TodoSpec` (name/location/spec_type/summary/inputs/
outputs/behavior/constraints/edge_cases/references) and drops any other key without erroring;
`references` are typed objects and belong INSIDE `spec`. `execution_mode` is carried through
`load_from_plan_state` (verified: loader.rs deserializes `execution_mode: "manager"`).

Traps that cost a mission each: `dod_gate` command is `{"check": "command", "run": "..."}` -- `command`
as the field name fails validation, and the failure orphans an already-created planless mission. Phase
ids are assigned `P{n}` by position, so any `id` you pass is ignored. A todo without `repo_id`
silently inherits the project's FIRST linked repo.

## Execution model the plan depends on (so author to fit it)

- **Inbox-driven, one todo at a time.** Orchestrator pushes ONE todo spec to the local MCP inbox;
  the agent calls `check_inbox` -> executes exactly that -> `report_todo_complete` -> `check_inbox`
  again. Agents must never self-assign work from the plan. Author todos as independently-deliverable
  units of goal.
- **Evidence-gated completion only.** A todo completes solely via `report_todo_complete` (an
  `ack_inbox` no longer completes anything). Completion needs real evidence (a backing commit;
  `verify_commit` checks SHA reachability). Bake "commit when criteria are met" into every spec.
- **Recovery = re-hydrate from SSOT.** On restart, Brain's retained plan re-arrives, the engine
  reloads and reconciles status against git ground truth, and the orchestrator re-pushes the current
  spec. No local persistence -- so a Brain-landed plan survives restarts; a cancelled mission must
  have its retained plan cleared or it re-hydrates as a ghost.

## Workflow

Given: `$ARGUMENTS` (a goal, roadmap item, spec path, or "mission N of <roadmap>").

1. **Orient.** `ch_get_memory_context` (project, active mission, decisions). Identify `project_id`
   and `workspace`.
2. **Ground the plan in real code (avoid hallucinated refs).** Run `/contexthub:plan` or
   `ch_ocxp_plan` + `ch_ocxp_standards_check` on the goal to get verified file references and blast
   radius. Fix or drop any reference that fails the standards check.
3. **Draft phases goal-focused.** Apply the design -> checkpoint -> implement pattern. Assign model
   tier per todo. Put hard specifics only in guardrails.
4. **Self-review against this skill's checklist** (below) before landing.
5. **Land it.**
   - Dogfood/full-flow: `ch_create_mission_with_plan(title, phases, project_id, scope, priority)`,
     then trigger execution (`mission_action(mid, "execute")` via the frontend, or the Kanban).
   - Fast local: write `plans/<date>-<slug>.yaml` and `start_mission(path)`.
6. **Read the plan back before declaring it landed.** `ch_get_mission_plan(mission_id, detail="full")`
   -- verify phase/todo counts, that each phase carries the `blocked_by` you intended, and that the
   specs still hold their content. Repair in place with `ch_edit_mission_plan` (partial `updates` are
   safe), but it cannot touch `goal`, `acceptance_criteria`, `completion`, `dod_gate`, or a todo's
   `repo_id` -- those mean recreating the mission.
7. **Record the decision.** `ch_record_decision(mission_id, decision_type="process")` capturing why
   the plan is shaped this way, so the dogfood loop accrues memory.

## Pre-land checklist

- [ ] Each phase has goal + acceptance_criteria + guardrails (not step scripts).
- [ ] `file:line` are in `references:` as hints, verified via OCXP standards-check.
- [ ] Design phases are docs-only; a HOLD-for-PASS human checkpoint gates implementation.
- [ ] Model tier assigned by altitude (validate=Opus/Fable, build=Sonnet, mechanical=Haiku).
- [ ] Hard guardrails present: AWS acct/region, no emojis, no Claude trailers, cargo-check green,
      commit-per-phase, Brain enum match (`in_progress`/`running`/`executing`).
- [ ] Every implement todo spec says "commit when acceptance criteria are met."
- [ ] Fresh `mission_id` (no id reuse).
- [ ] For full-flow: landed via Brain (`ch_create_mission_with_plan`), not just a local YAML.
- [ ] Brain payload checked against `../mission-forge/references/mission-plan-schema.md`: `dod_gate`
      uses `run`, `spec` has only its ten fields, `references` are typed objects inside `spec`, every
      todo names its `repo_id`, every phase after the first has `depends_on`.
- [ ] Plan read back with `ch_get_mission_plan` after landing; counts and specs verified.

## Examples

```
/contexthub:weaver-plan build mission 1 of the dogfood roadmap: model-tier budget engine
/contexthub:weaver-plan turn docs/superpowers/specs/2026-07-19-mission-rollup-adr.md into a Weaver plan
/contexthub:weaver-plan author a goal-focused manager-mode mission to harden the evidence gate
```
