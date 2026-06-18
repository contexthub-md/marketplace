---
name: kb
description: Navigate and query the project's OWN indexed reference repos (Strands, EMQX, AG-UI, etc.) -- RAG answers + cross-reference docs with code. Use when the user asks about library APIs, framework patterns, protocol specs, configuration guides, or says "check the docs", "what do the docs say", "find in the knowledge base", "KB search". Lane vs siblings -- use `/contexthub:research` instead when you need EXTERNAL library docs (Context7) or the web; use `/contexthub:discover` for general project-knowledge search not tied to reference repos.
---

# Project Knowledge Base Navigator

Search and query your project's reference documentation repos using semantic search and RAG. These are the REFERENCE-tagged repos in your project -- library docs, framework guides, protocol specs, and API references that provide context for development.

## Prerequisites

An active project with knowledge base repos is required. If you get NO_PROJECT errors, run `/contexthub:connect` first.

## Workflow

Given: "$ARGUMENTS" (a question, topic, or search query about docs/libraries/frameworks)

### 1. Understand the Query

Classify what the user needs:
- **Factual lookup**: "what is the EMQX authentication mechanism?" -- needs doc search
- **How-to**: "how do I create a Strands agent tool?" -- needs RAG answer
- **API reference**: "what parameters does X accept?" -- needs doc search + code cross-reference
- **Troubleshooting**: "why is my MQTT connection failing?" -- needs docs + code context

### 2. Search the Knowledge Base

**For factual lookups and browsing:**
```
ch_discover_context(query=<query>, content_type="docs", max_results=10)
```

**For questions that need a synthesized answer (RAG mode):**
```
ch_discover_context(query=<query>, include_answer=true, max_results=5)
```

RAG mode retrieves relevant doc chunks and generates a sourced answer. Use this when the user asks a question rather than just searching for a topic.

**For specific library documentation:**
```
ch_discover_context(query=<query>, context_type="docs-library")
```
This hits the Context7 provider for external library docs (React, FastAPI, Prisma, etc.).

### 3. Present Results

For each result, show:
- The relevant content snippet
- The source repo and file path
- A relevance score

For RAG answers, show:
- The generated answer
- The sources it drew from
- Key quotes from the docs

### 4. Cross-Reference with Code

After finding relevant docs, bridge to the codebase to show how the documented patterns are actually used:

```
ch_ocxp_search(query=<topic from docs>)
ch_ocxp_grep(pattern=<specific API/class/function from docs>)
```

This connects "what the docs say" with "how we actually use it" -- the most valuable part of a KB navigator.

### 5. Deep Dive (if needed)

For more context:
- `ch_discover_context(query=<follow-up>, include_answer=true)` -- ask follow-up questions
- `ch_ocxp_file_read(path=<file>)` -- read the actual source code using the documented patterns
- `ch_discover_context(provider="tavily", query=<query>)` -- search the web for additional context

## Common Knowledge Base Repos

Projects often include these types of reference repos:
- **Framework docs** (strands-agents/docs) -- how to build agents, tools, hooks
- **Infrastructure docs** (emqx/emqx-docs) -- MQTT broker config, authentication, clustering
- **Protocol specs** (ag-ui-protocol/ag-ui) -- API contracts, message formats, event schemas
- **Library docs** -- any library the project depends on

## Examples

```
/contexthub:kb how do I create a custom Strands agent tool?
/contexthub:kb EMQX authentication with JWT tokens
/contexthub:kb AG-UI protocol event types and message format
/contexthub:kb what MQTT QoS levels does EMQX support?
/contexthub:kb how to configure Strands agent memory
```
