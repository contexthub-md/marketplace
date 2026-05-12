# ContextHub Marketplace

Plugin marketplace for ContextHub tools. Currently contains:

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

## Installation

```bash
claude plugin add Sonic-Web-Dev/contexthub-marketplace
```

## Requirements

- `OCXP_MCP_API_KEY` -- API key for the OCXP engine
- `OCXP_PROJECT_ID` -- Project identifier for your indexed codebase
