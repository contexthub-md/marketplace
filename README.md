# ContextHub Marketplace

ContextHub -- project memory, missions, context discovery, code intelligence (OCXP), and knowledge base tools for AI coding agents.

This repository has **two faces**:

1. **A Claude Code plugin** (`contexthub/`) -- skills, agents, and MCP tools. Claude Code installs the whole thing.
2. **A remote MCP server** at `https://mcp.contexthub.md/mcp` -- any MCP-capable client (Claude.ai, ChatGPT, Cline, etc.) can connect to it for the `ch_*` tools.

> **What works where:**
> - **Tools** (`ch_*` -- project memory, OCXP code intelligence, knowledge base, missions) work on **every** MCP client: Claude Code, Claude.ai, ChatGPT, Cline.
> - **Skills** (the `SKILL.md` capability files in `contexthub/skills/`) work on **Claude Code** (native), **Cline** (drop the folders into its skills directory), and **Claude.ai** (upload as a zip). **Not ChatGPT** (no skill mechanism -- tools only).
> - The **one-command plugin/marketplace install** (`claude plugin ...`) is **Claude Code only**. On Cline and Claude.ai you install the skill folders manually (see [Using the skills outside Claude Code](#using-the-skills-outside-claude-code)). Skills do not sync across apps -- install per surface.

## What you get

### Skills (Claude Code)

*Orientation & setup*
- `contexthub:start` -- routing map: which tool/skill to use for a given intent (use first when unsure)
- `contexthub:connect` -- connect to a project (workspace, project, mission setup)
- `contexthub:import` -- import a repository from GitHub
- `contexthub:resume` -- resume work on a project or mission
- `contexthub:status` -- project health check and compass briefing

*Code intelligence (OCXP)*
- `contexthub:explore` -- navigate and understand a codebase using the code graph
- `contexthub:analyze` -- audit code quality (dead code, anti-patterns, gaps, architecture)
- `contexthub:plan` -- plan features/refactors with code graph intelligence and validation
- `contexthub:branch-search` -- index and search a specific Git branch

*Architecture decisions (ADRs)*
- `contexthub:adr-follow` -- find the accepted ADR clauses governing files before editing; stop on conflict; cite clauses when done
- `contexthub:adr-capture` -- propose an ADR for an architectural decision made during work (a human accepts it)
- `contexthub:adr-author` -- author a complete proposed ADR from an idea document, re-grounding every claim in the code index
- `contexthub:adr-anchors` -- keep ADR governs anchors accurate when code moves

*Context, docs & knowledge*
- `contexthub:context` -- read/write/list/delete documents on any context type (mission/project/SOP docs)
- `contexthub:discover` -- general semantic search / RAG over the project knowledge base
- `contexthub:kb` -- query the project's own indexed reference repos
- `contexthub:research` -- multi-source research (KB + external library docs + web)

*Missions & process*
- `contexthub:mission` -- mission management (list, create, update, track)
- `contexthub:mission-dev` -- start developing on a mission (branch checkout, indexing)
- `contexthub:sop` -- create and manage SOPs (runbooks, deployment guides)
- `contexthub:sop-writer` -- autonomous research-backed SOP writer
- `contexthub:reflect` -- post-run feedback and reflection

### Agents (Claude Code)
- `code-navigator` -- OCXP-aware code navigation (call chains, topology, impact analysis)
- `researcher` -- ContextHub-aware research agent for investigating questions
- `sop-writer` -- autonomous SOP writer (researches, drafts, validates, saves)

### MCP tools (all clients)
Project and mission management, context discovery, document CRUD, knowledge base, and 26 OCXP code intelligence tools (route, search, plan, analyze, topology, constraints, references, and more). Call `ch_get_memory_context` first to orient.

### Hooks -- cross-session learning (Claude Code)
Installed with the plugin and active automatically. They close the learning loop so the agent improves across sessions:
- **SessionStart** -- reminds the agent to call `ch_get_lessons` (load error patterns, skill stats, and prompt effectiveness learned from prior runs) before substantial work.
- **PreToolUse** (Edit, Write, MultiEdit) -- calls `ch_get_governing` with `format: "hook"`, the
  file path; when accepted ADR clauses govern the file, they are added to the
  agent's context before the edit (binding clauses with rule state, a trial-clause count). It maps
  only files inside a checkout of a project repo (a folder named like the repo); a worktree
  not named like the repo gets no injection (fail closed). It injects nothing outside a
  ContextHub project, on any error or after a 3 second timeout, and never blocks. NotebookEdit is not covered. Needs the Brain
  `format=hook` release.
- **PostToolUseFailure** -- when a tool call fails, automatically calls `ch_log_outcome` to capture the failure so future sessions learn from it.

The matching MCP tools work on every client: `ch_get_lessons` (read learned lessons) and `ch_log_outcome` (capture an error+fix, skill result, or prompt outcome). On non-Claude-Code clients, call them manually -- the hooks just automate them. Lessons are populated by AgentCore missions and by `ch_log_outcome`; extraction is asynchronous, so a freshly logged outcome surfaces in `ch_get_lessons` a few minutes later.

## Install

### Claude Code (full plugin: skills + agents + tools)

```bash
claude plugin marketplace add contexthub-md/marketplace
claude plugin install contexthub@marketplace
```

Or use the `/plugin` command inside Claude Code to add the marketplace and install the `contexthub` plugin from the UI.

- Update later: `/plugin` (pulls the latest version), then `/reload-plugins` to apply it in the current session.
- First use prompts a browser-based OAuth login.

### Claude (claude.ai)

Connect to the remote MCP server as a custom connector:

1. Settings -> **Connectors** -> **Add custom connector**.
2. Enter the URL: `https://mcp.contexthub.md/mcp`
3. Click **Add**, then complete the OAuth login on first use.

You get the `ch_*` tools. To also use the skills on Claude.ai, see [Using the skills outside Claude Code](#using-the-skills-outside-claude-code).

### ChatGPT

Add ContextHub as a remote MCP server / connector (Settings -> **Connectors**, or via Developer mode, depending on your plan and app version):

1. Add a connector / remote MCP server.
2. URL: `https://mcp.contexthub.md/mcp`
3. Authenticate via OAuth on first use.

Remote MCP connector availability depends on your ChatGPT plan (Plus / Pro / Team / Enterprise / Business). You get the `ch_*` tools.

### Cline

> **Note on "Cline plugins":** ContextHub is not packaged as a Cline plugin (in Cline, a "plugin" is a TypeScript code module installed via `cline plugin install`). You do not need a separate repo or a plugin build. In Cline you use ContextHub two ways, both from this same repo: connect the **MCP server** for the tools, and copy the **skill folders** into `~/.cline/skills/` for the skills (below).

Add the remote server in Cline:

1. Open the **MCP Servers** icon -> **Remote Servers** tab.
2. Name: `contexthub`, URL: `https://mcp.contexthub.md/mcp`, transport: **Streamable HTTP**.

Or edit the MCP config JSON directly:

```json
{
  "mcpServers": {
    "contexthub": {
      "url": "https://mcp.contexthub.md/mcp"
    }
  }
}
```

OAuth is handled on first connect. (If your deployment uses a static token instead, add a `"headers": { "Authorization": "Bearer <token>" }` field.) You get the `ch_*` tools. Cline can also run the skills -- see [Using the skills outside Claude Code](#using-the-skills-outside-claude-code).

### Using the skills outside Claude Code

The skills are plain `SKILL.md` files (markdown + `name`/`description` frontmatter) in `contexthub/skills/`. They orchestrate the `ch_*` tools, so **connect the MCP server first** (above), then install the skill folders:

**Cline** -- copy the skill folders into Cline's skills directory:

```bash
# global (all projects)
cp -r contexthub/skills/* ~/.cline/skills/
# or per-project: <project>/.cline/skills/
```

Cline auto-discovers them and activates the right one per request (via its `use_skill` mechanism). Same `SKILL.md` format -- no conversion needed.

**Claude.ai** -- upload a skill as a zip (Pro / Max / Team / Enterprise, with code execution enabled):

1. Zip a skill folder so `SKILL.md` sits at the root (e.g. `cd contexthub/skills/explore && zip -r explore.zip .`).
2. In Claude.ai: **Settings -> Features** -> upload the skill zip.
3. Repeat per skill you want.

> Skills do **not** sync across apps -- a skill installed in Claude Code is not automatically available in Cline or Claude.ai; install it on each surface. Exact menu labels vary by app version. ChatGPT has no skill mechanism (tools only).

> Exact menu labels vary by app and version; the mechanism in every non-Claude-Code client is the same: add a **remote / custom MCP server** pointing at `https://mcp.contexthub.md/mcp`.

## Getting started (the base flow)

ContextHub is organized as: **workspace -> project -> mission -> session**. Almost every tool needs an active **project**; linking a **session** persists your context (decisions, memory) across conversations. A **mission** is an optional unit of work (a feature, refactor, investigation) you can scope and track.

### 1. Connect to a project (links your session)

The fastest path in Claude Code -- one guided command sets workspace + project + session:

```
/contexthub:connect            # interactive: pick workspace, project, (optional) mission
/contexthub:connect brain      # connect by project name
/contexthub:connect <uuid>     # connect directly by project UUID
```

Under the hood this calls `ch_set_context` (locks workspace + project + mission) and `ch_connect_session` (creates a persistent session linked to them). On any client you can do it with tools directly:

```
ch_list_projects                                   # find the project + its UUID
ch_set_project(project_id="<uuid>")                # set active project
ch_connect_session(project_id="<uuid>", mission_id="<uuid>")   # link a session (mission optional)
```

If a tool ever returns `NO_PROJECT`, you just need to connect first.

### 2. No project yet? Import a repo

```
/contexthub:import https://github.com/org/repo      # downloads + indexes, creates a project
```
Indexing runs in the background; check it with `ch_get_index_status(job_id)`.

### 3. Create or link a mission

```
/contexthub:mission                                       # list / create / update missions
ch_create_mission(title="...", project_id="<uuid>", priority="high")   # create
ch_connect_session(project_id="<uuid>", mission_id="<uuid>")           # link an existing mission to your session
/contexthub:mission-dev <mission-id>                      # start dev: checkout mission branch + index it
```
Creating a mission auto-creates `mission/<id>` branches on the project's code repos for isolated work.

### Base commands worth knowing

| Goal | Claude Code skill | Tool (any client) |
|------|-------------------|-------------------|
| See the map of what to use when | `/contexthub:start` | -- |
| Orient: what's going on here | `/contexthub:status` | `ch_get_memory_context`, `ch_get_compass` |
| Connect / switch project | `/contexthub:connect` | `ch_set_project`, `ch_connect_session` |
| Understand the codebase | `/contexthub:explore` | `ch_ocxp_warmup`, `ch_ocxp_search` |
| Plan a change | `/contexthub:plan` | `ch_ocxp_plan` |
| Recall a past decision | -- | `ch_search_memory` |
| Save a session decision | -- | `ch_record_decision` |
| Follow / propose architecture decisions | `/contexthub:adr-follow`, `/contexthub:adr-capture`, `/contexthub:adr-author` | `ch_list_adrs`, `ch_create_adr` |
| Attach a doc to a mission/project | `/contexthub:context` | `ch_write_context` |
| Search our docs / libraries / web | `/contexthub:kb`, `/contexthub:research` | `ch_discover_context` |
| Resume previous work | `/contexthub:resume` | `ch_list_sessions`, `ch_get_session_messages` |

Tip: when in doubt about which tool fits, call `ch_get_memory_context` first to orient, and in Claude Code run `/contexthub:start` for the full routing map.

## Configuration

- **Server URL** -- defaults to `https://mcp.contexthub.md/mcp`. The endpoint is `{CONTEXTHUB_API_URL}{CONTEXTHUB_MCP_PATH}`:
  `CONTEXTHUB_API_URL` sets the host (default `https://mcp.contexthub.md`) and `CONTEXTHUB_MCP_PATH` sets the path
  (default `/mcp`). Set both when a deployment needs an exact path, for example a trailing slash:
  `CONTEXTHUB_API_URL=https://dev-mcp.contexthub.md` and `CONTEXTHUB_MCP_PATH=/mcp/`. In Claude Code, put them in the
  `env` block of `.claude/settings.local.json` so they survive plugin updates.
- **Authentication** -- Cognito OAuth; a browser login is triggered on first connect for every client.
- **Tools work everywhere; skills install per surface.** The `ch_*` tools work on any MCP client. The skills run natively in Claude Code, and can be installed manually on Cline and Claude.ai (see [Using the skills outside Claude Code](#using-the-skills-outside-claude-code)); ChatGPT is tools-only. Agents are Claude Code only.

## Verify the connection

- Any client: list the available tools (look for `ch_*`), or call `ch_get_memory_context` to fetch the project/mission orientation bundle.
- Claude Code: run `/contexthub:start` for the routing map, or `/contexthub:connect` to set up a workspace/project.
