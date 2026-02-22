#!/bin/bash
# =============================================================================
# entrypoint.sh
# Applies firewall rules (requires sudo, which node user has for this script only)
# then executes the requested command (default: bash)
# =============================================================================


# Claude specific
CLAUDE_DIR="/home/node/.claude"
CLAUDE_GLOBAL_SKILLS="/home/node/.claude/skills"
CLAUDE_PROJECT_SKILLS="/workspace/.claude/skills"
CLAUDE_JSON="/home/node/.claude.json"

# Workspace specific
WORKSPACE_DIR="/workspace"


echo ""
echo "──────────────────────────────────────────────────────────"
echo "  ⚙️  Configuration"
echo "──────────────────────────────────────────────────────────"

# Create settings if they don't exist yet (first run)
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

if [ ! -f "$SETTINGS_FILE" ]; then
    echo "  [config]  🗳️  Creating Claude $SETTINGS_FILE"
    mkdir -p "$CLAUDE_DIR"
    cp /etc/claude-settings.json "$SETTINGS_FILE"
else
    echo "  [config]  ✅ File $SETTINGS_FILE already exist, untouched"
fi

if [ ! -f "$CLAUDE_JSON" ]; then
    echo ""
    echo "  [config]  🗳️  Creating Claude $CLAUDE_JSON"
    cp /etc/claude-dot.json "$CLAUDE_JSON"
else
    echo "  [config]  ✅ .claude.json already exists, untouched"
fi


echo ""
echo "──────────────────────────────────────────────────────────"
echo "  🧠  Memory"
echo "──────────────────────────────────────────────────────────"

# Initialise global CLAUDE.md from template if not present
CLAUDE_MEMORY_GLOBAL_FILE="$CLAUDE_DIR/CLAUDE.md"

if [ ! -f "$CLAUDE_MEMORY_GLOBAL_FILE" ]; then
    echo "  [memory]  📝 Copying global Claude md file into $CLAUDE_MEMORY_GLOBAL_FILE"
    cp /etc/claude-template.md $CLAUDE_MEMORY_GLOBAL_FILE
else
    echo "  [memory]  ✅ File $CLAUDE_MEMORY_GLOBAL_FILE already exist, untouched"
fi

# Initialise project CLAUDE.md from template if not present
CLAUDE_MEMORY_PROJECT_FILE="$WORKSPACE_DIR/CLAUDE.md"
if [ ! -f "$CLAUDE_MEMORY_PROJECT_FILE" ]; then
    echo "  [memory]  📝  Copying project template Claude md file"
    # Detect project type and copy the right template
    if [ -f /workspace/package.json ]; then
        echo "  [memory]  📝  Copying Node template into $CLAUDE_MEMORY_PROJECT_FILE"
        cp /etc/claude-template-node.md $CLAUDE_MEMORY_PROJECT_FILE
    elif [ -f /workspace/requirements.txt ] || [ -f /workspace/pyproject.toml ]; then
        echo "  [memory]  📝  Copying Python template into $CLAUDE_MEMORY_PROJECT_FILE"
        cp /etc/claude-template-python.md $CLAUDE_MEMORY_PROJECT_FILE
    else
        echo "  [memory]  📝  Copying default template into $CLAUDE_MEMORY_PROJECT_FILE"
        cp /etc/claude-template-default.md $CLAUDE_MEMORY_PROJECT_FILE
  fi
else
    echo ""
    echo "  [memory]  ✅ File $CLAUDE_MEMORY_PROJECT_FILE already exist, untouched"
fi


echo ""
echo "──────────────────────────────────────────────────────────"
echo "  🎯  Skills"
echo "──────────────────────────────────────────────────────────"

# Global skills — personal habits
CLAUDE_SKILLS_GLOBAL_FILE="$CLAUDE_GLOBAL_SKILLS/CLAUDE.md"

if [ ! -d "$CLAUDE_GLOBAL_SKILLS" ]; then
    echo "  [skills]  📂 Copying global skills — personal habits into $CLAUDE_GLOBAL_SKILLS"
    mkdir -p $CLAUDE_GLOBAL_SKILLS
    cp /etc/claude-skills/global/* $CLAUDE_GLOBAL_SKILLS
else
    echo ""
    echo "  [skills]  ✅ Global skills $CLAUDE_SKILLS_GLOBAL_FILE already exist, untouched"
fi

# Project skills — team conventions
if [ ! -d "$CLAUDE_PROJECT_SKILLS" ]; then
    echo "  [skills]  📂  Copying project skills — team conventions into $CLAUDE_PROJECT_SKILLS"
    mkdir -p $CLAUDE_PROJECT_SKILLS
    cp /etc/claude-skills/project/* $CLAUDE_PROJECT_SKILLS
else
    echo ""
    echo "  [skills]  ✅ Project skills $CLAUDE_PROJECT_SKILLS already exist, untouched"
fi

echo ""
echo "──────────────────────────────────────────────────────────"
echo "  🤖 Claude Code Sandbox (Anthropic base + Ollama support)"
echo "──────────────────────────────────────────────────────────"
echo "  Ollama endpoint : ${ANTHROPIC_BASE_URL}"
echo "  Model           : ${OLLAMA_MODEL}"
echo ""

echo ""
echo "──────────────────────────────────────────────────────────"
echo "  🔥 Apply firewall (node user has sudo rights for this script only)"
echo "──────────────────────────────────────────────────────────"

sudo /usr/local/bin/init-firewall.sh

echo ""
echo "──────────────────────────────────────────────────────────"
echo "  🚀 Ready. To start Claude Code:"
echo "──────────────────────────────────────────────────────────"
echo "  claude --model \$OLLAMA_MODEL --dangerously-skip-permissions"
echo "  or ai . if function ai has been added to ./zshrc"
echo ""

# Execute the CMD (default: bash)
exec "$@"
