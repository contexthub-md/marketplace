---
name: plan
description: Plan features, refactors, or assess the impact of proposed changes before writing code, using OCXP code graph intelligence. Use when the user asks to plan a feature, plan a refactor, scope a change, or understand the blast radius of a modification.
---

# Implementation Planning with ContextHub

Generate implementation plans grounded in actual codebase structure using OCXP's route + spec generation. Plans are based on the code graph, not guesswork.

## Prerequisites

An active project with indexed repositories is required. If you get OCXP_UNAVAILABLE or NO_PROJECT, run `/contexthub:connect` first.

## Workflow

Given: "$ARGUMENTS" (feature request, refactor goal, or change description)

### 1. Orient

Call `ch_ocxp_warmup` for codebase orientation -- module tree, entry points, key types.

### 2. Generate plan

Call `ch_ocxp_plan` with the request. This is the most efficient tool -- it combines route + spec in one call:
- Returns ordered navigation waypoints AND a YAML implementation spec
- Use `mode: "modify"` for implementation tasks (default: "comprehend")
- Use `scope` to narrow to a subdirectory if the change is localized -- always combine with `focus_repo` to prevent cross-repo leakage
- Use `output_mode: "default"` to keep output structured (~8K chars) and prevent overflow

### 2b. Validate references

Extract all function names, file paths, and infrastructure references from the spec. Call `ch_ocxp_standards_check` to validate them against the actual code graph.

If any references FAIL:
1. Use `ch_ocxp_search` to find the correct path
2. Fix the reference in the plan
3. Report corrections to the user ("Corrected path: X -> Y")

Do NOT proceed with failed references -- they indicate hallucinated paths that will waste implementation time.

### 2c. Compliance check

Feed the spec into `ch_ocxp_audit` to verify it follows codebase rules and patterns.

Review the score:
- **Pass**: proceed to context analysis
- **Failures**: flag to user with specific checks that failed and why. Adjust the plan if needed.
- **Warnings**: note but proceed (usually means files will be created during implementation)

### 3. Understand context

- `ch_ocxp_topology` -- service-level dependencies affected by the change
- `ch_ocxp_communities` -- which subsystems are involved and their boundaries
- `ch_ocxp_constraints` -- naming conventions and architectural rules to follow

### 4. Assess impact

For each key entity in the plan:
- `ch_ocxp_references` -- what calls/imports/uses it? (blast radius)
- Check if modifications cascade through the dependency chain

### 5. Output structured plan

Present:

**Scope**: Which subsystems/communities are affected

**Files to modify** (ordered by dependency -- modify dependencies first):
- File path, what to change, why

**New files to create**:
- File path, purpose, which patterns to follow (from constraints)

**Impact analysis**:
- Entities affected by the change
- Downstream consumers that may need updates
- Cross-repo edges if applicable

**Constraints to follow**:
- Naming conventions from `ch_ocxp_constraints`
- Module boundary rules
- Existing patterns to match

**Risks and edge cases**:
- Breaking changes to public APIs
- Missing test coverage for affected paths
- Cross-subsystem dependencies

## Tips

- `ch_ocxp_plan` replaces 5-10 manual query+entity chains -- start there
- Always run `ch_ocxp_standards_check` after generating a plan -- LLMs hallucinate file paths
- Always run `ch_ocxp_audit` to verify the plan follows codebase rules
- For precise impact use `ch_ocxp_references` on the entity
- For large changes, use `scope` + `focus_repo` to plan subsystem by subsystem
- Check `ch_ocxp_diff` after implementation to verify structural changes match the plan

## Examples

```
/contexthub:plan add rate limiting to the API
/contexthub:plan refactor the auth module
/contexthub:plan what breaks if I change the User model
```
