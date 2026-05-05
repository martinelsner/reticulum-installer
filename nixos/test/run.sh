#!/usr/bin/env bash
#
# Test runner — builds and runs the NixOS installer test in a QEMU VM.
#
# Prerequisites on Ubuntu:
#   sudo apt install qemu-system-x86 kvm
#
# Usage: bash test/run.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "==> Reticulum Installer Test (NixOS)"
echo ""

# --- Run NixOS test ---
echo "--- Building and running NixOS VM test ---"
nix-build "${PROJECT_DIR}/nixos/test/default.nix"

RESULT=$?

if [[ $RESULT -eq 0 ]]; then
    echo ""
    echo "========================================"
    echo "  ALL TESTS PASSED"
    echo "========================================"
else
    echo ""
    echo "========================================"
    echo "  TEST FAILED"
    echo "========================================"
fi

exit $RESULT