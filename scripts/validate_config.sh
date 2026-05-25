#!/bin/bash
set -Eeuo pipefail

CONFIG_FILE="${CONFIG_FILE:-.env}"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: ${CONFIG_FILE} not found. Copy .env.example to .env and configure it."
  exit 1
fi

set -a
# shellcheck disable=SC1091
. "$CONFIG_FILE"
set +a

required_vars=(
  PROJECT_NAME
  PROJECTS_ROOT_PATH
  SHARED_SYSTEM_PATH
  TEMP_PATH
  LLM_SOURCE
  OPENCODE_PORT
  PYTHON_BASE_IMAGE
  UV_IMAGE
  NODE_VERSION
  OPENCODE_VERSION
  GH_VERSION
  OLLAMA_IMAGE_TAG
)

for var_name in "${required_vars[@]}"; do
  if [ -z "${!var_name:-}" ]; then
    echo "Error: ${var_name} must be set in .env"
    exit 1
  fi
done

for id_var in HOST_UID HOST_GID; do
  if [ -n "${!id_var:-}" ] && { ! [[ "${!id_var}" =~ ^[0-9]+$ ]] || [ "${!id_var}" -eq 0 ]; }; then
    echo "Error: ${id_var} must be a non-zero numeric ID so the agent never runs as root."
    exit 1
  fi
done

case "$LLM_SOURCE" in
  lm_studio)
    : "${LM_STUDIO_MODEL:?LM_STUDIO_MODEL must be set when LLM_SOURCE=lm_studio}"
    ;;
  fastflow_amd)
    : "${FASTFLOW_MODEL:?FASTFLOW_MODEL must be set when LLM_SOURCE=fastflow_amd}"
    ;;
  ollama_docker)
    : "${OLLAMA_MODEL:?OLLAMA_MODEL must be set when LLM_SOURCE=ollama_docker}"
    ;;
  *)
    echo "Error: LLM_SOURCE must be one of: lm_studio, fastflow_amd, ollama_docker"
    exit 1
    ;;
esac

if [ "${PROJECT_NAME}" != "${PROJECT_NAME//\//}" ] || [ "$PROJECT_NAME" = "." ] || [ "$PROJECT_NAME" = ".." ]; then
  echo "Error: PROJECT_NAME must be a simple directory name without slashes."
  exit 1
fi

for path_var in PROJECTS_ROOT_PATH SHARED_SYSTEM_PATH TEMP_PATH; do
  path_value="${!path_var}"
  if [ "${path_value#/}" = "$path_value" ]; then
    echo "Error: ${path_var} must be an absolute path."
    exit 1
  fi
done

if [ -n "${GITHUB_TOKEN:-}" ] && [ -n "${GH_TOKEN:-}" ] && [ "$GITHUB_TOKEN" != "$GH_TOKEN" ]; then
  echo "Error: Set only one of GITHUB_TOKEN or GH_TOKEN, or set them to the same value."
  exit 1
fi

if [ -f config/apt-package-allowlist.txt ]; then
  if grep -Ev '^(#.*|$|[a-z0-9][a-z0-9+._-]*)$' config/apt-package-allowlist.txt >/dev/null; then
    echo "Error: config/apt-package-allowlist.txt contains invalid package names."
    exit 1
  fi

  package_entries="$(grep -Ev '^(#.*|$)' config/apt-package-allowlist.txt)"
  if [ "$package_entries" != "$(printf '%s\n' "$package_entries" | sort -u)" ]; then
    echo "Error: config/apt-package-allowlist.txt must be sorted and deduplicated."
    exit 1
  fi
fi

echo "Configuration is valid."
