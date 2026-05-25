ifneq (,$(wildcard ./.env))
    include .env
    export
endif

.PHONY: setup run stop clean-cache logs nuke-all delete-project

setup:
	mkdir -p $(PROJECTS_ROOT_PATH) $(SHARED_SYSTEM_PATH) $(TEMP_PATH)

run: setup
	@if [ -z "$(PROJECT_NAME)" ]; then echo "Error: PROJECT_NAME is not set in .env."; exit 1; fi
	@./new_project.sh
	@if [ "$(LLM_SOURCE)" = "ollama_docker" ]; then \
		ACTIVE_PROJECT=$(PROJECT_NAME) docker compose --profile local-llm up -d --build; \
		while ! docker exec opencode-llm ollama list > /dev/null 2>&1; do sleep 2; done; \
		if ! docker exec opencode-llm ollama list | grep -q "$(OLLAMA_MODEL)"; then \
			docker exec opencode-llm ollama pull $(OLLAMA_MODEL); \
		fi; \
	elif [ "$(LLM_SOURCE)" = "lm_studio" ]; then \
		ACTIVE_PROJECT=$(PROJECT_NAME) docker compose up -d --build; \
		if ! curl -s http://localhost:$(LLM_PORT)/v1/models | grep -q "$(LM_STUDIO_MODEL)"; then \
			echo "WARNING: Could not detect $(LM_STUDIO_MODEL) via LM Studio."; \
		fi; \
	elif [ "$(LLM_SOURCE)" = "fastflow_amd" ]; then \
		ACTIVE_PROJECT=$(PROJECT_NAME) docker compose up -d --build; \
		if ! curl -s http://localhost:52625/v1/models | grep -q "$(FASTFLOW_MODEL)"; then \
			echo "WARNING: Could not detect $(FASTFLOW_MODEL) via FastFlowLM. Ensure 'flm serve $(FASTFLOW_MODEL)' is running."; \
		fi; \
	else \
		echo "Error: Invalid LLM_SOURCE '$(LLM_SOURCE)' in .env"; exit 1; \
	fi

stop:
	ACTIVE_PROJECT=$(PROJECT_NAME) docker compose --profile local-llm down

clean-cache:
	rm -rf $(TEMP_PATH)/*

delete-project: stop
	rm -rf $(PROJECTS_ROOT_PATH)/$(PROJECT_NAME)

logs:
	ACTIVE_PROJECT=$(PROJECT_NAME) docker compose --profile local-llm logs -f

nuke-all: stop clean-cache delete-project
	ACTIVE_PROJECT=$(PROJECT_NAME) docker compose --profile local-llm down -v --rmi all
