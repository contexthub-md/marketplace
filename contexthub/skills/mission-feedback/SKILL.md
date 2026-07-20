---
name: mission-feedback
description: Debrief a completed development mission from its actual session transcript. Resolves a mission ID to its Claude Code transcript, reads what really happened (prompts, tool calls, errors, retries, token usage), then scores the run across flow / quality / agenticness / PM and produces a ranked findings list -- each classified as a bugfix, prompt-change, or skill-creation with evidence and a concrete action. Use when the user says "mission-feedback", "debrief", "what went wrong in mission X", "post-mortem", or wants an evidence-based review of a specific mission. Sibling to /contexthub:reflect (which is subjective/manual); this one is transcript-driven and scored.
---

# Mission Feedback -- Transcript-Driven Debrief

Turn a finished mission into tracked improvements. Unlike `/contexthub:reflect` (subjective, end-of-run, product+process notes), this skill reads the **actual session transcript** for a specific mission and produces an evidence-based debrief: scores per dimension plus a ranked findings list, each routed to a **bugfix**, a **prompt-change**, or a **skill-creation** so the same failure does not recur.

This is the local, human-run first cut of a larger debrief loop. The analysis body below is deliberately self-contained so it can later be lifted verbatim into a Brain/AgentCore agent that runs automatically on mission-complete.

## Prerequisites

- A mission ID or its short form (e.g. `weaver-02d2080b` or `02d2080b`).
- The mission's Claude Code transcript must exist locally under `~/.claude/projects/`.

## Workflow

Given: "$ARGUMENTS" (a mission ID -- full UUID, `weaver-<short>`, or bare `<short>`). If empty, ask the user which mission to debrief rather than guessing.

### 1. Resolve the mission to its transcript folder

The mission maps to a git worktree, which maps to a Claude Code project folder:

1. **Short-id**: take the first 8 chars of the UUID (or strip a `weaver-` prefix). This matches Weaver's `shorten_mission_id`.
2. **Worktree path**: `<workspace-mount>/.worktrees/<short-id>/<repo>`. The workspace mount is the contexthub checkout root (e.g. `/Users/andre/Sonic-Web-Dev/contexthub`).
3. **Encoded folder**: Claude Code stores transcripts at `~/.claude/projects/<encoded>`, where `<encoded>` is the absolute worktree path with every `/` and `.` replaced by `-`. This matches Weaver's `encode_project_path`.

Find all matching folders with a prefix scan (a mission spans multiple repo worktrees). Use Bash:

```bash
SHORT="02d2080b"   # derived from the mission id
ls -d ~/.claude/projects/*worktrees-${SHORT}-* 2>/dev/null
```

If nothing matches, the mission may have run in a non-worktree workspace -- fall back to scanning `~/.claude/projects/` for any folder whose name contains the short-id, and confirm with the user before proceeding.

### 2. Read the transcripts (source of truth)

For each matched folder, read every `*.jsonl` **except** `agent-*.jsonl` (those are subagent sidechains -- include them only if the user asks for subagent-level detail).

Each line is one JSON object. The fields that matter:
- `type`: `user`, `assistant`, `system`, `file-history-snapshot`, etc.
- `message.role` + `message.content`: the turn content. `content` is either a string (user) or an array of blocks with `type` in `text` / `thinking` / `tool_use` / `tool_result`.
- `message.model`: the model for assistant turns (e.g. `claude-opus-4-8`).
- `message.usage`: `input_tokens`, `output_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens` -- preserve these; they are the cost signal.
- `timestamp`, `uuid`, `parentUuid`: ordering and turn references.

**Source discipline (locked):** use transcripts ONLY. Do NOT pull from claude-mem / agent-mem for this cut -- its per-session join is unreliable (it keys observations by project folder, not session id). Transcripts are authoritative.

Reconstruct the run: the goal, the sequence of work, tool calls and their results, errors (`tool_result` blocks flagged as errors, or content starting with `[Error]`), retries, dead ends, and where the agent stalled or produced incorrect results. Roll up total tokens per model from the `usage` blocks.

### 3. Score across four dimensions

