# Development Cycle 2: Port Policy, Logs, and Final Security Checks

Date: 2026-05-25

## Scope

Added a short exposed-port policy, strengthened local validation, documented operational usage, and verified project initialization in a disposable workspace.

## Changes Implemented

- Added `config/port-allowlist.txt` for approved host/container ports.
- Updated validation so `OPENCODE_PORT`, `APP_PORT`, and `LLM_PORT` must be valid non-privileged ports and must appear in the allowlist.
- Updated Compose so `APP_PORT` maps symmetrically instead of always targeting container port `7860`.
- Updated project initialization so generated projects inherit the configured `APP_PORT`.
- Added `scripts/security_check.sh` and `make check` for shell syntax, config rendering, allowlist validation, and lightweight committed-secret scanning.
- Added `make ports` to show the approved exposed-port list.
- Added root `logs/.gitkeep` and documented root/project logging expectations.
- Updated `AGENTS.md` with port allowlist and log-safety rules.
- Expanded README usage guidance, security model, port policy, logs, and shielded-image operating strengths.
- Added professional repository hygiene files: `.editorconfig`, `.gitattributes`, `CONTRIBUTING.md`, `SECURITY.md`, and `docs/architecture.md`.
- Expanded `make check` with assertions for non-root Docker runtime, local-only Compose port binding, and avoidance of broad apt sudo patterns.

## Security Notes

- The image still intentionally permits constrained sudo wrappers, so the workspace service cannot enable Docker `no-new-privileges`.
- Host exposure remains limited by Docker port mappings bound to `127.0.0.1`; this is not a replacement for running Docker rootless or inside a dedicated VM.
- Port allowlist changes should be treated as security-sensitive changes and reviewed like dependency additions.

## Validation Evidence

- `CONFIG_FILE=.env.example ./scripts/validate_config.sh`
- `docker compose --env-file .env.example config`
- `make check`
- Docker image smoke tests for non-root identity and pinned tools.
- Disposable project initialization under `/private/tmp`.
