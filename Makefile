API_CONTAINER_NAME=kubesure
PATH_PROJECT=./src
.DEFAULT_GOAL := help

# ---- Variables ---------------------------------------------------------------
PYTEST_ARGS = -s -x -vv --cov=$(PATH_PROJECT) \
	--cov-report=xml:coverage.xml \
	--cov-report=term-missing \
	--cov-report=html:coverage_html

PYTEST_CMD_IF = if [ -f .env ]; then \
	PYTEST_CMD="uv run --no-project dotenv -f .env run pytest"; \
else \
	PYTEST_CMD="uv run --no-project pytest"; \
fi

RUN_PYTEST = $(PYTEST_CMD_IF); $$PYTEST_CMD $(PYTEST_ARGS)


# ---- Local -------------------------------------------------------------------
.PHONY: pre-commit-install lint format test clean
pre-commit-install: ## Install Git hooks (Conventional Commits validation for semantic-release)
	uv run pre-commit install --install-hooks

lint: ## Run lint checks
	ruff check $(PATH_PROJECT) && ruff check $(PATH_PROJECT) --diff

format: ## Run code formatter
	ruff check $(PATH_PROJECT) --fix && ruff format $(PATH_PROJECT)

test: ## Run tests
	$(RUN_PYTEST)

clean: ## Clean up coverage files
	rm -rf .coverage
	rm -rf coverage.xml
	rm -rf coverage_html
	rm -rf .pytest_cache
	rm -rf htmlcov


# ---- Docker ------------------------------------------------------------------
.PHONY: docker-build docker-start docker-test docker-stop
docker-build: ## Build Docker image with tooling
	docker compose build --no-cache

docker-start: ## Start Docker containers
	docker compose build --no-cache
	docker compose up -d

docker-test: ## Run tests in Docker
	docker compose build --no-cache
	docker compose run --rm -e PYTHONPATH=/app -w /app $(API_CONTAINER_NAME) \
		sh -c '$(RUN_PYTEST)'

docker-stop: ## Stop Docker containers
	docker compose down


# ---- CI ----------------------------------------------------------------------
.PHONY: test-coverage-ci
test-coverage-ci: ## Run tests + coverage via docker-test; prints COVERAGE_PERCENT=<n> (GitHub Actions workflow)
	docker compose build --no-cache
	\
	docker compose run --rm -e PYTHONPATH=/app -w /app \
		-v "$(CURDIR):/host" $(API_CONTAINER_NAME) \
		sh -c '$(RUN_PYTEST) && cp coverage.xml /host/coverage.xml' && \
	\
	COVERAGE=$$(sed -n 's/.*line-rate="\([^"]*\)".*/\1/p' coverage.xml | head -n 1); \
	PERCENT=$$(echo "scale=2; $$COVERAGE * 100" | bc); \
	\
	if [ -z "$$COVERAGE" ]; then \
		echo "coverage: TOTAL value not found"; \
		exit 1; \
	fi; \
	\
	echo "COVERAGE_PERCENT=$$PERCENT"


# ---- Help --------------------------------------------------------------------
.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'
