---
name: adr-capture
description: Capture an architectural decision as a PROPOSED ADR in ContextHub. Use when you or the user make a choice between alternatives with lasting effect (storage, API contract, auth model, module boundaries, a library others must follow) while working. Decides PROPOSE, NONE or LINK_EXISTING, checks for an existing ADR first, then creates a proposed ADR with atomic clauses and governs anchors.
---

# Capture an Architecture Decision

Record decisions that future work must follow. Agents only ever create PROPOSED ADRs: a human accepts them on the dashboard, and only then are they binding. Session notes and small facts go to `ch_record_decision`; architectural decisions go here.

## Prerequisites

An active project (`ch_get_memory_context`; on `NO_PROJECT` run `/contexthub:connect`).

## Workflow

Given: "$ARGUMENTS" (the decision, or empty to review the current work)

### 1. Rate the candidate

Pick exactly one result:

| Result | When |
|---|---|
| PROPOSE | The choice is architectural (hard to reverse, crosses modules, or fixes a pattern others must follow), at least two real options existed, a reason was stated, and no ADR covers it. |
| LINK_EXISTING | An accepted or proposed ADR already records it, or the work only applies it. Name the ADR and clause. |
| NONE | A local implementation choice, a one-off fix, a style preference, an unverified preference, or a choice with no stated reason. |

A choice that contradicts an accepted clause is PROPOSE as a superseding or amending record, never an edit around it (see `/contexthub:adr-follow`). Propose at most one or two ADRs per piece of work.

### 2. Check for an existing ADR first

Call `ch_list_adrs` with `governs=["<owner>/<repo>:<path>"]` for the files the decision constrains, and `focus="<keywords>"` for the topic. Read the hits at `tier="L2"`. If one covers it, the result is LINK_EXISTING: tell the user and stop. If the user wants to extend an existing ADR, use `ch_update_adr` with `action="propose_clause"` instead of a new ADR.

### 3. Create the proposed ADR

Call `ch_create_adr`:

- `title`: a verb phrase. `summary`: one or two sentences, what was decided and why.
- `context`: the problem, the trigger and why now. `rationale`: why this option, including the strongest counter-argument.
- `decisions`: the clauses, one rule each, in active voice ("We will keep run state in one DynamoDB table"). Per clause: `title` (short, imperative, 3-120 chars, no trailing period), `text`, `source_ref` (where it was decided: PR, doc path, session), `decided_on` (YYYY-MM-DD, from the real date), and `governs`.
- `governs` anchors point at the real files: `"<owner>/<repo>:<path>"`, with `#symbol` for a function or class, or a folder path to cover everything under it. Verify each path exists with `ch_ocxp_find_file` or `ch_ocxp_file_exists`; never invent one.
- `options`: each `{name, chosen, pros, cons, rejected_because}`, at least two, one chosen. Also `consequences` (good and bad), and optional `verification`, `confidence` and `revisit_when` (conditions, not dates) per clause.
- `links` for related ADRs: `{clause: "D1", type: "supersedes"|"amends"|"relates"|"depends_on", target: "ADR-0007#D2"}`.
- `request_id`: a stable key so a retry returns the same ADR.

Leave a field out when the evidence does not support it. Do not invent ratings, costs, owners or confidence.

### 4. Read the result

Check `warnings`: on DUPLICATE_CANDIDATES read the named ADR and either switch to LINK_EXISTING or explain in `rationale` how the new one differs. Check `anchors`: fix `broken` or `ambiguous` entries with `ch_update_adr` `action="edit"` (read `rev` from `ch_get_adr` first and pass it as `expected_rev`); add useful entries from `suggested_governs` the same way.

### 5. Hand over to the human

Give the user the `dashboard_url` and say plainly: "Proposed, not binding. It takes effect when you accept it on the dashboard." Never call it accepted or binding, and never try to accept it yourself; MCP callers are refused.

## Rules

- Agents create `proposed` only. Accept, reject and waive are human actions.
- One rule per clause; split a clause that states two.
- No ADR number is chosen by you; the server numbers records and clauses.
- Do not use `ch_record_decision` as a substitute for an ADR when the choice meets the PROPOSE bar.
