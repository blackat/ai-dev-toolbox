#!/bin/bash
# =============================================================================
# entrypoint.sh
# Applies firewall rules (requires sudo, which node user has for this script only)
# then executes the requested command (default: bash)
# =============================================================================

# Create settings if they don't exist yet (first run)
if [ ! -f /home/node/.claude/settings.json ]; then
    echo ""
    echo "🗳️ Creating Claude settings.json"
    mkdir -p /home/node/.claude
    cp /etc/claude-settings.json /home/node/.claude/settings.json
fi

# Initialise global CLAUDE.md from template if not present
if [ ! -f /home/node/.claude/CLAUDE.md ]; then
    echo "🚀 Copying global Claude md file into /home/node/.claude/CLAUDE.md"
    cp /etc/claude-template.md /home/node/.claude/CLAUDE.md
fi

# Initialise project CLAUDE.md from template if not present
if [ ! -f /workspace/CLAUDE.md ]; then
    echo "🚀 Copying project template Claude md file"
    # Detect project type and copy the right template
    if [ -f /workspace/package.json ]; then
        echo "🧑🏼‍💻 Copying Node template into /workspace/CLAUDE.md"
        cp /etc/claude-template-node.md /workspace/CLAUDE.md
    elif [ -f /workspace/requirements.txt ] || [ -f /workspace/pyproject.toml ]; then
        echo "🧑🏼‍💻 Copying Python template into /workspace/CLAUDE.md"
        cp /etc/claude-template-python.md /workspace/CLAUDE.md
    else
        echo "🧑🏼‍💻 Copying default template into /workspace/CLAUDE.md"
        cp /etc/claude-template-default.md /workspace/CLAUDE.md
  fi
fi

# Global skills — personal habits
if [ ! -d /home/node/.claude/skills ]; then
    echo "🍳 Copying global skills — personal habits into /home/node/.claude/skills/"
    mkdir -p /home/node/.claude/skills
    cp /etc/claude-skills/global/* /home/node/.claude/skills/
fi

# Project skills — team conventions
if [ ! -d /workspace/.claude/skills ]; then
    echo "🍳 Copying project skills — team conventions into /workspace/.claude/skills/"
    mkdir -p /workspace/.claude/skills
    cp /etc/claude-skills/project/* /workspace/.claude/skills/
fi

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
