#!/bin/bash
set -e

# Load environment variables
if [ -f .env ]; then export $(grep -v '^#' .env | xargs); else exit 1; fi
if [ -z "$PROJECT_NAME" ]; then exit 1; fi

PROJECT_DIR="${PROJECTS_ROOT_PATH}/${PROJECT_NAME}"

# Ensure the master AGENTS.md exists in the root directory
if [ ! -f "AGENTS.md" ]; then
  echo "Error: AGENTS.md not found in the root repository. Please ensure it exists."
  exit 1
fi

echo "Ensuring project workspace exists for: ${PROJECT_NAME}..."

# Always ensure target directories exist
PKG_NAME="${PROJECT_NAME//-/_}"
mkdir -p "$PROJECT_DIR/docs" "$PROJECT_DIR/artifacts" "$PROJECT_DIR/logs" "$PROJECT_DIR/src/$PKG_NAME"

# Drop an __init__.py so the agent immediately recognizes it as the active package
touch "$PROJECT_DIR/src/$PKG_NAME/__init__.py"

# --- Dynamic LLM Routing Injection (Always Runs) ---
if [ "$LLM_SOURCE" = "lm_studio" ]; then
  INJECT_URL="http://host.docker.internal:${LLM_PORT:-1234}/v1"
  INJECT_MODEL="$LM_STUDIO_MODEL"
elif [ "$LLM_SOURCE" = "fastflow_amd" ]; then
  INJECT_URL="http://host.docker.internal:52625/v1"
  INJECT_MODEL="$FASTFLOW_MODEL"
elif [ "$LLM_SOURCE" = "ollama_docker" ]; then
  INJECT_URL="http://opencode-llm:11434/v1"
  INJECT_MODEL="$OLLAMA_MODEL"
fi

cat <<EOF > "$PROJECT_DIR/.env"
# Dynamic Configuration injected by xl-sandboxed-opencoder
LLM_BASE_URL="${INJECT_URL}"
LLM_MODEL_NAME="${INJECT_MODEL}"
APP_PORT=7860
EOF
# ------------------------------------------

# Generate the internal Python Makefile for the agent
mkdir -p agent_templates
cat << 'EOF' > agent_templates/Makefile
.PHONY: setup format lint typecheck test run
setup:
	uv venv && uv sync
format:
	uv run ruff format . && uv run ruff check --fix .
lint:
	uv run ruff check .
typecheck:
	uv run mypy --strict .
test:
	uv run pytest -v
run:
	uv run python main.py
EOF

# Always inject the latest constraints and commands into the project
cp AGENTS.md "$PROJECT_DIR/"
cp agent_templates/Makefile "$PROJECT_DIR/"

# Only initialize Git and write README if it's a completely new project
if [ ! -d "$PROJECT_DIR/.git" ]; then
  echo "# ${PROJECT_NAME}" > "$PROJECT_DIR/README.md"
  echo "Project initialized via xl-sandboxed-opencoder." >> "$PROJECT_DIR/README.md"

  cd "$PROJECT_DIR"
  git init
  git add .
  git commit -m "chore: initialize project with strict agent templates"
  echo "Project '$PROJECT_NAME' created securely."
else
  echo "Existing project '$PROJECT_NAME' updated with latest templates and .env."
fi
