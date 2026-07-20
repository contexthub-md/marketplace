#!/usr/bin/env bash
# Worktree concierge — SubagentStop hook (ContextHub plugin). REPORT-ONLY + safe git-prune.
# Fires when a subagent finishes, in ANY project this plugin is loaded into. It:
#   1. `git worktree prune` — SAFE: only drops admin entries for ALREADY-deleted dirs. Frees ~0 disk, loses nothing.
#   2. Audits every live worktree: clean? merged to the default branch? big regenerable target/ cache?
#   3. Emits a systemMessage listing worktrees SAFE to remove + the exact command. NEVER deletes a worktree dir itself.
# Safety-by-design: no `rm` of any worktree source dir — removal stays a human decision. Only `git worktree prune`
# (bookkeeping) runs automatically. "safe to remove" = clean AND merged to the default branch; anything else = KEEP.
# Reads stdin JSON but requires no field; discovers the repo from the finished agent's cwd, falls back to $PWD.
set -uo pipefail

payload=$(cat 2>/dev/null || true)
# Prefer the finished agent's cwd if present; else current dir.
start_dir=$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$start_dir" ] && [ -d "$start_dir" ] || start_dir="$PWD"

# Resolve the git common dir (shared across all worktrees of this repo).
repo=$(git -C "$start_dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
[ -n "$repo" ] || { echo '{}'; exit 0; }
toplevel=$(git -C "$start_dir" rev-parse --show-toplevel 2>/dev/null)

# default branch (origin/HEAD -> e.g. origin/main or origin/master); fall back to master then main.
def=$(git -C "$start_dir" symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/||')
[ -n "$def" ] || { for b in origin/master origin/main; do git -C "$start_dir" rev-parse --verify "$b" >/dev/null 2>&1 && def="$b" && break; done; }
[ -n "$def" ] || { echo '{}'; exit 0; }

# 1. SAFE prune (removes only entries whose worktree dir is already gone)
pruned=$(git -C "$start_dir" worktree prune -v 2>&1 | grep -c "Removing" || true)

# 2/3. Audit
git -C "$start_dir" fetch origin -q 2>/dev/null || true
safe_list=""; disk_flags=""
while IFS= read -r wt; do
  [ -z "$wt" ] && continue
  [ "$wt" = "$toplevel" ] && continue      # never flag the primary checkout
  [ -d "$wt" ] || continue
  dirty=$(git -C "$wt" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  tip=$(git -C "$wt" rev-parse HEAD 2>/dev/null)
  br=$(git -C "$wt" rev-parse --abbrev-ref HEAD 2>/dev/null)
  tsz=$(du -sh "$wt/target" 2>/dev/null | awk '{print $1}')
  [ -n "$tsz" ] && disk_flags="${disk_flags}  target ${tsz}: rm -rf ${wt}/target\n"
  # "safe to remove" requires ALL of:
  #  - clean working tree
  #  - branch tip reachable from the default branch (merged)
  #  - the branch has AT LEAST ONE commit of its own beyond the default-branch base
  #    that is now IN the default branch (proves it was REAL, since-merged work) --
  #    a branch sitting exactly AT the default tip with 0 unique commits is a base/
  #    scratch branch (e.g. a just-created feature root other agents branch from),
  #    NOT finished work, so we do NOT flag it.
  #  - `git worktree remove --dry-run` succeeds (git itself refuses locked/in-use trees)
  merged="no"; had_work="no"
  if [ -n "$tip" ] && git -C "$start_dir" merge-base --is-ancestor "$tip" "$def" 2>/dev/null; then
    merged="yes"
    mb=$(git -C "$start_dir" merge-base "$tip" "$def" 2>/dev/null)
    # commits this branch contributed (now in def). >0 => real merged work, not a bare base.
    own=$(git -C "$start_dir" rev-list --count "${def}..${tip}" 2>/dev/null || echo 0)
    # if tip==def exactly (own==0 AND tip==def), it's a scratch/base branch -> not "done"
    deftip=$(git -C "$start_dir" rev-parse "$def" 2>/dev/null)
    [ "$tip" != "$deftip" ] && had_work="yes"
  fi
  # locked worktrees are excluded (git refuses to remove them anyway)
  locked=$(git -C "$start_dir" worktree list --porcelain 2>/dev/null | awk -v p="$wt" '$1=="worktree"{cur=$2} $1=="locked" && cur==p{print "y"}')
  if [ "$dirty" = "0" ] && [ "$merged" = "yes" ] && [ "$had_work" = "yes" ] && [ -z "$locked" ]; then
    safe_list="${safe_list}  git worktree remove ${wt}   (branch ${br})\n"
  fi
done < <(git -C "$start_dir" worktree list --porcelain 2>/dev/null | awk '/^worktree/{print $2}')

msg=""
[ "${pruned:-0}" -gt 0 ] 2>/dev/null && msg="worktree-concierge: pruned ${pruned} stale entry(ies).\n"
[ -n "$safe_list" ] && msg="${msg}Worktrees SAFE to remove (clean + merged to ${def}):\n${safe_list}"
[ -n "$disk_flags" ] && msg="${msg}Reclaimable build caches (regenerable):\n${disk_flags}"

[ -z "$msg" ] && { echo '{}'; exit 0; }
printf '%s' "$(jq -nc --arg m "$(printf "%b" "$msg")" '{systemMessage:$m, suppressOutput:true}')"
exit 0
