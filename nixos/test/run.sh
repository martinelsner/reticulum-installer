#!/usr/bin/env bash
#
# Test runner — evaluates the NixOS module and runs verification on the host.
#
# Usage: bash test/run.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "==> Reticulum Installer Test (NixOS)"
echo ""

# --- Evaluate module and verify ---
echo "--- Evaluating module and running verification ---"
bash "${SCRIPT_DIR}/rebuild.sh"
RESULT=$?

exit $RESULT