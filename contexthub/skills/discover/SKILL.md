---
name: discover
description: Smart context discovery -- search project knowledge bases using semantic search or RAG. Use when you need to find relevant code, docs, or project context.
---

# Context Discovery with ContextHub

Search your project's knowledge base using ContextHub's semantic search and RAG capabilities.

## Workflow

Given: "$ARGUMENTS" (search query or question)

### 1. Search

Call `ch_discover_context` with the query.

- For factual lookups, use default settings (semantic search)
- For questions that need an answer, set `include_answer: true` (RAG mode)
- Scope to a project with `project_id` if you know which project to search

### 2. Review Results

Results include:
- **content**: Relevant snippets ranked by score
- **source**: Where the content came from
- **answer**: LLM-generated answer (only in RAG mode)
- **strategy_used**: Which search strategy was applied

### 3. Follow Up

- Use `ch_get_project` to understand the broader project context
- Use `ch_get_compass` for a project health overview
- Use `ch_list_missions` to see what work is in progress

## Examples

```
/contexthub:discover how does authentication work?
/contexthub:discover what error handling patterns exist in the API?
/contexthub:discover database migration process
```
