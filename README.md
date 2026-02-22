# Claude Code + Ollama — Docker Setup

<!-- toc -->

- [File Structure](#file-structure)
- [Quick Start (Mac)](#quick-start-mac)
- [What's Different from Anthropic's Official Devcontainer](#whats-different-from-anthropics-official-devcontainer)
- [Security Measures Applied](#security-measures-applied)
- [Full Architecture Diagram](#full-architecture-diagram)
- [Security Checklist](#security-checklist)
- [The Cluade → Ollama Flow](#the-cluade-%E2%86%92-ollama-flow)
- [Claude Code settings.json — Key Reference](#claude-code-settingsjson--key-reference)
  * [Key Explanations](#key-explanations)
    + [`permissions.defaultMode: "bypassPermissions"`](#permissionsdefaultmode-bypasspermissions)
    + [`theme: "dark"`](#theme-dark)
    + [`skipDangerousModePermissionPrompt: true`](#skipdangerousmodepermissionprompt-true)
    + [`hasCompletedProjectOnboarding: true`](#hascompletedprojectonboarding-true)
    + [`hasAcknowledgedCaveats: true`](#hasacknowledgedcaveats-true)
  * [The Remaining Prompt — Startup Theme](#the-remaining-prompt--startup-theme)
  * [Two Config Files — Know the Difference](#two-config-files--know-the-difference)
  * [How to chnage the Claude settings.json](#how-to-chnage-the-claude-settingsjson)
  * [Summary](#summary)
- [Claude Memory and Skills](#claude-memory-and-skills)
  * [Claude Memory: CLAUDE.md](#claude-memory-claudemd)
    + [Two-file Strategy (recommended)](#two-file-strategy-recommended)
  * [Claude Skills: SKILL.md](#claude-skills-skillmd)
    + [What a Skill is](#what-a-skill-is)
    + [How to use them?](#how-to-use-them)
    + [Practical example](#practical-example)
- [Start Claude automatically](#start-claude-automatically)
- [MacOS Specific](#macos-specific)
  * [Terminal would like to access data from other apps](#terminal-would-like-to-access-data-from-other-apps)
    + [What this prompt actually means](#what-this-prompt-actually-means)
  * [Can I Run Ollama from a Container?](#can-i-run-ollama-from-a-container)
- [Run Everything in Container](#run-everything-in-container)
  * [Can Claude Code and Ollama Containers Work Together?](#can-claude-code-and-ollama-containers-work-together)
    + [Architecture A: Ollama on host, Claude Code in container (recommended for Mac)](#architecture-a-ollama-on-host-claude-code-in-container-recommended-for-mac)
    + [Architecture B: Both in containers (recommended for Linux/Windows with GPU)](#architecture-b-both-in-containers-recommended-for-linuxwindows-with-gpu)
  * [What Are the Advantages?](#what-are-the-advantages)
    + [Privacy](#privacy)
    + [Cost](#cost)
    + [Safety (container isolation)](#safety-container-isolation)
    + [Consistency](#consistency)
    + [Offline capability](#offline-capability)
  * [How Are the Models Actually Run? Inside a Container or on My Local Env?](#how-are-the-models-actually-run-inside-a-container-or-on-my-local-env)
    + [If Ollama runs on your Mac (Architecture A):](#if-ollama-runs-on-your-mac-architecture-a)
    + [If Ollama runs in a container (Architecture B):](#if-ollama-runs-in-a-container-architecture-b)

<!-- tocstop -->

Extends Anthropic's official devcontainer base with Ollama support for fully local, private AI coding.

## File Structure

```
├── README.md                                   ← This file
├── devcontainer
│   ├── Dockerfile                              ← extends Anthropic's base + adds Python/vim/Ollama env
│   ├── claude-memory                           ← Claude memory
│   │   ├── global                              ← global (applies to all projects)
│   │   │   └── claude-template.md
│   │   └── project                             ← project (applies to a specific project language)
│   │       ├── claude-template-default.md
│   │       ├── claude-template-node.md
│   │       └── claude-template-python.md
│   ├── claude-settings.json                    ← Claude settings.json
│   ├── claude-skills                           ← Claude skills
│   │   ├── global
│   │   │   ├── code-review.md
│   │   │   ├── git-workflow.md
│   │   │   └── test-style.md
│   │   └── project
│   │       └── component-structure.md
│   ├── entrypoint.sh                           ← applies firewall, prints startup info, opens shell
│   └── init-firewall.sh                        ← Anthropic's firewall + Ollama port rule
├── docker-compose.yml                          ← start here    
├── .env                                        ← optional overrides (never commit)
└── workspace                                   ← YOUR CODE (only thing Claude can touch)
```


## Quick Start (Mac)

```bash
# 1. Start Ollama natively on your Mac (uses Apple Silicon GPU)
brew install ollama
ollama serve &
ollama pull qwen3-coder:30b

# 2. Customise your project code location in .env using MY_WORKSPACE environment variable.
# 2a. By default ./workspace, init your project there
cd workspace && git init && git add . && git commit -m "pre-claude checkpoint"
# 2b. Set the folder of your existing project .env
MY_WORKSPACE=''


# 3. Build and start
docker compose up --build -d

# 4. Enter the sandbox
docker compose exec -it claude-code bash

# 5. Inside the container — start coding, the model must have been pulled
claude --model qwen3-coder:30b --dangerously-skip-permissions
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


## Full Architecture Diagram

```
YOUR MAC
│
├── Ollama (native, Apple Silicon GPU via Metal)
│   ├── Model: qwen3-coder:30b loaded in unified memory
│   └── API: localhost:11434
│
└── Docker Engine
    │
    └── Network: ai-network (isolated bridge)
        │
        └── claude-code-sandbox container
            ├── Runs as: non-root user "claude"
            ├── Filesystem: read-only (except /workspace)
            ├── Firewall: whitelist-only outbound rules
            ├── Memory limit: 4GB
            ├── No privilege escalation
            │
            ├── /workspace ◄──── bind mount ────► ./workspace/ on your Mac
            │   (your code lives here — only thing Claude can touch)
            │
            └── Claude Code
                └── HTTP → host.docker.internal:11434 → Ollama
                    (all inference happens on your Mac GPU)

WHAT STAYS ON YOUR MAC:
  ✅ All model weights
  ✅ All inference (GPU)
  ✅ Your other projects (not mounted)
  ✅ SSH keys, .aws, .env files (not mounted)
  ✅ All other files outside ./workspace/

WHAT HAPPENS IF CLAUDE GOES WRONG:
  Deletes files  → only affects ./workspace/ (use git to recover)
  Runs bad cmd   → only inside container (restart to fix)
  Network attack → firewall blocks it
  Escapes sandbox → very hard (non-root, dropped caps, read-only FS)
```


## Security Checklist

```
CONTAINER HARDENING                          STATUS
─────────────────────────────────────────   ──────
Non-root user                               ✅
Read-only root filesystem                   ✅
No new privileges                           ✅
All Linux capabilities dropped              ✅
Only necessary caps added back              ✅
Memory + CPU limits                         ✅
Network firewall (whitelist outbound)       ✅
Only project folder mounted                 ✅
No home dir, credentials, or keys mounted   ✅

MODEL & DATA PRIVACY                         STATUS
─────────────────────────────────────────   ──────
Models run locally (no cloud inference)     ✅
Code never sent to Anthropic                ✅
No API key required                         ✅
Works fully offline                         ✅

SAFETY NET                                   STATUS
─────────────────────────────────────────   ──────
Git checkpoints before every session        ✅ (your responsibility)
Named volumes for model persistence         ✅
Easy container reset                        ✅


## Switching to Anthropic Cloud

If you want to use Anthropic's API instead of local Ollama:

```bash
# In docker-compose.yml, change environment to:
- ANTHROPIC_BASE_URL=   # leave empty
- ANTHROPIC_AUTH_TOKEN= # leave empty  
- ANTHROPIC_API_KEY=sk-ant-your-key-here
```

Then inside the container, run claude normally without `--model`.


## The Cluade → Ollama Flow

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


## Claude Code settings.json — Key Reference

The shipped file:

```json
{
  "permissions": {
    "defaultMode": "bypassPermissions"
  },
  "theme": "dark",
  "skipDangerousModePermissionPrompt": true,
  "hasCompletedProjectOnboarding": true,
  "hasAcknowledgedCaveats": true
}
```


### Key Explanations

#### `permissions.defaultMode: "bypassPermissions"`
Sets Claude Code to never ask for approval before running commands, editing files, or executing anything. The four possible values are:

| Value | Behaviour |
|---|---|
| `default` | Ask every time |
| `acceptEdits` | Auto-approve file edits only |
| `plan` | Read-only, no actions at all |
| `bypassPermissions` | Approve everything automatically |

Safe inside a container because the blast radius is limited to the mounted workspace.


#### `theme: "dark"`
Sets the color scheme of the Claude Code UI. Goes into `settings.json` but does **not** suppress the startup theme prompt — that is controlled by `~/.claude.json` instead. Partially redundant with what you need to put in `claude.json`.

#### `skipDangerousModePermissionPrompt: true`
Suppresses the "you are entering bypass mode, do you accept responsibility" confirmation screen — the one where pressing Enter did nothing. This is what fixed that specific issue.

#### `hasCompletedProjectOnboarding: true`
Tells Claude Code that the project onboarding flow has already been completed, so it skips the first-run walkthrough that appears when Claude Code detects a new project for the first time.

#### `hasAcknowledgedCaveats: true`
Marks the security caveats screen as already acknowledged — the warning that explains the risks of running in bypass mode. Without this, Claude Code shows that warning on first run even if the permission prompt is already suppressed.


### The Remaining Prompt — Startup Theme

The startup theme prompt (dark/light terminal selector) lives in a **different file**:

```
~/.claude.json          ← NOT ~/.claude/settings.json
```

To suppress it, seed `~/.claude.json` with:

```json
{
  "hasCompletedOnboarding": true,
  "theme": "dark"
}
```


### Two Config Files — Know the Difference

| File | Purpose |
|---|---|
| `~/.claude/settings.json` | Permissions, tools, environment, behaviour |
| `~/.claude.json` | Onboarding state, theme preference, OAuth session, per-project state, caches |

Both need to be pre-seeded in the container to fully suppress all first-run prompts.

### How to chnage the Claude settings.json

- Modify the `claude-settings.json` in the `devcontainer` folder
- Remove the existing one if any from the volume 
    - running container: `docker compose exec -u root claude-code rm /home/node/.claude/settings.json` and then `docker compose restart claude-code`
    - not running container: `docker run --rm -v yourproject_claude-config:/data alpine rm /data/settings.json`

### Summary

| Key | What it skips |
|---|---|
| `permissions.defaultMode: "bypassPermissions"` | Permission prompts during operation |
| `skipDangerousModePermissionPrompt` | The "do you accept responsibility" screen |
| `hasCompletedProjectOnboarding` | First-run project walkthrough |
| `hasAcknowledgedCaveats` | Security caveats warning screen |
| `theme` | Color scheme (but NOT the terminal theme prompt at startup) |


## Claude Memory and Skills

### Claude Memory: CLAUDE.md

#### Two-file Strategy (recommended)

The global one travels with you across all projects. The project one gets committed to git so your whole team benefits from it:

```
/home/node/.claude/CLAUDE.md     ← YOUR preferences (persists in claude-config volume) coding style, workflow rules, personal habits

/workspace/CLAUDE.md             ← PROJECT knowledge (persists in your repo) architecture, decisions, known issues, conventions
```

#### Rule of Thumb

| Preference | Where |
|---|---|
| "I always use uv + src layout" | Global — it's about how YOU work |
| "This project uses FastAPI" | Project — it's about THIS codebase |
| "I prefer ruff over black" | Global — personal style |
| "Run `uv run pytest` to test" | Project — project-specific command |
| "I like dark themes in output" | Global — personal preference |
| "Database is PostgreSQL 15" | Project — project-specific fact |

### Claude Skills: SKILL.md

Claude Code's /skills is a plugin system that lets you add reusable instruction sets that Claude loads before tackling certain tasks — think of them as expert playbooks Claude can reference.

#### What a Skill is

A skill is a markdown file (like SKILL.md) stored in a known location that contains:

Best practices for a specific task
Step-by-step instructions Claude should follow
Templates, patterns, or conventions
Examples of good vs bad output

When Claude starts a task that matches a skill, it reads the skill file first, then applies that knowledge to your specific problem.

The skills live in:

```bash
/home/node/.claude/skills/     ← global skills (all projects)
/workspace/.claude/skills/     ← project skills (this project only)
```

#### How to use them?

```bash
# Inside Claude Code, list available skills
/skills

# Add a skill from Anthropic's marketplace
claude plugin marketplace add anthropics/skills

# Reference a skill in a prompt
"Use the react-component skill to build a login form"
```

#### Practical example

You could create a skill for your team's coding conventions:

```bash
# Our Team Conventions
# /workspace/.claude/skills/our-conventions.md:

## When writing a new API endpoint:
1. Always validate input with Zod
2. Return errors in { error: string, code: number } format
3. Add a test in /tests/api/
4. Update the OpenAPI spec
```

Then tell Claude:
```
"Follow our-conventions skill and add a /users endpoint"
```


## Start Claude automatically

```bash
# Add to ~/.zshrc
function ai {
  if [[ -z "$1" ]]; then
    echo "❌ Usage: ai <path>"
    return 1
  fi

  local dir
  dir=$(cd "$1" 2>/dev/null && pwd)

  echo "DEBUG resolved dir: '$dir'"
  echo "DEBUG file exists: $(test -f "$dir/docker-compose.yml" && echo YES || echo NO)"

  if [[ -z "$dir" ]]; then
    echo "❌ Path does not exist: $1"
    return 1
  fi

  # check both valid compose filename extensions
  if [[ ! -f "$dir/docker-compose.yml" && ! -f "$dir/docker-compose.yaml" ]]; then
    echo "❌ No docker-compose.yml found in: $dir"
    return 1
  fi

  docker compose --project-directory "$dir" up -d
  docker compose --project-directory "$dir" exec claude-code claude --model qwen3-coder:30b
}

```

and these are possible usages:

```bash
# The path where the docker compose is, the working folder is defined in the .env file.
ai .                      # current folder
ai ~/projects/my-app      # absolute with ~
ai /Users/me/projects     # full absolute path
ai ../other-project       # relative: one level up
ai ./sub-project          # relative: current folder child
ai ../../somewhere        # relative: multiple levels up
```


## MacOS Specific

### Terminal would like to access data from other apps

This is a macOS privacy prompt, not a Docker or Claude Code issue. It's asking whether Terminal is allowed to access data from other running apps.
Click `"Don't Allow"` — it's the safer choice and Claude Code will work fine without it.

#### What this prompt actually means

MacOS introduced this permission to protect against one app scraping data from another (passwords, clipboard content, etc.). Terminal is asking because a process inside it (likely the Docker build or Claude Code startup) triggered an inter-app communication check.

You don't need to grant it. The permission is about reading data from other apps, not about network access, filesystem access, or running containers — none of which require this.

If you accidentally clicked `"Allow"` and want to revoke it
`System Settings → Privacy & Security → Automation`
Find Terminal in the list and toggle off any apps it's been granted access to.

### Can I Run Ollama from a Container?

**Yes — but with an important caveat for Mac users.**

Ollama has an official Docker image (`ollama/ollama`) that works great on Linux and Windows with NVIDIA/AMD GPUs. However:

> ⚠️ **macOS + Docker Desktop**: Docker Desktop on Mac does **not** support GPU passthrough. If you run Ollama inside a container on a Mac, it runs on CPU only — which is extremely slow for large models.

| Platform | Ollama in container? | GPU support? | Recommendation |
|---|---|---|---|
| Linux + NVIDIA GPU | ✅ Yes | ✅ Yes (NVIDIA Container Toolkit) | Run in container |
| Linux + AMD GPU | ✅ Yes | ✅ Yes (ROCm) | Run in container |
| Windows + NVIDIA GPU | ✅ Yes | ✅ Yes (Docker Desktop + WSL2) | Run in container |
| **macOS (Apple Silicon)** | ✅ Technically | ❌ No GPU passthrough | **Run on host instead** |

**For Mac users (the likely majority reading this):** Run Ollama natively on your Mac (where it can use the GPU via Metal/MLX), and have the Claude Code container connect to it.

---

## Run Everything in Container

### Can Claude Code and Ollama Containers Work Together?

**Yes, absolutely.** This is one of the best setups for privacy and safety. There are two architectures:

#### Architecture A: Ollama on host, Claude Code in container (recommended for Mac)

```
YOUR MAC
├── Ollama (native, uses Apple Silicon GPU via Metal)
│   └── listening on localhost:11434
│
└── Docker
    └── Claude Code container
        └── connects to host Ollama via host.docker.internal:11434
```

#### Architecture B: Both in containers (recommended for Linux/Windows with GPU)

```
YOUR MACHINE
└── Docker network: ai-network
    ├── ollama container (port 11434, GPU access)
    │   └── models stored in named volume
    └── claude-code container
        └── connects to ollama:11434 (via Docker internal DNS)
```

In both cases, Claude Code sends requests to Ollama instead of Anthropic's cloud API. The models run locally, the code stays local, nothing leaves your machine.


### What Are the Advantages?

#### Privacy
- Your code **never leaves your machine** — it's not sent to Anthropic or any cloud
- No API keys exposed in requests
- Safe to work with proprietary, confidential, or client code

#### Cost
- Zero API costs — no per-token billing
- Run as many iterations as you want (Ralph loops, heavy refactoring) without watching your bill

#### Safety (container isolation)
- Claude Code runs in a sandboxed container: can't touch your other files, credentials, or system
- Ollama is isolated too: models and data stay in named Docker volumes, separate from your filesystem
- Each project gets its own container — no cross-contamination

#### Consistency
- Everyone on your team runs the exact same environment
- No "works on my machine" issues
- Easy to reset: delete container, start fresh

#### Offline capability
- Works without internet after initial model download
- Great for travel, restricted networks, or air-gapped environments


### How Are the Models Actually Run? Inside a Container or on My Local Env?

This is the most important question to understand. **Models run wherever Ollama runs.**

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

#### If Ollama runs on your Mac (Architecture A):
- ✅ Model uses Apple Silicon GPU (Metal/MLX) — fast
- ✅ Model files stored on your Mac's disk
- ✅ RAM comes from your Mac's unified memory
- The container only runs Claude Code — lightweight, no GPU needed

#### If Ollama runs in a container (Architecture B):
- Model is loaded inside the container's memory
- GPU access requires NVIDIA Container Toolkit (Linux/Windows only)
- Model files stored in a Docker named volume (persists between restarts)
- On Mac without GPU passthrough: CPU-only inference — **very slow** for 30B models

**Rule of thumb:** Put Ollama where the GPU is accessible. On Mac, that's the host. On Linux/Windows with NVIDIA, that can be the container.

