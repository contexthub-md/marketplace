---
name: branch-search
description: Index and search a Git branch using ContextHub code intelligence. Imports the branch code if needed, triggers OCXP delta indexing, then runs grep/search/warmup scoped to the branch. Use when the user says "search branch X", "index branch X", "explore branch X", "what changed on branch X", "grep on branch X", or wants to find code that only exists on a feature branch. Also use when the user provides a branch name and wants to understand what's different from main.
---

# Branch Index + Search with ContextHub

Import, index, and search a Git branch -- see branch-specific code that doesn't exist on main.

## Prerequisites

An active project with at least one indexed repository is required. If you get NO_PROJECT or OCXP_UNAVAILABLE errors, run `/contexthub:connect` first.

## Workflow

Given: "$ARGUMENTS" (branch name, optionally followed by a search query or repo URL)

### 1. Parse Input

Extract from $ARGUMENTS:
- **branch** (required): the Git branch name (e.g., `feat/auth`, `fix/login-bug`)
- **query** (optional): a search term or grep pattern after the branch name
- **repo_url** (optional): a GitHub URL if the user wants to import a specific repo

Examples:
- `feat/auth` -- just the branch, will show warmup stats
- `feat/auth authentication middleware` -- branch + search query
- `feat/auth https://github.com/org/repo` -- branch + repo to import

### 2. Check If Branch Is Already Indexed

Call `ch_list_branch_indexes` to see if the branch already has a code intelligence index.

- If the branch is listed: skip to **Step 5** (the index is ready)
- If not listed: continue to **Step 3**

### 3. Import the Branch (if needed)

The branch code needs to be downloaded and registered before indexing. This step ensures the repo registry knows about the branch.

If the user provided a repo URL:
```
ch_import_repo(github_url=<url>, branch=<branch>)
```

If no URL was provided, tell the user:
> "Branch `<branch>` hasn't been indexed yet. To index it, I need the GitHub URL of the repo that has this branch. Which repo should I import?"

Wait for the user to provide the URL, then call `ch_import_repo`.

Poll `ch_get_index_status(job_id)` until the import completes. Show progress:
```
Downloading branch code... (25%)
Uploading to S3... (60%)
Complete!
```

### 4. Trigger Branch Indexing

Once the branch code is in S3 and registered, trigger the OCXP delta index:

```
ch_trigger_index(branch=<branch>)
```

Poll `ch_get_index_status(job_id)` until indexing completes. Show progress:
```
Building branch delta index... (40%)
Generating embeddings... (75%)
Complete!
```

After completion, call `ch_reload_index` so the OCXP engine picks up the new branch graph.

### 5. Show Branch Overview

Call `ch_ocxp_warmup(branch=<branch>)` to get branch-specific stats. Present to the user:

- Languages and file count
- Total entities (functions, classes, etc.)
- Module tree structure
- How the branch differs from main (different file/node counts indicate branch-specific content)

### 6. Search the Branch

If the user provided a **search query** in their input:

1. Try `ch_ocxp_grep(pattern=<query>, branch=<branch>)` for exact matches
2. Try `ch_ocxp_search(query=<query>, branch=<branch>)` for semantic matches
3. Present combined results, highlighting which files are branch-specific

If no query was provided, tell the user the branch is ready:
> "Branch `<branch>` is indexed and ready. You can now use any OCXP tool with branch context. Try:
> - `ch_ocxp_grep(pattern='...', branch='<branch>')` for text search
> - `ch_ocxp_search(query='...', branch='<branch>')` for semantic search
> - `ch_ocxp_file_read(path='...', branch='<branch>')` to read branch files"

### 7. Follow-up Exploration

All OCXP tools support the `branch` parameter. For deeper exploration after the initial search:

- `ch_ocxp_entity(id, branch=<branch>)` -- entity details
- `ch_ocxp_file_read(path, branch=<branch>)` -- read source code
- `ch_ocxp_references(id, branch=<branch>)` -- find callers/users
- `ch_ocxp_route(task, branch=<branch>)` -- navigate by task

Pass the branch parameter to every subsequent OCXP call in the conversation to stay in branch context.

## Important Notes

- Branch indexing builds a delta on top of the main branch index. The branch graph contains main + branch changes.
- Grep results on a branch show the branch version of modified files and main's version of unchanged files.
- Semantic search on a branch overlays branch embeddings on main embeddings -- branch results take priority.
- If branch indexing fails with "No repos have branch X", the branch hasn't been downloaded yet. Go back to Step 3.

## Examples

```
/contexthub:branch-search feat/oauth-implementation
/contexthub:branch-search fix/memory-leak database connection pool
/contexthub:branch-search feat/new-api https://github.com/org/backend
```
