---
name: discover
description: General semantic search / RAG over THIS project's knowledge base (indexed repos + docs). Use when you need to find relevant code, docs, or project context, or the user asks how something works in their project. Lane vs siblings -- use `/contexthub:kb` instead for our specific indexed reference/library repos (Strands, EMQX, etc.); use `/contexthub:research` instead for multi-source incl. external library docs (Context7) and the web (Tavily); use `ch_search_memory` instead to recall past decisions.
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
- For web search, set `provider: 'tavily'`
- For library documentation, set `provider: 'context7'`
- For specific content types, use `content_type`: code, docs, or visual

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
- Use `ch_search_memory` for past decisions related to the query

## Examples

```
/contexthub:discover how does authentication work?
/contexthub:discover what error handling patterns exist in the API?
/contexthub:discover database migration process
/contexthub:discover latest React docs (uses Context7 provider)
```
