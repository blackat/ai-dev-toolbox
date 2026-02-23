# [Project Name]

## Stack
- Python 3.12, FastAPI, PostgreSQL 15
- uv for package management

## Commands
- `uv run pytest` — run tests
- `uv run ruff check .` — lint
- `uv run fastapi dev src/myapp/main.py` — start dev server

## Architecture
- src/myapp/api/ — route handlers
- src/myapp/models/ — SQLAlchemy models
- src/myapp/services/ — business logic
