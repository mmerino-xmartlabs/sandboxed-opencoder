# ==============================================================================
# xl-sandboxed-opencoder - Hardened Dockerfile
# Base: Minimal Debian with Python 3.13
# ==============================================================================
FROM python:3.13-slim

ARG HOST_UID=1000
ARG HOST_GID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# 1. System Updates, Essential Tools & Sudo
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    make \
    curl \
    wget \
    zip \
    unzip \
    jq \
    tree \
    vim \
    cloc \
    ca-certificates \
    sudo \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add the Sudoers Whitelist for the agent
RUN echo "agent ALL=(root) NOPASSWD: /usr/bin/apt-get update, /usr/bin/apt-get install *" > /etc/sudoers.d/agent-apt \
    && chmod 0440 /etc/sudoers.d/agent-apt

# 2. Securely install 'uv' directly from the official Astral image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# 3. Create non-root agent user matching the host
# If the GID already exists (e.g., GID 20), we use it. Otherwise, we create it.
RUN getent group ${HOST_GID} || groupadd -g ${HOST_GID} agent_group
RUN useradd -m -u ${HOST_UID} -g ${HOST_GID} -s /bin/bash agent

# 4. Set up the workspace directories
RUN mkdir -p /home/agent/projects \
             /home/agent/shared \
             /home/agent/temp \
             /home/agent/app

# 5. Install OpenCode CLI via NPM
RUN npm install -g opencode-ai@latest

# 6. Copy the entrypoint script (using just 'agent' defaults to their primary group)
COPY --chown=agent entrypoint.sh /home/agent/app/entrypoint.sh
RUN chmod +x /home/agent/app/entrypoint.sh

# 7. Lock down the container to the non-root user
USER agent
WORKDIR /home/agent/projects

# 8. Entrypoint execution
ENTRYPOINT ["/home/agent/app/entrypoint.sh"]
