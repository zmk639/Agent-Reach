#!/bin/bash
# SessionStart hook for Claude Code cloud sessions: installs Agent Reach,
# dev tools, mcporter + Exa search, and the yt-dlp JS runtime config.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

# Agent Reach CLI plus lint/test tooling
python3 -m pip install -q --root-user-action=ignore -e ".[dev]"

# mcporter + Exa semantic search
if ! command -v mcporter >/dev/null 2>&1; then
  npm install -g --silent mcporter
fi
if ! grep -q '"exa"' "$HOME/.mcporter/mcporter.json" 2>/dev/null; then
  mcporter config add exa https://mcp.exa.ai/mcp --scope home
fi

# yt-dlp needs a JS runtime for YouTube
mkdir -p "$HOME/.config/yt-dlp"
grep -qxF -- '--js-runtimes node' "$HOME/.config/yt-dlp/config" 2>/dev/null \
  || printf '%s\n' '--js-runtimes node' >> "$HOME/.config/yt-dlp/config"

# Route Node (mcporter) through the cloud egress proxy
if [ -n "${CLAUDE_ENV_FILE:-}" ] && [ -f /root/.ccr/ca-bundle.crt ]; then
  echo 'export NODE_USE_ENV_PROXY=1' >> "$CLAUDE_ENV_FILE"
  echo 'export NODE_EXTRA_CA_CERTS=/root/.ccr/ca-bundle.crt' >> "$CLAUDE_ENV_FILE"
fi
