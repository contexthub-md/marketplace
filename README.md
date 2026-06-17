# ContextHub Marketplace

Plugin marketplace for ContextHub -- project management, missions, context discovery, code intelligence, and knowledge base tools for Claude Code.

## Plugin

### ContextHub (`contexthub/`)

A single unified plugin powered by the ContextHub Brain API, with OCXP code intelligence built in.

**Skills:**

*Setup & connection*
- `contexthub:connect` -- Connect to a project (workspace, project, mission setup)
- `contexthub:import` -- Import a repository from GitHub
- `contexthub:resume` -- Resume work on a project or mission
- `contexthub:status` -- Project health check and compass briefing

*Code intelligence (OCXP)*
- `contexthub:explore` -- Navigate and understand a codebase using the code graph
- `contexthub:analyze` -- Audit code quality (dead code, anti-patterns, gaps, architecture)
- `contexthub:plan` -- Plan features/refactors with code graph intelligence and validation
- `contexthub:branch-search` -- Index and search a specific Git branch

*Context & knowledge*
- `contexthub:discover` -- Smart context discovery with semantic search and RAG
- `contexthub:research` -- Research questions using project context and knowledge base
- `contexthub:kb` -- Knowledge base management

*Missions & process*
- `contexthub:mission` -- Mission management (list, create, update, track)
- `contexthub:mission-dev` -- Start developing on a mission (branch checkout, indexing)
- `contexthub:sop` -- Create and manage SOPs (runbooks, deployment guides)
- `contexthub:sop-writer` -- Autonomous research-backed SOP writer

**Agents:**
- `code-navigator` -- OCXP-aware code navigation (call chains, topology, impact analysis)
- `researcher` -- ContextHub-aware research agent for investigating questions
- `sop-writer` -- Autonomous SOP writer (researches, drafts, validates, saves)

**MCP Tools:** project/mission management, context discovery, knowledge base, and 26 OCXP code intelligence tools (route, search, plan, analyze, topology, constraints, references, and more).

## Installation

```bash
claude plugin add contexthub-md/marketplace
```

## Requirements

- `CONTEXTHUB_API_URL` -- Brain API URL (defaults to https://mcp.contexthub.md)
- Authentication via Cognito OAuth (browser login on first use)
