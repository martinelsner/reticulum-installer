.PHONY: build-deb build-apk build test-packages clean
.PHONY: test test-alpine test-debian test-nixos

build-deb: ## Build all Debian packages (reticulum-common, rnsd, lxmd)
	@bash scripts/build-deb.sh

build-apk: ## Build all Alpine packages (reticulum-common, rnsd, lxmd)
	@bash scripts/build-apk.sh

build: build-deb build-apk ## Build all packages

test: ## Run all package tests (Alpine + Debian)
	@echo "==> Running Alpine package test"
	@bash alpine/test/run.sh
	@echo ""
	@echo "==> Running Debian package test"
	@bash debian/test/run.sh

test-alpine: ## Run Alpine package test only
	@bash alpine/test/run.sh

test-debian: ## Run Debian package test only
	@bash debian/test/run.sh

test-nixos: ## Run NixOS installer test with verbose output
	@bash nixos/test/run.sh

test-packages: ## Test package builds (validates spec files parse correctly)
	@echo "==> Validating package specs..."
	@cd debian/build && nfpm package -f ../../debian/reticulum-common/nfpm.yml -p deb --dry-run 2>/dev/null && echo "    reticulum-common: OK" || echo "    reticulum-common: FAILED"
	@cd debian/build && nfpm package -f ../../debian/rnsd/nfpm.yml -p deb --dry-run 2>/dev/null && echo "    rnsd: OK" || echo "    rnsd: FAILED"
	@cd debian/build && nfpm package -f ../../debian/lxmd/nfpm.yml -p deb --dry-run 2>/dev/null && echo "    lxmd: OK" || echo "    lxmd: FAILED"
	@cd alpine/build && nfpm package -f ../../alpine/reticulum-common/nfpm.yml -p apk --dry-run 2>/dev/null && echo "    reticulum-common: OK" || echo "    reticulum-common: FAILED"
	@cd alpine/build && nfpm package -f ../../alpine/rnsd/nfpm.yml -p apk --dry-run 2>/dev/null && echo "    rnsd: OK" || echo "    rnsd: FAILED"
	@cd alpine/build && nfpm package -f ../../alpine/lxmd/nfpm.yml -p apk --dry-run 2>/dev/null && echo "    lxmd: OK" || echo "    lxmd: FAILED"
	@echo "==> Package validation complete"

clean: ## Clean build artifacts
	rm -rf debian/*/build debian/*/out
	rm -rf alpine/*/build alpine/*/out

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'