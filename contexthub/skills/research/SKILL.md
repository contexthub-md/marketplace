---
name: research
description: BROADEST research -- multi-source across project KB + EXTERNAL library docs (Context7) + the WEB (Tavily), all through ContextHub. Use when the user needs to research a topic across sources, compare approaches, look up external/library API references, or says "research this", "find docs for", "what does the internet say about", "look up". Lane vs siblings -- use `/contexthub:kb` instead when it's purely our own indexed reference repos; use `/contexthub:discover` for general project-only knowledge search.
---

# Multi-Source Research with ContextHub

Research any topic using three sources in parallel: project knowledge base (Bedrock KB), library documentation (Context7), and web search (Tavily). All accessed through `ch_discover_context`.

## When to Use

- You need to understand a library/framework before using it
- The user asks "how does X work" and X could be in docs, code, or the internet
- You're implementing something and need reference material
- You want to compare what the docs say vs what the code does vs what the community recommends

## Workflow

Given: "$ARGUMENTS" (topic, question, or library name to research)

### 1. Fan Out: Three Parallel Searches

Run all three in parallel for comprehensive coverage:

**Project Knowledge Base** (Bedrock KB -- reference repos like Strands, EMQX, AG-UI):
```
ch_discover_context(query=<query>, content_type="docs", include_answer=true, max_results=5)
```

**Library Documentation** (Context7 -- React, FastAPI, Prisma, any library):
```
ch_discover_context(query=<query>, context_type="docs-library", max_results=5)
```

**Web Search** (Tavily -- blog posts, Stack Overflow, GitHub discussions):
```
ch_discover_context(query=<query>, provider="tavily", max_results=5)
```

### 2. Synthesize

Combine findings from all three sources into a coherent answer:

- **KB results**: What do our reference docs say? (most authoritative for project-specific context)
- **Library docs**: What does the official documentation say? (most accurate for API details)
- **Web results**: What does the community recommend? (most current for best practices)

Highlight where sources agree and where they conflict. Note which source is most relevant for the specific question.

### 3. Cross-Reference with Code

After gathering research, connect it to the actual codebase:

```
ch_ocxp_search(query=<topic>)
ch_ocxp_grep(pattern=<specific API/function from research>)
```

This shows how the researched patterns are actually used in the project.

### 4. Present

Structure the answer as:
1. **Direct answer** (synthesized from all sources)
2. **From project docs**: key findings from KB
3. **From library docs**: official API/usage details
4. **From web**: community insights, gotchas, best practices
5. **In our code**: where/how we use this pattern

## Source Selection Guide

Not every query needs all three sources. Pick based on the question:

| Question Type | Best Source | Tool Call |
|--------------|------------|-----------|
| "How does our MQTT setup work?" | Project KB | `ch_discover_context(query, content_type="docs")` |
| "What params does FastMCP accept?" | Library docs | `ch_discover_context(query, context_type="docs-library")` |
| "Best practices for X in 2026" | Web | `ch_discover_context(query, provider="tavily")` |
| "How should we implement X?" | All three | Fan out all three in parallel |

## Examples

```
/contexthub:research Strands agent tool creation patterns
/contexthub:research EMQX shared subscription load balancing
/contexthub:research FastMCP session state management
/contexthub:research best practices for Rust async error handling
/contexthub:research AG-UI protocol event streaming
```
