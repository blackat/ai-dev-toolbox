# Claude Code + Ollama — Docker Setup

Extends Anthropic's official devcontainer base with Ollama support for fully local, private AI coding.

## File Structure

```
your-project/
├── docker-compose.yml          ← start here
├── .env                        ← optional overrides (never commit)
├── workspace/                  ← YOUR CODE (only thing Claude can touch)
└── devcontainer/
    ├── Dockerfile              ← extends Anthropic's base + adds Python/vim/Ollama env
    ├── init-firewall.sh        ← Anthropic's firewall + Ollama port rule
    └── entrypoint.sh           ← applies firewall, prints startup info, opens shell
```

## Quick Start (Mac)

```bash
# 1. Start Ollama natively on your Mac (uses Apple Silicon GPU)
brew install ollama
ollama serve &
ollama pull qwen3-coder:30b-a3b

# 2. Customise your project code location in .env using MY_WORKSPACE environment variable.
# 2a. By default ./workspace, init your project there
cd workspace && git init && git add . && git commit -m "pre-claude checkpoint"
# 2b. Set the folder of your existing project .env
MY_WORKSPACE=''


# 3. Build and start
docker compose up --build -d

# 4. Enter the sandbox
docker compose exec claude-code bash

# 5. Inside the container — start coding
claude --model qwen3-coder:30b-a3b --dangerously-skip-permissions
```

## What's Different from Anthropic's Official Devcontainer

| Feature | Anthropic's original | This image |
|---|---|---|
| Base image | `node:20` | Same (`node:20`) |
| User | `node` (non-root) | Same |
| Firewall | ✅ Whitelist-only | ✅ Same + Ollama port added |
| sudo for firewall | ✅ | ✅ Same pattern |
| Claude Code | ✅ | ✅ Same |
| Python 3 | ❌ | ✅ Added |
| vim | ❌ (nano only) | ✅ Added |
| Ollama env vars | ❌ | ✅ Pre-configured |
| Shell history persistence | ✅ | ✅ Same |
| Intended workflow | VS Code devcontainer | Docker Compose CLI |

## Security Measures Applied

- Non-root `node` user (same as Anthropic's official image)
- `node` has sudo rights **only** for the firewall script
- Outbound firewall: whitelist-only (npm, GitHub, Anthropic API, Ollama on port 11434)
- `no-new-privileges` security option
- All Linux capabilities dropped except NET_ADMIN, CHOWN, DAC_OVERRIDE
- Only `./workspace/` mounted — no home dir, no SSH keys, no credentials
- `~/.gitconfig` mounted read-only (name/email only, not keys)
- Memory and CPU limits set

## Switching to Anthropic Cloud

If you want to use Anthropic's API instead of local Ollama:

```bash
# In docker-compose.yml, change environment to:
- ANTHROPIC_BASE_URL=   # leave empty
- ANTHROPIC_AUTH_TOKEN= # leave empty  
- ANTHROPIC_API_KEY=sk-ant-your-key-here
```

Then inside the container, run claude normally without `--model`.

## FAQ

### What is the flow?

```
WHAT A "MODEL" IS AT RUNTIME:
─────────────────────────────
Model file (.gguf)     → stored on disk (volume or host filesystem)
Ollama process         → loads model into RAM/VRAM, does inference
Claude Code            → sends text prompt → receives text response
                         (Claude Code never "runs" the model itself)

FLOW:
Claude Code → HTTP request → Ollama → loads model → generates tokens → response
```

