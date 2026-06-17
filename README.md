# ContextHub Marketplace

Plugin marketplace for ContextHub tools.

## Plugins

### OCXP (`ocxp/`)

Code intelligence plugin for Claude Code powered by OCXP (Open Context eXploration Protocol).

**Skills:**
- `ocxp:plan` -- Implementation planning with code graph intelligence, reference validation, and compliance checking
- `ocxp:explore` -- Codebase navigation using semantic code graph
- `ocxp:analyze` -- Code quality auditing (dead code, anti-patterns, test coverage)

**Agents:**
- `code-navigator` -- Deep codebase exploration and architecture analysis

**MCP Tools:** 19 tools including route, search, plan, spec, validate, compliance, topology, constraints, and more.

### ContextHub (`contexthub/`)

Project management and context discovery plugin powered by ContextHub Brain API.

**Skills:**
- `contexthub:discover` -- Smart context discovery with semantic search and RAG
- `contexthub:mission` -- Mission management (list, create, update, track)
- `contexthub:status` -- Project health check and compass briefing

**Agents:**
- `researcher` -- ContextHub-aware research agent for investigating questions

**MCP Tools:** 14 tools for projects, missions, memos, repos, context discovery, and sessions.

## Installation

```bash
claude plugin add contexthub-md/contexthub-marketplace
```

## Requirements

**OCXP plugin:**
- `OCXP_MCP_API_KEY` -- API key for the OCXP engine
- `OCXP_PROJECT_ID` -- Project identifier for your indexed codebase

**ContextHub plugin:**
- `CONTEXTHUB_API_URL` -- Brain API URL (defaults to https://dev-api.contexthub.md)
- Authentication via Cognito OAuth (browser login on first use)
