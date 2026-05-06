.PHONY: test-alpine test-debian test test-nixos

test: ## Run all installer tests (Alpine + Debian)
	@echo "==> Running Alpine installer test"
	@bash alpine/test/run.sh
	@echo ""
	@echo "==> Running Debian installer test"
	@bash debian/test/run.sh

test-alpine: ## Run Alpine installer test only
	@bash alpine/test/run.sh

test-debian: ## Run Debian installer test only
	@bash debian/test/run.sh

test-nixos: ## Run NixOS installer test with verbose output
	@bash nixos/test/run.sh

# Convenience targets
.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'