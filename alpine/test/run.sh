#!/usr/bin/env bash
#
# Test runner — builds and runs the Alpine package tests in a Docker container.
#
# Usage: bash alpine/test/run.sh
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

echo "==> Alpine Package Test"
echo ""

echo "--- Building packages ---"
bash "$PROJECT_DIR/scripts/build-apk.sh"
echo ""

RNS_VERSION=$(ls "$PROJECT_DIR/alpine/build/out"/rnsd-*.apk | sed -n 's/.*rnsd-\(.*\)\.apk/\1/p' | head -1)

echo "Versions: rnsd=$RNS_VERSION"

echo "--- Building test image ---"
docker build -t "$IMAGE_NAME" -f "${SCRIPT_DIR}/Dockerfile" "$PROJECT_DIR"
echo ""

echo "--- Starting container ---"
docker run -d \
    --name "$CONTAINER_NAME" \
    --privileged \
    "$IMAGE_NAME"
echo ""

echo "--- Copying packages to container ---"
RNSD_PKG="rnsd-${RNS_VERSION}.apk"
docker cp "$PROJECT_DIR/alpine/build/out/${RNSD_PKG}" "$CONTAINER_NAME:/tmp/"
docker cp "$SCRIPT_DIR/verify.sh" "$CONTAINER_NAME:/tmp/verify.sh"

echo "--- Installing packages ---"
docker exec "$CONTAINER_NAME" sh -c "apk add --allow-untrusted /tmp/${RNSD_PKG}"
echo ""

echo "--- Running verification ---"
RESULT=0
docker exec "$CONTAINER_NAME" sh /tmp/verify.sh || RESULT=$?

exit $RESULT