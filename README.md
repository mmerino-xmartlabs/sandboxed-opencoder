# xl-sandboxed-opencoder

A highly secure, containerized, and locally-hosted environment designed to replicate the OpenAI Codex desktop app experience using open-source tools. This project wraps **OpenCode** and **Qwen3 4B Thinking** inside a hardened Docker sandbox, strictly enforcing industry-standard software engineering practices for Python development.

## 🏗️ Architecture & File System

The sandbox strictly routes data into three distinct, host-mounted volumes defined in your `.env` file to prevent overlap and ensure easy clean-up:
* **`PROJECTS_ROOT_PATH`:** The active workspace where all git repositories and code reside.
* **`SHARED_SYSTEM_PATH`:** A read-only mount for injecting necessary host credentials (e.g., AWS configs, SSH keys) securely without the agent roaming your host OS.
* **`TEMP_PATH`:** The absolute garbage chute. All `uv` environments, `ruff` caches, `mypy` caches, and `pip` temporal files go here. If it gets too large, delete it on the host—it will rebuild harmlessly.

## 🔄 Agentic Development Cycles

Agents in this environment are instructed to **never** write code blindly. They operate via strict "Software Development Cycles." Every task must follow this sequence:

1. **Context & Damage Control:** Read `AGENTS.md`, the `README.md`, and the most recent report in the `docs/` folder. Verify that the previous cycle's goals were actually implemented. If not, perform damage control.
2. **Plan:** Scope the feature incrementally.
3. **Execute:** Write fully type-hinted, PEP8-compliant code.
4. **Test Exhaustively:** Write/update tests using `pytest` and execute static checks (`ruff`, `mypy`). Diagnose and repeat until green.
5. **Git Ops:** Commit logically, merge to main.
6. **Update Docs:** Generate a new `docs/development_cycle_X.md` report summarizing what was accomplished, any technical debt introduced, and the planned next steps.

## 🚀 Getting Started

### Prerequisites
* Docker & Docker Compose
* (Optional) LM Studio installed on your host OS.

### Installation & Initialization
1. Clone this repository and configure your `.env` file. Pay special attention to `USE_LOCAL_LM_STUDIO`.
2. Initialize the environment:
   ```bash
   make run
   ```
3. Create a new project:
   ```bash
   ./new_project.sh agentic-yt-inspector
   ```
4. Access the OpenCode Web UI at `http://localhost:8443` and prompt your agent.

## 🛠️ Useful Make Commands

This environment comes with a host `Makefile` to easily manage the sandbox without memorizing Docker commands:

* `make run`: Starts the sandbox (and the headless LLM container if `USE_LOCAL_LM_STUDIO=false`).
* `make stop`: Halts all sandboxed containers.
* `make clean-cache`: Safely deletes gigabytes of temporal files, uv environments, and garbage in your `TEMP_PATH`. The agent will rebuild them on the next run.
* `make nuke-all`: Destroys the containers and cleans the cache completely.

