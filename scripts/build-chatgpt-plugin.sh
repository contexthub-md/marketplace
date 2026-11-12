#!/usr/bin/env bash
# Build the ChatGPT / Codex plugin ZIP for the OpenAI plugin portal
# (https://platform.openai.com/plugins).
#
# The ZIP holds the portable Agent Plugins package only: plugin.json, mcp.json
# and skills/. Lifecycle hooks, Claude Code agents and the Claude manifests are
# left out, because the portal rejects packages that contain hooks.
set -euo pipefail

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

OUT="$DIST/contexthub-chatgpt-plugin-$PORTABLE_VERSION.zip"
mkdir -p "$DIST"
rm -f "$OUT"
INCLUDE=(plugin.json mcp.json skills)
[ -d "$PLUGIN/assets" ] && INCLUDE+=(assets)
(cd "$PLUGIN" && zip -qr "$OUT" "${INCLUDE[@]}" -x '*.DS_Store')
echo "Built $OUT"
