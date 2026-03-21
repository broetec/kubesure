.DEFAULT_GOAL := help

# ─── Local ────────────────────────────────────────────────────────

.PHONY: pre-commit-install
pre-commit-install: ## Install Git hooks (validation of Conventional Commits for semantic-release)
	uv run pre-commit install --install-hooks

.PHONY: format
format: ## Ruff check + format the Python scripts
	ruff check src/ --fix && ruff format src/

# ─── Help ─────────────────────────────────────────────────────────

.PHONY: help
help: ## Display this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'
