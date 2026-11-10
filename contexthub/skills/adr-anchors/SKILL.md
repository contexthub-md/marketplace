---
name: adr-anchors
description: Keep ADR governs anchors accurate when code moves. Use when moving, renaming, splitting, merging or deleting files, folders or symbols that accepted ADR clauses govern, or when an ADR anchor is reported broken, stale or ambiguous. Updates the anchors in the same piece of work and re-checks completeness.
---

# Keep ADR Anchors Accurate

A clause governs code through `governs` anchors: `"<owner>/<repo>:<path>"`, optionally `#symbol`, or a folder path covering everything under it. When code moves, an anchor that still points at the old path silently stops protecting the new one. Fix anchors in the same piece of work as the move.

## Prerequisites

An active project (`ch_get_memory_context`; on `NO_PROJECT` run `/contexthub:connect`).

## Workflow

Given: "$ARGUMENTS" (the move, rename, split or deletion, or empty to audit)

### 1. Find affected ADRs before the move

List the old paths and call `ch_list_adrs` with `governs=["<owner>/<repo>:<old path>", ...]` and `tier="L2"`. For each ADR returned, read `ch_get_adr` (`tier="L3"`) and note `rev` and the clauses whose `governs` match the old paths. No hits: nothing to update.

### 2. Make the code change, then decide each anchor

| Change | Anchor update |
|---|---|
| Rename or move | Point to the new path or symbol. |
| Symbol moved to another file | Re-anchor the clause to the new `file#symbol`, and fix any `verification` line that names the old file. |
| Split | Add an anchor for each new location that holds governed behavior; keep the folder if one covers them all. |
| Merge | Replace the old anchors with the merged location. |
| Delete | Remove the anchor. If the rule no longer applies at all, tell the user the clause may need retiring or superseding; that is a human action on the dashboard. |

Anchors use repo-root git paths (`backend/api/...`, not the shorter sub-index path). Confirm every new path with `ch_ocxp_file_exists` (full git path, `exists=true`; `ch_ocxp_find_file` globs can miss it) and every `#symbol` with `ch_ocxp_grep` for the `def` or `class` in the new file; re-index with `ch_trigger_index` if the new code is not indexed yet. Never write a guessed path.

### 3. Apply the update

Call `ch_update_adr` with `action="edit"`, `expected_rev` from `ch_get_adr`, and `changes={"decisions": [...]}` carrying each clause you change as `{id: "D<k>", ..., governs: [...]}` (keep the clause `id`; send the full clause fields from `ch_get_adr`). Use this for proposed clauses. On an accepted clause the text is immutable and changing `governs` is a human action: Brain refuses it for agents with 403 `human_verb_required`. Do not work around it. Instead:

- add a note with `action="note"` (`text`: old path to new path, `ref`: the PR), and
- tell the user which anchors need a human to apply the change on the dashboard, or propose the clause again with `action="propose_clause"` and a `supersedes` link to the old clause (accepted clauses only; use `amends` for a proposed one) so the human can accept the corrected one.

On `409 STALE_REV`, re-read the ADR and retry once.

### 4. Check afterwards

Call `ch_get_adr_completeness`. Read `findings` for anchor-related codes (broken, stale or ambiguous anchors) on the ADRs you touched. Fix what you caused; report what you did not touch. Re-check `anchors` in the `ch_create_adr` or `ch_get_adr` result when available: states are resolved, stale, ambiguous, broken or unknown.

### 5. Report

In the PR description or summary, list: `ADR-<n> D<k>: <old anchor> -> <new anchor>`, plus anything left for the human.

## Rules

- Same piece of work: do not leave anchor fixes for later.
- Never accept, reject or waive; ask the human to use the dashboard.
- Never delete an anchor just to silence a finding when the code still exists elsewhere.
