---
name: import
description: Import a GitHub repository into ContextHub -- downloads code, creates a project, and triggers code intelligence indexing. Use when the user wants to add a new repo, says "import", "add this repo", "index this codebase", or pastes a GitHub URL.
---

# Import a Repository into ContextHub

Import a GitHub repository, create a project, download the code, and trigger OCXP code intelligence indexing -- all in one flow.

## Workflow

Given: "$ARGUMENTS" (GitHub URL or owner/repo format)

### 1. Import

Call `ch_import_repo` with the GitHub URL or owner/repo.

- The tool automatically creates a project (or links to an existing one)
- It queues a download + indexing job
- Returns a `job_id` for tracking progress

If the repository is already imported, the tool returns `already_exists` with the existing project ID. Use `/contexthub:connect` to connect to it instead.

### 2. Wait for Indexing

Poll `ch_get_index_status(job_id)` every few seconds until the job completes. Show progress updates to the user:

```
Downloading repository... (25%)
Indexing code graph... (60%)
Building embeddings... (85%)
Complete!
```

### 3. Reload

Call `ch_reload_index` to make the OCXP engine pick up the new code graph.

### 4. Verify

Call `ch_ocxp_warmup` to confirm the index is live. Show the user:

- Repository name and branch
- Number of files, functions, and classes indexed
- Code graph stats

### 5. Set Context

Call `ch_set_project` with the new project ID so all subsequent tools use it automatically.

## Examples

```
/contexthub:import https://github.com/bujoo/paperclip
/contexthub:import anthropics/claude-code
/contexthub:import https://github.com/Sonic-Web-Dev/contexthub-brain/tree/develop
```
