# =============================================================================
# Dockerfile — Claude Code Sandbox with Ollama Support
# Extends: Anthropic's official devcontainer base (node:20 + firewall setup)
#
# What this adds on top of Anthropic's image:
#   - Python 3 + pip (not in official image)
#   - vim (not in official image, nano is their default)
#   - Ollama environment variables pre-configured
#   - Firewall rule for host.docker.internal:11434 (Ollama on Mac host)
#   - Entrypoint that applies firewall then drops into shell
# =============================================================================

# ─────────────────────────────────────────────
# Anthropic's official base: node:20 (Debian slim)
# with the same packages they use in their devcontainer:
#   less, git, procps, sudo, fzf, zsh, man-db, unzip,
#   gnupg2, gh, iptables, ipset, iproute2, dnsutils, aggregate, jq
# and the same user setup: node user with sudo for firewall only
# ─────────────────────────────────────────────
FROM node:20

ARG CLAUDE_CODE_VERSION=latest
ARG TZ=UTC
ENV TZ="$TZ"

# ── Step 1: Install Anthropic's exact package list + our additions ──────────
# Anthropic installs: less git procps sudo fzf zsh man-db unzip gnupg2
#                     gh iptables ipset iproute2 dnsutils aggregate jq
# We add:            python3 python3-pip vim
RUN apt-get update && apt-get install -y \
    less \
    git \
    procps \
    sudo \
    fzf \
    zsh \
    man-db \
    unzip \
    gnupg2 \
    gh \
    iptables \
    ipset \
    iproute2 \
    dnsutils \
    aggregate \
    jq \
    # ── our additions ──────────────────────────────────────────────────────
    python3 \
    python3-pip \
    vim \
    curl \
    # ───────────────────────────────────────────────────────────────────────
    && rm -rf /var/lib/apt/lists/*

# ── Step 2: npm global dir — same as Anthropic's setup ─────────────────────
RUN mkdir -p /usr/local/share/npm-global && \
    chown -R node:node /usr/local/share

ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# ── Step 3: Install Claude Code — same as Anthropic's image ────────────────
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# ── Step 4: Firewall script setup — same sudo pattern as Anthropic ──────────
# Anthropic's approach: node user gets passwordless sudo for firewall script only
# This is safer than running the whole container as root
COPY init-firewall.sh /usr/local/bin/init-firewall.sh
USER root
RUN chmod +x /usr/local/bin/init-firewall.sh && \
    echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" \
    > /etc/sudoers.d/node-firewall && \
    chmod 0440 /etc/sudoers.d/node-firewall

# ── Step 5: Persist bash/zsh history — same as Anthropic's devcontainer ─────
RUN mkdir -p /commandhistory && \
    touch /commandhistory/.bash_history && \
    touch /commandhistory/.zsh_history && \
    chown -R node:node /commandhistory

ENV HISTFILE=/commandhistory/.zsh_history

# ── Step 6: Copy other files ────────────────────────────────────────────────
# Copy Claude settings
COPY claude-settings.json /etc/claude-settings.json
# Preferences (persists in claude-config volume) coding style, 
# workflow rules, personal habits
COPY claude-memory/global/claude-template.md /etc/claude-template.md
COPY claude-memory/project/claude-template-default.md /etc/claude-template-default.md
COPY claude-memory/project/claude-template-node.md /etc/claude-template-node.md
COPY claude-memory/project/claude-template-python.md /etc/claude-template-python.md

# Copy skill templates
COPY claude-skills/global/  /etc/claude-skills/global/
COPY claude-skills/project/ /etc/claude-skills/project/



# ── Step 7: Workspace setup ─────────────────────────────────────────────────
RUN mkdir -p /workspace && chown -R node:node /workspace
WORKDIR /workspace

# ── Step 8: Ollama environment — our addition ───────────────────────────────
# Pre-configure to point at Ollama on Mac host (via host.docker.internal)
# Override ANTHROPIC_BASE_URL in docker-compose.yml if using Linux container Ollama
ENV ANTHROPIC_BASE_URL=http://host.docker.internal:11434
ENV ANTHROPIC_AUTH_TOKEN=ollama
ENV ANTHROPIC_API_KEY=
# Default model — override in docker-compose.yml or at runtime
ENV OLLAMA_MODEL=qwen3-coder:30b-a3b

# ── Step 9: Drop to non-root node user — same as Anthropic's image ──────────
USER node

# ── Step 10: Entrypoint — apply firewall then open shell ────────────────────
# Anthropic's devcontainer runs the firewall script via postStartCommand in
# devcontainer.json. For Docker Compose (no devcontainer.json), we do it here.
COPY --chown=node:node entrypoint.sh /usr/local/bin/entrypoint.sh
# Note: chmod needs root, so we do this before USER node
USER root
RUN chmod +x /usr/local/bin/entrypoint.sh
USER node

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