Score each 1-10 with a one-to-two sentence rationale grounded in specific turns. Do not inflate -- a 7 is a solid run; reserve 9-10 for exceptional.

- **Flow** -- did the mission move forward cleanly, or thrash (repeated retries, backtracking, re-reading the same files, circular tool calls)?
- **Quality** -- correctness and completeness of the work produced. Were there bugs, half-finished changes, hanging todos, incorrect claims?
- **Agenticness** -- did the agent act autonomously and decisively, use the right tools, verify its own work -- or stall, over-ask, or guess without checking?
- **PM / mission management** -- were tasks tracked, todos completed and reported, commits made, mission state kept honest? Anything left hanging or misreported?

### 4. Extract findings and classify each

List what went wrong or could be better, ranked most-impactful first. For each finding provide:
- **What happened** -- one concrete sentence.
- **Evidence** -- a turn reference (timestamp or a short quote) so it is verifiable, not a vibe.
- **Class** -- exactly one of:
  - `bugfix` -- a defect in Weaver / the engine / tooling that made the mission harder or wrong.
  - `prompt-change` -- guidance the agent needed but did not have (a CLAUDE.md rule, a clearer instruction, a missing constraint).
  - `skill-creation` -- a repeatable workflow that should become a skill so it is done consistently next time.
- **Proposed action** -- the concrete next step (e.g. "add rule to weaver CLAUDE.md: ...", "file bug: report_todo_complete accepted an abbreviated SHA", "create skill: pre-merge dashboard build gate").

Focus on findings that would change the outcome of the *next* comparable mission. Skip generic observations.

### 5. Write the debrief file

Get the correct date from the time MCP server. Write to `contexthub-docs/feedback/mission-<mission-short>-<YYYY-MM-DD>-debrief.md` (dated so files accumulate, never overwrite). Structure:

```markdown
# Mission Debrief -- <mission-id>

*Date: YYYY-MM-DD - Reviewer: mission-feedback (transcript-driven) - Transcripts: N files, M turns*

## Context
What the mission aimed to do, and whether it was met. Total tokens per model.

## Scores
| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Flow | x/10 | ... |
| Quality | x/10 | ... |
| Agenticness | x/10 | ... |
| PM | x/10 | ... |

## Findings (ranked)
| # | What happened | Evidence | Class | Proposed action |
|---|---------------|----------|-------|-----------------|
| 1 | ... | <turn ref> | bugfix / prompt-change / skill-creation | ... |

## Verdict
Net assessment + the single highest-leverage change for next time.
```

### 6. Present and route (human-approved)

Show the user the scores and the ranked findings. Then **propose** routing -- do not act without approval (per CLAUDE.md "ask before pushing to Brain"):
- `bugfix` findings -> offer to file via `create_bug_report` / `ch_create_memo`.
- `prompt-change` findings -> offer the concrete CLAUDE.md / prompt edit.
- `skill-creation` findings -> offer to draft the skill.

Nothing is written to Brain or committed until the user confirms.

## Rules

- Transcripts are the source of truth. Every finding cites a turn -- no unsupported claims.
- Source discipline: transcripts only for this cut; agent-mem is deferred.
- Score honestly; evidence over vibes.
- Read-only against `~/.claude/projects/` -- never modify transcripts.
- Human approves all routing; no auto-write to Brain, no auto-commit.
- Keep the analysis self-contained so it can port to an AgentCore agent unchanged.

## Quick reference

| Step | Action |
|------|--------|
| 1 | Resolve mission id -> short-id -> encoded `~/.claude/projects/` folder(s) |
| 2 | Read `*.jsonl` (skip `agent-*`); reconstruct run; keep `usage` |
| 3 | Score flow / quality / agenticness / PM (1-10 + rationale) |
| 4 | Extract findings; classify bugfix / prompt-change / skill-creation + action |
| 5 | Write dated debrief to `contexthub-docs/feedback/` |
| 6 | Present; propose routing; human approves |

## Examples

```
/contexthub:mission-feedback weaver-02d2080b
/contexthub:mission-feedback 02d2080b
/contexthub:mission-feedback
```
