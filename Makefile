API_CONTAINER_NAME=kubesure
PATH_PROJECT=./src
PYTHON_VERSION=3.10
MIN_COVERAGE=90
.DEFAULT_GOAL := help


# ---- Variables ---------------------------------------------------------------
PYTEST_ARGS = -s -x -vv --cov=$(PATH_PROJECT) \
	--cov-report=xml:coverage.xml \
	--cov-report=term-missing \
	--cov-report=html:coverage_html


# ---- Local -------------------------------------------------------------------
.PHONY: install pre-commit-install lint format test clean

install: ## Install dependencies locally using uv
	uv venv --python $(PYTHON_VERSION)
	uv sync --all-groups

pre-commit-install: ## Install Git hooks
	uv run pre-commit install --install-hooks

lint: ## Run lint checks (Ruff)
	uv run ruff check $(PATH_PROJECT)
	uv run ruff format --check $(PATH_PROJECT)

format: ## Run code formatter and fix lint issues
	uv run ruff check --fix $(PATH_PROJECT)
	uv run ruff format $(PATH_PROJECT)

test: ## Run tests locally
	uv run pytest $(PYTEST_ARGS)

clean: ## Clean up temporary files
	rm -rf .coverage coverage.xml coverage_html .pytest_cache htmlcov .ruff_cache
	find . -type d -name "__pycache__" -exec rm -rf {} +


# ---- Docker ------------------------------------------------------------------
.PHONY: docker-build docker-start docker-test docker-stop

docker-build: ## Build Docker image with tooling
	docker compose build --no-cache

docker-start: ## Start Docker containers
	docker compose up -d

docker-test: ## Run tests in Docker
	docker compose build --no-cache
	docker compose run --rm -e PYTHONPATH=/app -w /app $(API_CONTAINER_NAME) \
		sh -c 'uv run pytest $(PYTEST_ARGS)'

docker-stop: ## Stop Docker containers
	docker compose down


# ---- CI ----------------------------------------------------------------------
.PHONY: test-coverage-ci
test-coverage-ci: ## Run tests + coverage via docker-test; prints COVERAGE_PERCENT=<n> (GitHub Actions workflow)
	docker compose build --no-cache
	\
	docker compose run --rm -e PYTHONPATH=/app -w /app \
		-v "$(CURDIR):/host" $(API_CONTAINER_NAME) \
		sh -c '$(RUN_PYTEST) && \
		cp coverage.xml /host/coverage.xml' && \
	\
	COVERAGE=$$(sed -n 's/.*line-rate="\([^"]*\)".*/\1/p' coverage.xml | head -n 1); \
	PERCENT=$$(echo "scale=2; $$COVERAGE * 100" | bc); \
	\
	echo "------------------------------------------"; \
	echo "COVERAGE_PERCENT: $$PERCENT%"; \
	echo "MIN_REQUIRED: $(MIN_COVERAGE)%"; \
	echo "------------------------------------------"; \
	\
	if [ -z "$$COVERAGE" ]; then \
		echo "coverage: TOTAL value not found"; \
		exit 1; \
	fi;


# ---- Debug & Info ------------------------------------------------------------
.PHONY: debug-info
debug-info: ## Generate a report of the local environment for bug reporting
	@echo "=== kubesure Debug Report ==="
	@echo "Date: $$(date)"
	@echo "OS: $$(uname -s -r)"
	@echo "--- Tool Versions ---"
	@python3 --version || echo "Python: Not found"
	@uv --version || echo "uv: Not found"
	@kustomize version --short 2>/dev/null || echo "Kustomize: Not found"
	@kubectl version --client --short 2>/dev/null || echo "Kubectl: Not found"
	@echo "--- Project Info ---"
	@echo "Project: $(API_CONTAINER_NAME)"
	@echo "Path: $(PATH_PROJECT)"
	@if [ -d .git ]; then echo "Git Branch: $$(git rev-parse --abbrev-ref HEAD)"; fi
	@echo "============================="


# ---- Help --------------------------------------------------------------------
.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'
