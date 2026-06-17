---
name: analyze
description: Audit code quality, find dead code, check test coverage, identify architectural violations, or assess codebase health using OCXP graph intelligence. Use when the user asks to analyze code quality, find dead code, check coverage, audit architecture, or review codebase health.
---

# Codebase Analysis with ContextHub

Run comprehensive analysis using OCXP's graph-based code intelligence. All analysis is deterministic (no LLM) and based on structural graph properties.

## Prerequisites

An active project with indexed repositories is required. If you get OCXP_UNAVAILABLE or NO_PROJECT, run `/contexthub:connect` first.

## Workflow

Given: "$ARGUMENTS" (focus area, or empty for full analysis)

### 1. Orient and check health

Call `ch_ocxp_warmup` for codebase orientation, then `ch_ocxp_health` to check engine health. Use `ch_get_index_status` to verify the index is current.

If the index is stale or missing entities, suggest running `ch_trigger_index` before proceeding.

### 2. Run targeted analysis

Based on the focus area, run the relevant tools. Use `output_mode: "summary"` for initial triage, `"default"` for structured detail. This prevents overflow on large codebases.

**Code quality** -- `ch_ocxp_analyze`:
- Categories: `"dead_code"`, `"legacy"`, `"anti_patterns"`, `"infra_security"`, or `"all"`
- Returns findings with confidence scores and file locations
- Use `min_confidence` to filter noise (default 0.5)
- Use `path_filter` to scope to a specific directory (e.g. `"src/api/"`)

**Research gaps** -- `ch_ocxp_gap_analysis`:
- Discovers CODEBASE, CONTEXT, and DATABASE gaps
- Returns focus areas, key entities, and execution tiers
- Pure graph analysis (~5ms), no LLM

**Architecture** -- `ch_ocxp_constraints`:
- Naming conventions and semantic suffix patterns (*Service, *Repository)
- Module boundaries and violations
- Architectural rules discovered from codebase patterns

**Findings triage** -- `ch_ocxp_analyze_findings`:
- Prioritized, deduplicated view of analysis results

**Orphan detection** -- `ch_ocxp_orphan_scan`:
- Finds unreferenced entities and dead subgraphs

### 3. Synthesize findings

Organize by priority:

1. **Critical** (high confidence, high impact): Dead code in hot paths, anti-patterns in core modules, missing tests for critical flows
2. **Warnings** (medium confidence or impact): Legacy patterns, naming violations
3. **Suggestions** (low priority): Style inconsistencies, minor gap areas

For each finding, include: file path, entity name, confidence score, and suggested action.

### 4. Cross-reference

Use `ch_ocxp_references` on flagged entities to assess blast radius. Use `ch_ocxp_communities` to identify which subsystems are most affected.

## Quick reference

| Analysis | Tool | Key params |
|----------|------|------------|
| Dead code | `ch_ocxp_analyze` | `categories: "dead_code"`, `output_mode`, `path_filter` |
| Anti-patterns | `ch_ocxp_analyze` | `categories: "anti_patterns"`, `output_mode`, `path_filter` |
| Legacy code | `ch_ocxp_analyze` | `categories: "legacy"`, `output_mode`, `path_filter` |
| Infra security | `ch_ocxp_analyze` | `categories: "infra_security"`, `output_mode` |
| Research gaps | `ch_ocxp_gap_analysis` | `mission`, `output_mode`, `path_filter` |
| Naming rules | `ch_ocxp_constraints` | `scope`, `constraint_type` |
| Orphans | `ch_ocxp_orphan_scan` | `output_mode` |
| Subsystems | `ch_ocxp_communities` | `output_mode`, `max_output_chars` |
| Index health | `ch_get_index_status` | -- |

## Examples

```
/contexthub:analyze
/contexthub:analyze dead code in src/api
/contexthub:analyze architecture violations
/contexthub:analyze infra security
```
