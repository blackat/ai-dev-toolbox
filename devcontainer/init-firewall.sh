#!/bin/bash
# =============================================================================
# init-firewall.sh — Network firewall for Claude Code sandbox
#
# Based on Anthropic's official init-firewall.sh from:
# https://github.com/anthropics/claude-code/blob/main/.devcontainer/init-firewall.sh
#
# What we added: rule to allow connections to Ollama on Mac host
# (host.docker.internal port 11434)
# =============================================================================
set -e

echo "🔒 Applying firewall rules..."

# ── Flush existing rules ─────────────────────────────────────────────────────
iptables -F OUTPUT 2>/dev/null || true

# ── Allow loopback (localhost) ───────────────────────────────────────────────
iptables -A OUTPUT -o lo -j ACCEPT

# ── Allow already established connections ────────────────────────────────────
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# ── Allow DNS ────────────────────────────────────────────────────────────────
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# ── Allow SSH (for git operations) ───────────────────────────────────────────
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT

# ── Allow HTTPS to Anthropic's whitelisted domains ───────────────────────────
# (same list as Anthropic's official firewall)
for domain in \
    "api.anthropic.com" \
    "statsig.anthropic.com" \
    "sentry.io" \
    "registry.npmjs.org" \
    "github.com" \
    "raw.githubusercontent.com" \
    "objects.githubusercontent.com" \
    "pypi.org" \
    "files.pythonhosted.org" \
    "astral.sh" \
    "storage.googleapis.com"; do
    # Resolve domain to IPs and allow them
    IPs=$(getent ahosts "$domain" 2>/dev/null | awk '{print $1}' | sort -u)
    for ip in $IPs; do
        iptables -A OUTPUT -d "$ip" -j ACCEPT 2>/dev/null || true
    done
done

# ── Allow Ollama on Mac host ──────────────────────────────────────────────────
# host.docker.internal resolves to the Mac's IP from within the container
# We allow port 11434 to private/RFC1918 address ranges (covers Docker's gateway)
# This is our addition — not in Anthropic's original firewall
iptables -A OUTPUT -d 192.168.0.0/16 -p tcp --dport 11434 -j ACCEPT
iptables -A OUTPUT -d 172.16.0.0/12  -p tcp --dport 11434 -j ACCEPT
iptables -A OUTPUT -d 10.0.0.0/8     -p tcp --dport 11434 -j ACCEPT

# If Ollama is running as a sibling container (Linux mode, Architecture B),
# also allow the container network. The same ranges above cover this.

# ── Default deny: block everything else outbound ─────────────────────────────
iptables -A OUTPUT -j DROP

echo "✅ Firewall rules applied"
echo ""
echo "Allowed outbound: DNS, SSH, npm, GitHub, Anthropic API, Ollama (:11434)"
echo "Blocked: everything else"
echo ""
iptables -L OUTPUT --line-numbers -n
