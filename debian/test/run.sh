#!/usr/bin/env bash
#
# Test runner — builds and runs the Debian package tests in a Docker container.
#
# Usage: bash test/run.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONTAINER_NAME="reticulum-debian-test"
IMAGE_NAME="reticulum-debian-test"

cleanup() {
    echo ""
    echo "--- Cleaning up ---"
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
}
trap cleanup EXIT

echo "==> Debian Package Test"
echo ""

# --- Build packages ---
echo "--- Building packages ---"
bash "$PROJECT_DIR/scripts/build-deb.sh"
echo ""

RNS_VERSION=$(ls "$PROJECT_DIR/debian/build/out"/rnsd_*.deb | sed -n 's/.*rnsd_\(.*\)_amd64.deb/\1/p' | head -1)
LXMF_VERSION=$(ls "$PROJECT_DIR/debian/build/out"/lxmd_*.deb | sed -n 's/.*lxmd_\(.*\)_amd64.deb/\1/p' | head -1)

# --- Build test image ---
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

# --- Copy and install packages ---
echo "--- Installing packages ---"
RNSD_PKG="rnsd_${RNS_VERSION}_amd64.deb"
LXMD_PKG="lxmd_${LXMF_VERSION}_amd64.deb"
docker cp "$PROJECT_DIR/debian/build/out/${RNSD_PKG}" "$CONTAINER_NAME:/tmp/"
docker cp "$PROJECT_DIR/debian/build/out/${LXMD_PKG}" "$CONTAINER_NAME:/tmp/"
# Install python first to satisfy dependencies
docker exec "$CONTAINER_NAME" bash -c "apt-get update -qq && apt-get install -y -qq python3 python3-pip python3-venv python3-cryptography python3-cffi libffi-dev build-essential pkgconf"
# Now install packages
docker exec "$CONTAINER_NAME" bash -c "dpkg -i --force-depends /tmp/${RNSD_PKG} /tmp/${LXMD_PKG}"
docker exec "$CONTAINER_NAME" bash -c "dpkg --configure -a"
# Disable systemd sandboxing for test (allows execution of venv binaries)
docker exec "$CONTAINER_NAME" bash -c 'mkdir -p /etc/systemd/system/rnsd.service.d'
docker exec "$CONTAINER_NAME" bash -c 'cat > /etc/systemd/system/rnsd.service.d/override.conf << EOF
[Service]
NoNewPrivileges=false
ProtectSystem=off
ProtectHome=false
EOF'
docker exec "$CONTAINER_NAME" bash -c 'mkdir -p /etc/systemd/system/lxmd.service.d'
docker exec "$CONTAINER_NAME" bash -c 'cat > /etc/systemd/system/lxmd.service.d/override.conf << EOF
[Service]
NoNewPrivileges=false
ProtectSystem=off
ProtectHome=false
EOF'
docker exec "$CONTAINER_NAME" bash -c "systemctl daemon-reload"
echo ""

# --- Wait for services to settle ---
echo "--- Waiting for services to start ---"
sleep 10

# --- Run verification ---
echo "--- Running verification ---"
docker exec "$CONTAINER_NAME" bash /opt/reticulum-installer/debian/test/verify.sh
RESULT=$?

exit $RESULT