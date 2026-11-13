---
name: adr-follow
description: Follow the project's accepted architecture decisions (ADRs) while changing code. Use BEFORE editing, creating, moving or deleting files in a ContextHub project, when planning a change, or when a code result lists governing decisions. Finds the accepted clauses that govern the files, states them in the plan, stops when the task would break one, and cites the respected clauses when done.
---

# Follow Accepted ADRs

Architecture decision records (ADRs) hold the rules a project has decided on. Each ADR has clauses D1..Dn. Only clauses with status `accepted` are binding. `proposed` clauses are suggestions: mention them, do not obey them as rules. `superseded` and `withdrawn` clauses no longer apply.

## Prerequisites

An active project (`ch_get_memory_context`; on `NO_PROJECT` run `/contexthub:connect`).

## Workflow

Given: "$ARGUMENTS" (the change you are about to make)

### 1. Find the governing clauses

In Claude Code a PreToolUse hook adds the accepted clauses that govern a file to your context just before each Edit, Write, MultiEdit or NotebookEdit. When you see that "ContextHub: accepted ADR clauses govern ..." text, treat it as the result of this step for that file: the clauses bind you, the `BROKEN` line means do not add to that rule's violations, and trial clauses only warn. Silence from the hook does not prove nothing governs (it fails open): still do the lookup below before planning a change.

List the files and folders you expect to touch, as `<owner>/<repo>:<path>` with the repo-root git path (`backend/api/...`).

- When a code result carries a `governing_decisions` field, use it. Tools that can carry it: `ch_ocxp_route`, `ch_ocxp_search`, `ch_ocxp_query`, `ch_ocxp_entity`, `ch_ocxp_zoom`, `ch_ocxp_references`, `ch_ocxp_communities`, `ch_ocxp_find_file`, `ch_ocxp_grep` and `ch_ocxp_file_read`. Keys:
  - `decisions`: accepted clauses that govern files in the result, closest match first (at most three with full text). Each has `clause` (for example "ADR-0001 D2"), `adr_id`, `title`, a one-sentence `decision`, the covered `path`, and `match` (`symbol`, `file` or `folder`: how closely the anchor covers it).
  - `read`: the call to read the whole ADR, `ch_get_adr(adr_id=<adr_id>, tier='L2')`.
  - `shown_earlier`: clauses listed by id only, because you already saw their text this session. They still bind you; do not treat them as gone.
  - `proposed_clauses`: a count of proposed clauses on these files. Proposals are not binding; ignore them unless the user asks.
  - `more` and `more_hint`: the block was truncated and `more` clauses are not shown. Run the `ch_list_adrs(governs=[...])` call in `more_hint` to see them all before editing.
- When the result has no `governing_decisions` field (nothing governs, or the lookup was skipped), or you have not read the files yet, call `ch_list_adrs` with `governs=["<owner>/<repo>:<path>", ...]` (a folder path covers everything under it). Use `tier="L2"` to get the clause list with status and implementation state.

Only accepted clauses on non-superseded ADRs bind you. `binding=true` on an ADR means at least one clause is accepted: check each clause status, since the rest may still be proposed.

### 2. State them in the plan

Before the first edit, write a short "Governing decisions" list in your plan or reply: `ADR-<n> D<k>: <title>` and how the change respects it. If none apply, say "no accepted ADR governs these files".

Drill into a clause with `ch_get_adr` (`tier="L3"`) only when the title and short text do not settle whether your change complies. Do not read full ADRs by default; it costs tokens.

### 3. If the task conflicts with an accepted clause

Stop. Do not edit against it, and do not look for a workaround that keeps the letter and breaks the intent. Tell the user:

- which clause (`ADR-<n> D<k>`, title) and which part of the task conflicts,
- the two ways forward: (a) change the decision, by proposing an amending or superseding ADR (see `/contexthub:adr-capture`; `ch_create_adr` or `ch_update_adr` action `propose_clause` with a `supersedes` or `amends` link), or (b) a one-off exception, which only the user can grant as a waiver on the ContextHub dashboard.

Change lifecycle for an accepted clause: the meaning changes, so a superseding clause (you propose it; never edit in place); a wording fix with the same meaning, so an erratum; one time-boxed exception, so a waiver with an end date; it no longer applies, so retire. Erratum, waiver and retire are human dashboard verbs.

Accept, reject, waive, erratum and retire are human-only actions; MCP callers are refused. Never try them. Continue only after the user confirms the clause was changed or waived, or narrows the task so it complies.

### 4. When you finish

Cite the clauses you respected in the PR description or final summary: `Respects ADR-<n> D<k>, ADR-<m> D<j>`. If you touched a governed file but found no clause that applied, say so. If the change moved or renamed governed files, run `/contexthub:adr-anchors`. If you made a new architectural choice, run `/contexthub:adr-capture`.

## Rules

- Accepted clauses are binding; proposed ones are not. Never describe a proposed clause as a rule.
- Never accept, reject, waive, correct or retire anything; ask the human to use the dashboard.
- A clause's `implementation` state ("decided, not implemented") does not weaken it: it still binds new work.
- Look up by file path, not by guessing ADR titles.

## Examples

```
/contexthub:adr-follow add a retry layer to the export job
/contexthub:adr-follow move session storage to Redis
```
