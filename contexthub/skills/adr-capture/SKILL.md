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

A choice that contradicts an accepted clause is PROPOSE as a superseding or amending record, never an edit around it (see `/contexthub:adr-follow`). If the clause it contradicts is still `proposed`, link with `amends` instead (or edit/withdraw that clause when you own it): `supersedes` only targets accepted clauses. Propose at most one or two ADRs per PR or task; split a bundle of decisions into separate ADRs only when each meets the PROPOSE bar.

### 2. Check for an existing ADR first

Call `ch_list_adrs` with `governs=["<owner>/<repo>:<path>"]` for the files the decision constrains, and `focus="<keywords>"` for the topic. Proposed ADRs count too (the default status filter includes them; a proposed ADR that covers the choice is LINK_EXISTING). Read the hits at `tier="L2"`. If one covers it, the result is LINK_EXISTING: tell the user and stop. If the user wants to extend an existing ADR, use `ch_update_adr` with `action="propose_clause"` instead of a new ADR.

### 3. Create the proposed ADR

Call `ch_create_adr`:

- `title`: a verb phrase. `summary`: one or two sentences, what was decided and why.
- `context`: the problem, the trigger and why now. `rationale`: why this option, including the strongest counter-argument.
- `decisions`: the clauses, one rule each, in active voice ("We will keep run state in one DynamoDB table"). Per clause: `title` (short, imperative, 3-120 chars, no trailing period), `text`, `source_ref`, `decided_on` and `governs`.
- `source_ref`: where it was decided, as `pr:owner/repo#n`, `doc:<repo>/<path>` or `mission:<id>`. A decision made in chat or from memory: cite the date and who decided, for example `session 2026-11-05, decided by <name>`.
- `decided_on` (YYYY-MM-DD): the date the clause text was decided. If a later commit changed the rule, use that later date and cite it in `source_ref`. Get the date from the time tool, never from memory.
- `governs` anchors use repo-root git paths: `"<owner>/<repo>:<path>"`, such as `owner/repo:backend/api/features/x/y.py`, with `#symbol` for a function or class, or a folder path to cover everything under it. Index results may show a shorter sub-index path (`features/x/y.py`); do not copy it. Call `ch_ocxp_file_exists` with the full git path and check `exists=true`. `ch_ocxp_find_file` globs can miss a file that `file_exists` finds. Never invent a path.
- Check each `#symbol` with `ch_ocxp_grep` for the `def` or `class` in that file. After create, `anchors[].state` must be `resolved`.
- `options`: at least two, one chosen. `pros` and `cons` are lists of strings, never one string. Also `consequences` (list of strings, good and bad).
- Per clause, optional: `verification` (a list of strings; prefer typed checks such as `file_exists: <repo>:<path>`, `symbol_exists: <repo>:<path> :: Name`, `grep_present: ...`, as seen on existing ADRs), `confidence` (low|medium|high) and `revisit_when` (conditions, not dates).
- `links` for related ADRs: `{clause: "D1", type, target: "ADR-0007#D2"}` with type `supersedes` (target must be an ACCEPTED clause, otherwise completeness reports a blocking finding), `amends` (use for proposed targets), `relates` or `depends_on`.
- `request_id`: a stable key so a retry returns the same ADR.

Minimal valid call:

```json
{
  "title": "Keep run state in one DynamoDB table",
  "summary": "Run state lives in one DynamoDB table because it needs single-digit ms reads.",
  "context": "Run state is read on every step and was spread over S3 and Postgres.",
  "rationale": "One table is simplest to operate; the counter-argument is hot partitions.",
  "decisions": [{
    "title": "Store run state in one DynamoDB table",
    "text": "We will keep run state in one DynamoDB table.",
    "source_ref": "pr:owner/repo#12",
    "decided_on": "2026-11-05",
    "governs": ["owner/repo:backend/api/state/store.py#RunStore"],
    "verification": ["file_exists: owner/repo:backend/api/state/store.py"]
  }],
  "options": [
    {"name": "DynamoDB", "chosen": true, "pros": ["low latency"], "cons": ["hot partitions"]},
    {"name": "Postgres", "chosen": false, "pros": ["joins"], "cons": ["extra service"], "rejected_because": "no relational need"}
  ],
  "consequences": ["Reads are fast", "Cross-item queries need a GSI"],
  "links": [{"clause": "D1", "type": "relates", "target": "ADR-0001#D3"}],
  "request_id": "state-table-2026-11-05"
}
```

Leave a field out when the evidence does not support it. Do not invent ratings, costs, owners or confidence.

### 4. Read the result and check completeness

Check `warnings`: on DUPLICATE_CANDIDATES read the named ADR and either switch to LINK_EXISTING or explain in `rationale` how the new one differs. If `warnings` or `suggested_governs` are absent, none were found. Check `anchors`: fix `broken` or `ambiguous` entries with `ch_update_adr` `action="edit"` (read `rev` from `ch_get_adr` first and pass it as `expected_rev`); add useful entries from `suggested_governs` the same way.

Then always call `ch_get_adr_completeness` and fix every blocking finding you caused (for example `superseded_replacement_not_accepted`: `unlink` the `supersedes` link and `link` an `amends` one). Info findings (such as a missing typed verification) are not blocking. Links you add with `ch_update_adr` `link`/`unlink` are state `inferred`; a human confirms them. You may unlink your own.

### 5. Hand over to the human

Give the user the `dashboard_url` and say plainly: "Proposed, not binding. It takes effect when you accept it on the dashboard." Never call it accepted or binding, and never try to accept it yourself; MCP callers are refused.

## Rules

- Agents create `proposed` only; links they add are `inferred` until a human confirms. Accept, reject and waive are human actions.
- One rule per clause; split a clause that states two.
- No ADR number is chosen by you; the server numbers records and clauses.
- Do not use `ch_record_decision` as a substitute for an ADR when the choice meets the PROPOSE bar.
