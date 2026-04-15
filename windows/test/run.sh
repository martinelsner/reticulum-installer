#!/usr/bin/env bash
#
# Test runner — spins up a Windows 11 VM in Docker (via dockur/windows),
# runs the Reticulum installer, and verifies the result.
#
# Prerequisites:
#   - Docker with KVM support (/dev/kvm)
#   - Windows ISO at ~/Downloads/ (auto-detected) or pass as $1
#
# Usage: bash test/run.sh [/path/to/windows.iso]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONTAINER_NAME="reticulum-windows-test"
IMAGE="dockurr/windows"
OEM_DIR="$SCRIPT_DIR/oem"
STORAGE_DIR="$SCRIPT_DIR/storage"

# --- Locate Windows ISO ---

ISO_PATH="${1:-}"
if [[ -z "$ISO_PATH" ]]; then
    ISO_PATH=$(find ~/Downloads -maxdepth 1 -iname "Win*.iso" -print -quit 2>/dev/null || true)
fi

if [[ -z "$ISO_PATH" || ! -f "$ISO_PATH" ]]; then
    echo "Error: No Windows ISO found."
    echo "Place a Windows ISO in ~/Downloads or pass the path as an argument."
    echo "Usage: bash test/run.sh /path/to/windows.iso"
    exit 1
fi

echo "==> Reticulum Installer Test (Windows)"
echo ""
echo "    ISO: $ISO_PATH"
echo ""

# --- Prepare OEM directory ---
# dockur/windows copies /oem to C:\OEM and runs install.bat automatically.

echo "--- Preparing OEM payload ---"
rm -rf "$OEM_DIR"
mkdir -p "$OEM_DIR/installer"

# Copy project files into the OEM payload
cp -r "$PROJECT_DIR/config"  "$OEM_DIR/installer/config"
cp -r "$PROJECT_DIR/windows" "$OEM_DIR/installer/windows"

# Copy the install.bat trigger to the OEM root
cp "$SCRIPT_DIR/install.bat" "$OEM_DIR/install.bat"

# Copy the verify script alongside
cp "$SCRIPT_DIR/verify.ps1" "$OEM_DIR/verify.ps1"

echo "    OEM directory ready."
echo ""

# --- Cleanup handler ---

cleanup() {
    echo ""
    echo "--- Cleaning up ---"
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
    # Keep oem/ and storage/ for debugging
}
trap cleanup EXIT

# --- Preflight checks ---

if [[ ! -e /dev/kvm ]]; then
    echo "Error: /dev/kvm not found. KVM is required."
    exit 1
fi

# Remove any leftover container from a previous run
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

# --- Start Windows VM ---

echo "--- Starting Windows VM ---"

docker run -d \
    --name "$CONTAINER_NAME" \
    -e "RAM_SIZE=4G" \
    -e "CPU_CORES=4" \
    -e "DISK_SIZE=64G" \
    -e "USERNAME=Docker" \
    -e "PASSWORD=admin" \
    --device=/dev/kvm \
    --device=/dev/net/tun \
    --cap-add NET_ADMIN \
    -v "$ISO_PATH:/boot.iso" \
    -v "$OEM_DIR:/oem" \
    -v "$STORAGE_DIR:/storage" \
    -p 8006:8006 \
    "$IMAGE"

echo "    Container started: $CONTAINER_NAME"
echo "    Web viewer: http://localhost:8006"
echo ""

# --- Wait for installation and verification to complete ---
# Monitor container logs for our marker strings.
# The OEM install.bat echoes RETICULUM_TEST markers at each stage.

echo "--- Waiting for Windows install + Reticulum setup + verification ---"
echo "    (This typically takes 20-60 minutes for a fresh install)"
echo ""

MAX_WAIT=5400  # 90 minutes max
ELAPSED=0
INTERVAL=30

while [[ $ELAPSED -lt $MAX_WAIT ]]; do
    # Check if the container is still running
    if ! docker inspect "$CONTAINER_NAME" --format '{{.State.Running}}' 2>/dev/null | grep -q true; then
        echo ""
        echo "Error: Container stopped unexpectedly."
        echo "--- Container logs (last 80 lines) ---"
        docker logs "$CONTAINER_NAME" --tail 80 2>&1
        exit 1
    fi

    # Check container logs for our markers
    LOGS=$(docker logs "$CONTAINER_NAME" 2>&1 || true)

    if echo "$LOGS" | grep -q "RETICULUM_TEST: VERIFY_OK"; then
        echo ""
        echo "    Verification completed successfully."
        echo ""

        # Print everything between the first RETICULUM_TEST marker and the end
        echo "--- Test Output ---"
        echo "$LOGS" | sed -n '/RETICULUM_TEST: Starting installer/,$ p'
        echo ""

        echo "======================================="
        echo "  Windows Test — PASSED"
        echo "======================================="
        exit 0

    elif echo "$LOGS" | grep -q "RETICULUM_TEST: VERIFY_FAILED"; then
        echo ""
        echo "    Verification FAILED."
        echo ""

        echo "--- Test Output ---"
        echo "$LOGS" | sed -n '/RETICULUM_TEST: Starting installer/,$ p'
        echo ""

        echo "======================================="
        echo "  Windows Test — FAILED"
        echo "======================================="
        echo ""
        echo "  To debug: http://localhost:8006"
        trap - EXIT  # keep container for debugging
        exit 1

    elif echo "$LOGS" | grep -q "RETICULUM_TEST: INSTALL_FAILED"; then
        echo ""
        echo "    Installer FAILED."
        echo ""

        echo "--- Test Output ---"
        echo "$LOGS" | sed -n '/RETICULUM_TEST: Starting installer/,$ p'
        echo ""

        echo "======================================="
        echo "  Windows Test — FAILED (installer)"
        echo "======================================="
        echo ""
        echo "  To debug: http://localhost:8006"
        trap - EXIT
        exit 1
    fi

    # Show progress
    STATUS=""
    if echo "$LOGS" | grep -q "RETICULUM_TEST: INSTALL_OK"; then
        STATUS="installer done, running verification..."
    elif echo "$LOGS" | grep -q "RETICULUM_TEST: Starting installer"; then
        STATUS="installer running..."
    elif echo "$LOGS" | grep -q "Booting Windows"; then
        STATUS="booting Windows..."
    elif echo "$LOGS" | grep -q "Installing Windows"; then
        STATUS="installing Windows..."
    else
        STATUS="preparing VM..."
    fi

    printf "    [%d/%ds] %s\r" "$ELAPSED" "$MAX_WAIT" "$STATUS"
    sleep "$INTERVAL"
    ELAPSED=$((ELAPSED + INTERVAL))
done

echo ""
echo "Error: Timed out after ${MAX_WAIT}s."
echo "--- Container logs (last 80 lines) ---"
docker logs "$CONTAINER_NAME" --tail 80 2>&1
echo ""
echo "  To debug: http://localhost:8006"
trap - EXIT
exit 1
