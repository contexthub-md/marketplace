---
name: reflect
description: Run a post-run feedback and reflection moment after a big mission, research run, or work session. Captures how ContextHub/OCXP tools performed (product feedback) and what process lessons were learned, then saves a dated markdown file to contexthub-docs/feedback/. Use when the user says "reflect", "feedback", "retro", "post-run reflection", "how did that go", or after completing a large piece of work.
---

# Reflection & Feedback with ContextHub

Turn the end of a big run into durable feedback. Captures two things: **product feedback** (where ContextHub and OCXP tools helped or created friction) and **process lessons** (what was learned about how to work). Saves to `contexthub-docs/feedback/` so feedback accumulates over time.

This is the human/agent-facing front door to the same learning loop the memory system automates. Today it writes files; later these reflections feed into the ContextHub memory tool so lessons become queryable and get injected into future runs.

## Prerequisites

None required to write a reflection. If you want to enrich it with project context, an active project helps (`/contexthub:connect`), but the reflection itself is just a markdown file.

## Workflow

Given: "$ARGUMENTS" (the run or topic to reflect on — e.g. "memory research", "auth refactor mission"). If empty, reflect on the current session's work.

### 1. Recall what the run did

Summarize the run honestly before judging tools:
- What was the goal, and was it met?
- What was hard, surprising, or went wrong?
- Which ContextHub / OCXP / external tools were used?

If the run is unclear, ask the user one clarifying question rather than guessing.

### 2. Assess each tool touched

For every ContextHub/OCXP tool used in the run, note:
- **Useful?** What did it make faster or possible?
- **Friction?** Where did it slow you down, return too much, or miss something?
- **Token cost?** Did any tool return more than was useful?

Be specific and cite real tool names (`ch_ocxp_warmup`, `ch_search_memory`, etc.) and concrete numbers where possible.

### 3. Separate product feedback from process lessons

- **Product feedback** — concrete, prioritized improvements to ContextHub/OCXP/ch tools.
- **Process lessons** — what was learned about *how to work* (e.g. "summaries hallucinate — verify with file:line before asserting"). These are often the most valuable and the easiest to lose.

### 4. Write the feedback file

Write to `contexthub-docs/feedback/<area>-<YYYY-MM-DD>-<topic>.md` (dated + topic'd so files accumulate, never overwrite). Use the time MCP server to get the correct date. Structure:

```markdown
# <Area> Feedback — <Topic>

*Date: YYYY-MM-DD · Reviewer: <who> · Run type: <what>*

## Context
What the run was and what it aimed to do.

## Where it was useful
Concrete wins, with tool names and numbers.

## Where it could do better
Honest friction, each with a concrete suggestion.

## Suggested improvements (prioritized)
Table: priority | improvement | tied to which observation.

## Verdict
Net assessment + the meta-lesson (process learning) from the run.
```

### 5. Forward-looking hook (memory integration)

Note at the end of the file (or to the user) that this reflection is currently file-based. Once the memory system's write-back loop lands, reflections should also persist via `ch_record_decision` (or a future `ch_record_feedback`) so they become queryable memory and get injected into future runs — closing the loop instead of sitting in a folder.

## Quick reference

| Step | Action |
|------|--------|
| 1 | Recall the run — goal, what was hard, tools used |
| 2 | Assess each tool — useful / friction / token cost |
| 3 | Split product feedback vs process lessons |
| 4 | Write dated file to `contexthub-docs/feedback/` |
| 5 | Note the path to memory-tool persistence |

## Examples

```
/contexthub:reflect memory research
/contexthub:reflect how did the auth refactor mission go
/contexthub:reflect
```
