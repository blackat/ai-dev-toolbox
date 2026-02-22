# Claude Code + Ollama — Docker Setup

<!-- toc -->

- [File Structure](#file-structure)
- [Quick Start (Mac)](#quick-start-mac)
- [What's Different from Anthropic's Official Devcontainer](#whats-different-from-anthropics-official-devcontainer)
- [Security Measures Applied](#security-measures-applied)
- [Switching to Anthropic Cloud](#switching-to-anthropic-cloud)
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

<!-- tocstop -->

Extends Anthropic's official devcontainer base with Ollama support for fully local, private AI coding.

## File Structure

```
your-project/
├── docker-compose.yml          ← start here
├── .env                        ← optional overrides (never commit)
├── workspace/                  ← YOUR CODE (only thing Claude can touch)
└── devcontainer/
    ├── CLAUDE.md               ← global (applies to all projects)
    ├── Dockerfile              ← extends Anthropic's base + adds Python/vim/Ollama env
    ├── init-firewall.sh        ← Anthropic's firewall + Ollama port rule
    └── entrypoint.sh           ← applies firewall, prints startup info, opens shell
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
