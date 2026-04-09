#!/usr/bin/env bash
#
# Test runner — builds and runs the Alpine installer test in Docker.
#
# Usage: bash test/run.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONTAINER_NAME="reticulum-alpine-test"
IMAGE_NAME="reticulum-alpine-test"

cleanup() {
    echo ""
    echo "--- Cleaning up ---"
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
}
trap cleanup EXIT

echo "==> Reticulum Installer Test (Alpine)"
echo ""

# --- Build ---
echo "--- Building test image ---"
docker build -t "$IMAGE_NAME" -f "${SCRIPT_DIR}/Dockerfile" "$PROJECT_DIR"
echo ""

# --- Start container ---
echo "--- Starting container ---"
docker run -d \
    --name "$CONTAINER_NAME" \
    --privileged \
    "$IMAGE_NAME" \
    sleep infinity

# Wait for container to be ready
sleep 2

# Initialize OpenRC inside the container
docker exec "$CONTAINER_NAME" sh -c "openrc sysinit 2>/dev/null; openrc boot 2>/dev/null; openrc default 2>/dev/null" || true
echo "    Container ready."
echo ""

# --- Run installer ---
echo "--- Running install.sh ---"
docker exec "$CONTAINER_NAME" sh /opt/reticulum-installer/alpine/install.sh
echo ""

# --- Wait for services to settle ---
echo "--- Waiting for services to start ---"
sleep 5

# --- Run verification ---
echo "--- Running verification ---"
docker exec "$CONTAINER_NAME" sh /opt/reticulum-installer/alpine/test/verify.sh
RESULT=$?

exit $RESULT
