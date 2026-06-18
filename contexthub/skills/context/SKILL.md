---
name: context
description: Read, write, list, or delete documents in ContextHub for any content type -- mission docs, project docs, SOPs, artifacts, context, sessions. Use when you need to attach/save/upload a doc to a mission or project, store a plan or notes in ContextHub, put a file where it shows up in a mission's docs, list or read stored context documents, or remove one. Also use when the user says "attach this to the mission", "save this doc", "add to project docs", "write to context", or "what docs are on this mission".
---

# Context Document Management

ContextHub stores documents (mission docs, project docs, SOPs, artifacts, etc.) in a server-side content store with automatic metadata + Bedrock KB indexing. Manage them with the generic `ch_*_context` MCP tools.

## Core rule

**To put a document into ContextHub, use `ch_write_context` -- never write to S3 directly and never fall back to `ch_create_memo`.** Raw S3 bypasses the metadata sidecar, frontmatter, and KB indexing the tools run for you. A memo is not a document -- it won't appear in the mission/project docs.

## The tools

| Tool | Use for |
|------|---------|
| `ch_list_context_types` | Discover valid `content_type` values (mission, project, sop, artifact, context, session, ...) -- includes dynamic provider types. Call when unsure. |
| `ch_write_context(content_type, path, content, ...)` | Create/overwrite a document. Runs metadata sidecar + frontmatter + KB index. |
| `ch_read_context(content_type, path, detail=)` | Read a document. `detail="summary"` strips the body (token-saving). |
| `ch_list_context(content_type, path=, recursive=)` | List documents of a type, optionally under a path prefix. |
| `ch_delete_context(content_type, path, recursive=, confirm=)` | Delete a document. Recursive deletes REQUIRE `confirm=True`. |

## Path convention

Paths are namespaced by the entity ID under the content type:

- Mission doc: `content_type="mission"`, `path="{mission_id}/docs/your-file.md"`
- Project doc: `content_type="project"`, `path="{project_id}/docs/your-file.md"`
- SOP / artifact / context: `content_type="sop"` (etc.), `path="..."`

Pass `mission_id` / `project_id` as params too -- they enrich the sidecar metadata. Markdown files get Obsidian frontmatter injected automatically.

## Workflow

1. **Unsure of the type?** Call `ch_list_context_types`.
2. **Write:** read the source content (e.g. with `Read`), then `ch_write_context(content_type, path, content, mission_id=..., project_id=...)`.
3. **Verify:** `ch_list_context` or `ch_read_context` to confirm it landed.

## Examples

```
# Attach a plan to a mission's docs
ch_write_context(content_type="mission",
                 path="30ed80e8.../docs/10x-memory-plan.md",
                 content="<file contents>",
                 mission_id="30ed80e8...", project_id="2af3ec57...")

# List a mission's docs
ch_list_context(content_type="mission", path="30ed80e8.../docs/", recursive=True)

# Read one (summary = metadata only, no body)
ch_read_context(content_type="mission", path="30ed80e8.../docs/plan.md", detail="summary")
```

## Performance: fast vs verified write

`ch_write_context` defaults to `wait_for_index=True, verify_access=True` -- it blocks until KB indexing is verified (can take ~30s, and may report `indexed: false` if indexing lags). For bulk writes or when you don't need immediate KB searchability, pass **both** `wait_for_index=False` AND `verify_access=False` for the fast async path.

## Common mistakes

- **Falling back to `ch_create_memo`** because you didn't find a doc-write tool -- use `ch_write_context`. Memos are findings/alerts, not documents.
- **Writing raw to S3** -- bypasses metadata + KB indexing; the doc won't be searchable or properly tagged.
- **Forgetting `confirm=True`** on a recursive delete -- the tool refuses without it.
- **Treating `detail="summary"` as a bandwidth saver** -- it fetches the full doc then strips the body client-side; it only reduces tokens shown to the model, not transfer.
- **Guessing `content_type`** -- call `ch_list_context_types` if unsure.
