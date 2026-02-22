#!/bin/bash
# =============================================================================
# entrypoint.sh
# Applies firewall rules (requires sudo, which node user has for this script only)
# then executes the requested command (default: bash)
# =============================================================================

echo ""
echo "🤖 Claude Code Sandbox (Anthropic base + Ollama support)"
echo "──────────────────────────────────────────────────────────"
echo "  Ollama endpoint : ${ANTHROPIC_BASE_URL}"
echo "  Model           : ${OLLAMA_MODEL}"
echo ""

# Apply firewall (node user has sudo rights for this script only)
sudo /usr/local/bin/init-firewall.sh

echo ""
echo "Ready. To start Claude Code:"
echo "  claude --model \$OLLAMA_MODEL --dangerously-skip-permissions"
echo ""

# Execute the CMD (default: bash)
exec "$@"
