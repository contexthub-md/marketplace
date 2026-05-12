---
name: analyze
description: Use when auditing code quality, finding dead code, checking test coverage, identifying architectural violations, discovering research gaps, or assessing codebase health. Requires OCXP MCP tools to be available.
---

# Codebase Analysis with OCXP

Run comprehensive analysis using OCXP's graph-based code intelligence. All analysis is deterministic (no LLM) and based on structural graph properties.

## Workflow

Given: "$ARGUMENTS" (focus area, or empty for full analysis)

### 1. Orient and check health

Call `ocxp_warmup` for codebase orientation, then `ocxp_status` to check index health.

If status shows stale files or missing entities, suggest running `ocxp_index` with `path: "."` before proceeding.

### 2. Run targeted analysis

Based on the focus area, run the relevant tools:

**Code quality** -- `ocxp_analyze`:
- Categories: `"dead_code"`, `"legacy"`, `"anti_patterns"`, or `"all"`
- Returns findings with confidence scores and file locations
- Use `min_confidence` to filter noise (default 0.5)

**Test quality** -- `ocxp_test_quality`:
- Metrics: test density, structural coverage, mock detection, shallow test detection
- Identifies untested code paths and over-mocked tests

**Research gaps** -- `ocxp_gap_analysis`:
- Discovers CODEBASE, CONTEXT, and DATABASE gaps
- Returns focus areas, key entities, and execution tiers
- Pure graph analysis (~5ms), no LLM

**Architecture** -- `ocxp_constraints`:
- Naming conventions and semantic suffix patterns (*Service, *Repository)
- Module boundaries and violations
- Architectural rules discovered from codebase patterns

### 3. Synthesize findings

Organize by priority:

1. **Critical** (high confidence, high impact): Dead code in hot paths, anti-patterns in core modules, missing tests for critical flows
2. **Warnings** (medium confidence or impact): Legacy patterns, naming violations, shallow tests
3. **Suggestions** (low priority): Style inconsistencies, minor gap areas

For each finding, include: file path, entity name, confidence score, and suggested action.

### 4. Cross-reference

Use `ocxp_references` on flagged entities to assess blast radius. Use `ocxp_community` to identify which subsystems are most affected.

## Quick reference

| Analysis | Tool | Key params |
|----------|------|------------|
| Dead code | `ocxp_analyze` | `categories: "dead_code"` |
| Anti-patterns | `ocxp_analyze` | `categories: "anti_patterns"` |
| Legacy code | `ocxp_analyze` | `categories: "legacy"` |
| Test coverage | `ocxp_test_quality` | (no required params) |
| Research gaps | `ocxp_gap_analysis` | `mission_context` optional |
| Naming rules | `ocxp_constraints` | (no required params) |
| Index health | `ocxp_status` | (no required params) |
