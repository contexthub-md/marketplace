#!/usr/bin/env bash
# Build the ChatGPT / Codex plugin ZIP for the OpenAI plugin portal
# (https://platform.openai.com/plugins).
#
# The ZIP holds the portable Agent Plugins package only: plugin.json, mcp.json
# and skills/. Lifecycle hooks, Claude Code agents and the Claude manifests are
# left out, because the portal rejects packages that contain hooks.
#
# Usage: build-chatgpt-plugin.sh [--target prod|dev]
#   prod (default)  the submission package, MCP server https://mcp.contexthub.md/mcp
#   dev             internal test package, MCP server https://dev-mcp.contexthub.md/mcp/
#                   and display name "ContextHub (dev)". Never upload it for review.
set -euo pipefail

TARGET=prod
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --target=*) TARGET="${1#--target=}"; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
case "$TARGET" in
  prod|dev) ;;
  *) echo "Unknown target: $TARGET (use prod or dev)" >&2; exit 2 ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN="$ROOT/contexthub"
DIST="$ROOT/dist"

version() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$1"; }

PORTABLE_VERSION="$(version "$PLUGIN/plugin.json")"
CLAUDE_VERSION="$(version "$PLUGIN/.claude-plugin/plugin.json")"
if [ "$PORTABLE_VERSION" != "$CLAUDE_VERSION" ]; then
  echo "Version mismatch: plugin.json=$PORTABLE_VERSION .claude-plugin/plugin.json=$CLAUDE_VERSION" >&2
  exit 1
fi

python3 - "$PLUGIN" <<'PY'
import json, pathlib, re, sys

plugin = pathlib.Path(sys.argv[1])
errors = []

manifest = json.loads((plugin / "plugin.json").read_text())
interface = manifest.get("extensions", {}).get("com.openai", {}).get("interface", {})
for field in ("displayName", "shortDescription", "longDescription", "developerName", "category"):
    if not interface.get(field):
        errors.append(f"plugin.json: interface.{field} is required")
for field in ("displayName", "shortDescription"):
    if len(interface.get(field, "")) > 30:
        errors.append(f"plugin.json: interface.{field} is longer than 30 characters")
if len(interface.get("longDescription", "")) > 4000:
    errors.append("plugin.json: interface.longDescription is longer than 4000 characters")

servers = json.loads((plugin / "mcp.json").read_text()).get("mcpServers", {})
if len(servers) != 1:
    errors.append("mcp.json: the portal accepts exactly one MCP server per plugin")
for name, server in servers.items():
    if server.get("type") != "streamable-http" or not server.get("url", "").startswith("https://"):
        errors.append(f"mcp.json: {name} must be streamable-http on a public https URL")
    if "${" in server.get("url", ""):
        errors.append(f"mcp.json: {name} url must not use variable interpolation")
    if server.get("headers"):
        errors.append(f"mcp.json: {name} must not set headers")

for skill in sorted((plugin / "skills").glob("*/SKILL.md")):
    text = skill.read_text()
    match = re.match(r"---\n(.*?)\n---\n", text, re.S)
    front = match.group(1) if match else ""
    for key in ("name", "description"):
        if not re.search(rf"^{key}:\s*\S", front, re.M):
            errors.append(f"{skill.relative_to(plugin)}: frontmatter {key} is required")

missing = [f for f in ("websiteURL", "supportURL", "privacyPolicyURL", "termsOfServiceURL", "logo", "composerIcon") if not interface.get(f)]
if missing:
    print("Note: needed for public directory review, not set yet: " + ", ".join(missing))

if errors:
    print("\n".join(errors), file=sys.stderr)
    sys.exit(1)
PY

SUFFIX=""
[ "$TARGET" = dev ] && SUFFIX="-dev"
OUT="$DIST/contexthub-chatgpt-plugin-$PORTABLE_VERSION$SUFFIX.zip"
mkdir -p "$DIST"
rm -f "$OUT"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
INCLUDE=(plugin.json mcp.json skills)
[ -d "$PLUGIN/assets" ] && INCLUDE+=(assets)
for item in "${INCLUDE[@]}"; do cp -R "$PLUGIN/$item" "$STAGE/"; done

if [ "$TARGET" = dev ]; then
  # The trailing slash matters: dev advertises its OAuth resource metadata for /mcp/.
  python3 - "$STAGE" <<'PY'
import json, pathlib, sys

stage = pathlib.Path(sys.argv[1])

mcp_path = stage / "mcp.json"
mcp = json.loads(mcp_path.read_text())
for server in mcp["mcpServers"].values():
    server["url"] = "https://dev-mcp.contexthub.md/mcp/"
mcp_path.write_text(json.dumps(mcp, indent=2) + "\n")

manifest_path = stage / "plugin.json"
manifest = json.loads(manifest_path.read_text())
manifest["extensions"]["com.openai"]["interface"]["displayName"] = "ContextHub (dev)"
manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
PY
fi

(cd "$STAGE" && zip -qr "$OUT" "${INCLUDE[@]}" -x '*.DS_Store')
echo "Built $OUT ($TARGET)"
