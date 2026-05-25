#!/bin/bash
set -e

# Configure Git
git config --global user.name "${GIT_USERNAME:-Agent Coder}"
git config --global user.email "${GIT_EMAIL:-agent@sandboxed.local}"
git config --global init.defaultBranch main
git config --global safe.directory '*'

mkdir -p /home/agent/temp/uv_cache /home/agent/temp/ruff_cache /home/agent/temp/mypy_cache /home/agent/temp/pytest_cache
mkdir -p /home/agent/.config/opencode

# Route the LLM Connection
if [ "$LLM_SOURCE" = "lm_studio" ]; then
  PROVIDER_ID="lmstudio"
  PROVIDER_NAME="LM Studio (Host)"
  BASE_URL="http://host.docker.internal:${LLM_PORT:-1234}/v1"
  ACTIVE_MODEL="$LM_STUDIO_MODEL"
elif [ "$LLM_SOURCE" = "fastflow_amd" ]; then
  PROVIDER_ID="fastflow"
  PROVIDER_NAME="FastFlowLM (Host NPU)"
  BASE_URL="http://host.docker.internal:52625/v1"
  ACTIVE_MODEL="$FASTFLOW_MODEL"
elif [ "$LLM_SOURCE" = "ollama_docker" ]; then
  PROVIDER_ID="ollama"
  PROVIDER_NAME="Ollama (Isolated)"
  BASE_URL="http://opencode-llm:11434/v1"
  ACTIVE_MODEL="$OLLAMA_MODEL"
else
  echo "Error: Invalid LLM_SOURCE defined in .env"
  exit 1
fi

cat <<EOF > /home/agent/.config/opencode/opencode.json
{
  "\$schema": "https://opencode.ai/config.json",
  "provider": {
    "${PROVIDER_ID}": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "${PROVIDER_NAME}",
      "options": { "baseURL": "${BASE_URL}" },
      "models": {
        "${ACTIVE_MODEL}": { "name": "${ACTIVE_MODEL}" }
      }
    }
  },
  "model": "${PROVIDER_ID}/${ACTIVE_MODEL}"
}
EOF

exec opencode web --hostname 0.0.0.0 --port ${OPENCODE_PORT:-3000}
