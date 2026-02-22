# Global Instructions for Claude Code

## My Coding Preferences
- Use TypeScript over JavaScript when possible
- Prefer functional programming patterns
- Always write tests for new functions
- Use descriptive variable names, no single-letter vars

## Workflow Rules
- Always run tests before marking a task done
- Create a git commit after each logical unit of work
- Ask before deleting any file
- Explain what you're about to do before doing it

## Project Context
<!-- Claude will enrich this section as it learns the project -->

## Decisions Made
<!-- Log important architectural decisions here -->

## Known Issues
<!-- Track known bugs or limitations -->

## Python Projects

Always scaffold Python projects with:
- uv for package management
- src layout (src/package_name/)
- pyproject.toml (not setup.py)
- ruff for linting and formatting
- pytest for testing
- .python-version file

## Git
- Conventional commits (feat:, fix:, chore:)
- Always create a feature branch, never commit to main
- Always ask before force pushing

## General
- Ask before deleting files
- Prefer simple solutions over clever ones
- Add docstrings to all public functions
- Never hardcode secrets or API keys