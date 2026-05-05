#!/usr/bin/env bash
#
# Rebuild script — validates the NixOS module and checks expected configuration.
#
# For NixOS, we verify:
# 1. The module has valid Nix syntax
# 2. Source code contains expected configuration values
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
MODULE_PATH="${PROJECT_DIR}/nixos/default.nix"

echo "--- Validating module syntax ---"

# Check that the module file has valid Nix syntax
nix-instantiate --parse "$MODULE_PATH" > /dev/null 2>&1 || {
    echo "Module has syntax errors!"
    exit 1
}

echo "    Module syntax is valid."

# Verify that the module generates correct configuration values
# by checking the source code directly for expected values
echo "--- Checking module source for expected values ---"

# Read the module source
MODULE_CONTENT=$(cat "$MODULE_PATH")

# Verify expected values exist in source
PASS=0
FAIL=0

check() {
    local description="$1"
    shift
    local pattern="$1"
    shift
    if grep -q "$pattern" "$MODULE_PATH" 2>/dev/null; then
        echo "  ✓ ${description}"
        PASS=$((PASS + 1))
    else
        echo "  ✗ ${description}"
        FAIL=$((FAIL + 1))
    fi
}

echo ""
echo "======================================="
echo "  Module Source — Verification"
echo "======================================="

check "rnsd uses /etc/reticulum path" '/etc/reticulum/config'
check "lxmd uses /etc/lxmd path" '/etc/lxmd'
check "lxmd ReadWritePaths includes /etc/lxmd" 'ReadWritePaths.*"/etc/lxmd'
check "tmpfiles creates /etc/lxmd directory" '/etc/lxmd.* 0750'
check "lxmd ExecStart includes --config /etc/lxmd" 'lxmd.*--config /etc/lxmd'

echo ""
echo "======================================="
echo "  Results: ${PASS} passed, ${FAIL} failed"
echo "======================================="

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi

exit 0