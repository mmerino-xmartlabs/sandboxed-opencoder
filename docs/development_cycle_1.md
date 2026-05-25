# Development Cycle 1: Security Baseline Audit and Hardening

Date: 2026-05-25

## Scope

Audited the existing Docker, Compose, shell, and documentation baseline for a local OpenCode workspace connected to LM Studio or another OpenAI-compatible local LLM.

## Key Findings

- The Dockerfile installed Node through a remote setup script and installed `opencode-ai@latest`, creating non-reproducible builds.
- The runtime container had no capability drop, `no-new-privileges`, process limit, CPU limit, or memory limit.
- `entrypoint.sh` interpolated shell variables directly into JSON and configured Git with `safe.directory '*'`.
- `new_project.sh` parsed `.env` through `grep | xargs`, which is brittle for quoted values and spaces.
- The README did not describe the actual current threat model or validation workflow.

## Changes Implemented

- Switched the base image to pinned `python:3.13.13-slim-bookworm`.
- Added core build/runtime tools, including `cmake`, `uv`, `cloc`, `tree`, `ripgrep`, `lsof`, `psmisc`, and compiler basics.
- Replaced the Node setup pipe with an explicit signed NodeSource apt repository and pinned `nodejs=22.22.2-1nodesource1`.
- Pinned OpenCode through `OPENCODE_VERSION=0.6.6` and moved npm execution to image build time only. Lifecycle scripts remain enabled because the package uses `postinstall.mjs` to fetch its platform binary.
- Pinned uv to `ghcr.io/astral-sh/uv:0.11.16`.
- Added GitHub CLI `2.92.0` from GitHub release assets with architecture-specific SHA-256 verification.
- Replaced broad apt sudo access with `sudo agent-apt-install`, backed by `config/apt-package-allowlist.txt`, and replaced direct privileged `fuser` access with `sudo agent-kill-port`.
- Expanded the base image with common Python/backend/data/AI development tools while keeping runtime package additions allowlisted.
- Added explicit secret-handling instructions to `AGENTS.md`.
- Added Compose hardening: non-root runtime, local-only port bindings, process limits, CPU limits, memory limits, UID/GID validation that rejects root IDs, and a minimal capability set for the constrained sudo wrappers.
- Rewrote OpenCode config generation to use `jq`.
- Restricted Git safe directory configuration to `/home/agent/projects`.
- Added `.env.example`, `.dockerignore`, and `scripts/validate_config.sh`.
- Updated generated project bootstrapping to create templates in a temporary directory instead of leaving host-side template artifacts.
- Rewrote the README around the actual security model and operator workflow.

## Technical Debt

- Docker image tags are version-pinned but not digest-pinned. A future cycle should add per-architecture digest pinning for stronger reproducibility.
- A stricter read-only root filesystem would require explicit writable mounts for OpenCode config and home cache paths.
- OpenCode npm package integrity is not yet verified with a lockfile or offline artifact mirror.
- The package allowlist is curated but not automatically checked against vulnerability feeds.

## Next Steps

- Add a CI-style validation target that runs shell syntax checks and Docker Compose config rendering.
- Consider an npm lockfile or an internal package mirror for OpenCode.
- Evaluate rootless Docker or a dedicated VM host profile as the recommended deployment mode.
