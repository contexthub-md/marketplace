---
name: adr-author
description: Author a complete PROPOSED ADR in ContextHub from an idea document, such as an existing markdown ADR, design note or plan in a repo. Use when the user hands you a document and asks to turn it into an ADR, to re-author or refresh an old ADR against current code, or to migrate a docs/adr file with grounded anchors and checks. The document is intent, not truth: every claim is re-grounded in the ContextHub code index before it becomes a clause. For a single decision made during work use /contexthub:adr-capture instead.
---

# Author an ADR from an idea document

Turn a document into one proposed ADR whose every clause is backed by the current code. Field shapes, the anchor format, the minimal `ch_create_adr` call, links and the PROPOSE/NONE/LINK_EXISTING bar live in `/contexthub:adr-capture`: read it first and follow it; this skill only adds the method for a document source. The server skills `adr-writer` (how to fill each field) and `adr-reviewer` (the 15-item readiness checklist) are the quality bar; check your draft against both before you create. Agents only create PROPOSED records; a human accepts.

## Prerequisites

An active project whose repo is indexed (`ch_get_memory_context`; on `NO_PROJECT` run `/contexthub:connect`). The source document: read it from the index or the user's text. `ch_import_adrs` copies a markdown ADR as written, without checking it; use this skill when the claims must be checked.

## Method

Given: "$ARGUMENTS" (the document path or text, and the project)

1. **Treat the document as intent, not truth.** Split it into claims: decisions, named files and symbols, "deferred" or "does not exist yet" statements, dependencies, links to other ADRs. Expect drift: in the calibration run (ADR-0001, 2026-11-06) a 17-day-old ADR was wrong on 3 of its 4 decisions: resources it called deferred already existed, a new optional dependency existed, and a later ADR had superseded part of it.
2. **Ground each claim only through the ContextHub index of the target project**: `ch_ocxp_grep`, `ch_ocxp_file_read`, `ch_ocxp_find_file`, `ch_ocxp_entity`, `ch_ocxp_file_exists`. Brain checks anchors against that index, so a local checkout proves nothing. If a path you need is missing from the index, report it as an index gap to the user (and as a memo if they agree). Do not anchor it anyway and do not drop it silently. Also run `ch_list_adrs` (`governs` and `focus`) to find later ADRs that touch the same ground.
3. **Drop or rewrite what the code no longer supports.** Leave out the parts a later ADR superseded and say so in `context`. A claim the index cannot show either way is not a clause: record it in `consequences` as deferred, or leave it out.
4. **One rule per clause.** Splitting a source decision is fine. Give each clause a `source_ref` that maps back to the original, such as `owner/repo:docs/adr/0001-x.md#D1 (bullet 2)`; later ADRs that cite the old numbers use that mapping. Add `decided_on` only from the document's own date, taken from the time tool, never from memory.
5. **Write `governs` anchors** as `owner/repo:path` or `owner/repo:path#symbol`, using only paths and symbols you saw in the index (see adr-capture for how to check them).
6. **Write verification in the closed check vocabulary** of Brain `backend/api/features/core/adrs/checks.py`: `file_exists`, `grep_present`, `grep_absent`, `symbol_exists`, `test_exists`, `no_reference_to`, `only_referenced_from`, `not_checkable`. Prefer a behavior proof: `test_exists` for a test that pins the rule, `no_reference_to` and `only_referenced_from` for module boundaries. Avoid `file_exists` alone and grepping docstrings, which prove a file or a phrase, not behavior. When no strong check exists, say so in plain text. Keep process claims ("we review weekly") out of clause text, or mark them `not_checkable`.
7. **Fill the body from evidence only** (adr-writer has the field rules):
   - `summary` as a Y-statement, plus `context` and drivers.
   - `rationale` with the strongest counter-argument.
   - `options` with pros and cons, exactly one chosen, every rejected one with a reason.
   - `consequences` with `consequence_polarity`, plus `risks` and `non_goals`.
   - `owner` and `decided_by` only when you know the workspace member (user_sub); otherwise leave them out.
   - `reversibility` (easy|hard) that is honest about how hard the decision is to undo; unset blocks auto-confirm.
8. **Create with `ch_create_adr`** and a stable `request_id` (for example `<repo>-<doc>-<date>`) so a retry returns the same ADR. Resolve every returned anchor. A `broken`, `stale` or `ambiguous` anchor is either your mistake (fix it with `ch_update_adr` `action="edit"`, `expected_rev` from `ch_get_adr`) or a tool or index defect (report it with the evidence). Never edit the ADR to hide a defect.
9. **Check completeness, then get the independent review.** Run `ch_get_adr_completeness` and fix every blocking finding you caused. Then request the independent reviewer with `ch_update_adr` `action="request_review"` per clause. The author never counts as the agreeing agent. Accept, reject, waive and retire stay with people: give the user the `dashboard_url` and say "Proposed, not binding."
10. **Known gotcha.** `extra.decided_on` is rejected with 422 although the `ch_create_adr` description lists it (the ADR body has no such field; checked against origin/main on 2026-11-06). Put `decided_on` on each clause instead. Drop this note once the description is fixed.

## Report

Return the ADR id and `dashboard_url`, and three short lists: claims kept, claims dropped or rewritten with the reason (including superseded parts), and defects found (index gaps, anchor states, tool errors). Keep the evidence, not the transcript.

## Rules

- No claim without index evidence; no anchor without an index sighting.
- Never ground from a local checkout, and never hide a defect by editing around it.
- No emojis; no invented ratings, costs, owners or confidence.
