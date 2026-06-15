---
name: explore
description: Explore a codebase using OCXP code intelligence -- navigate, search, and understand code structure. Use when the user asks to explore code, find where something is implemented, understand architecture, trace call chains, or navigate an unfamiliar codebase. Also use when the user says "show me the code for X" or "how does X work in the code".
---

# Code Exploration with ContextHub

Navigate and understand codebases using OCXP code intelligence -- semantic search, graph queries, and architecture analysis.

## Prerequisites

An active project with indexed repositories is required. If you get OCXP_UNAVAILABLE or NO_PROJECT, run `/contexthub:connect` first.

## Workflow

Given: "$ARGUMENTS" (what to explore -- a task, concept, file, or question)

### 1. Orient

Call `ch_ocxp_warmup` to load the code graph. This returns repository stats and structure in ~150 tokens. Always do this first.

### 2. Navigate

Choose the right tool based on what the user needs:

- **Task-based** ("find the files I need to add auth"): `ch_ocxp_route(task)` -- returns ordered waypoints
- **Concept search** ("where is the database connection pool?"): `ch_ocxp_search(query)` -- semantic search over embeddings
- **Graph query** ("all classes implementing Repository"): `ch_ocxp_query(query)` -- traverses entity relationships
- **Exact string** ("find all uses of AUTH_SECRET"): `ch_ocxp_grep(pattern)` -- literal text search
- **File lookup** ("find repository.py"): `ch_ocxp_find_file(name)` -- by filename

### 3. Drill Down

Once you find relevant entities:

- `ch_ocxp_entity(id)` -- get full details of a specific entity
- `ch_ocxp_file_read(path)` -- read the actual source code
- `ch_ocxp_references(id)` -- who calls/uses/imports this entity
- `ch_ocxp_zoom(uri)` -- follow zoom_in/zoom_out links for progressive exploration

### 4. Understand Architecture (if needed)

For broader understanding:

- `ch_ocxp_topology` -- service dependency maps
- `ch_ocxp_communities` -- detect subsystems and module boundaries
- `ch_ocxp_dependency_graph` -- dependency relationships
- `ch_ocxp_infra` -- infrastructure diagrams from Terraform

### 5. Report

Summarize what you found: key files, relationships, and patterns. If the user has a task, recommend which files to modify and in what order.

## Examples

```
/contexthub:explore how does authentication work
/contexthub:explore find the API route handlers
/contexthub:explore architecture overview
/contexthub:explore trace the request flow from API gateway to database
```
