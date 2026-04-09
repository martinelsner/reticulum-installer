#!/usr/bin/env bash
#
# Test runner — builds and runs the installer test in a Docker container.
#
# Usage: bash test/run.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONTAINER_NAME="reticulum-installer-test"
IMAGE_NAME="reticulum-installer-test"

cleanup() {
    echo ""
    echo "--- Cleaning up ---"
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
}
trap cleanup EXIT

echo "==> Reticulum Installer Test"
echo ""

# --- Build ---
echo "--- Building test image ---"
docker build -t "$IMAGE_NAME" -f "${SCRIPT_DIR}/Dockerfile" "$PROJECT_DIR"
echo ""

# --- Start container with systemd ---
echo "--- Starting container ---"
docker run -d \
    --name "$CONTAINER_NAME" \
    --privileged \
    --cgroupns=host \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    "$IMAGE_NAME"

# Wait for systemd to be ready
echo "    Waiting for systemd to initialize..."
for i in $(seq 1 30); do
    if docker exec "$CONTAINER_NAME" systemctl is-system-running --wait 2>/dev/null | grep -qE "running|degraded"; then
        break
    fi
    sleep 1
done
echo "    Container ready."
echo ""

# --- Run installer ---
echo "--- Running install.sh ---"
docker exec "$CONTAINER_NAME" bash /opt/reticulum-installer/debian/install.sh
echo ""

# --- Wait for services to settle ---
echo "--- Waiting for services to start ---"
sleep 10

# --- Run verification ---
echo "--- Running verification ---"
docker exec "$CONTAINER_NAME" bash /opt/reticulum-installer/debian/test/verify.sh
RESULT=$?

exit $RESULT
