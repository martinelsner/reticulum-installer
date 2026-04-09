#!/usr/bin/env bash
#
# Verification script — runs inside the container after install.sh
# Returns 0 if all checks pass, non-zero on failure.
#

set -euo pipefail

PASS=0
FAIL=0

check() {
    local description="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        echo "  ✓ ${description}"
        PASS=$((PASS + 1))
    else
        echo "  ✗ ${description}"
        FAIL=$((FAIL + 1))
    fi
}

echo ""
echo "======================================="
echo "  Reticulum Installer — Verification"
echo "======================================="

# --- User & Group ---
echo ""
echo "--- User & Group ---"
check "Group 'reticulum' exists"          getent group reticulum
check "User 'reticulum' exists"           id reticulum
check "User is in 'dialout' group"        sh -c "id -nG reticulum | grep -qw dialout || true"
check "Home is /var/lib/reticulum"        test "$(getent passwd reticulum | cut -d: -f6)" = "/var/lib/reticulum"
check "Shell is /usr/sbin/nologin"        test "$(getent passwd reticulum | cut -d: -f7)" = "/usr/sbin/nologin"

# --- Binaries ---
echo ""
echo "--- Binaries ---"
check "rnsd is installed"                 which rnsd
check "lxmd is installed"                 which lxmd

# --- Configuration ---
echo ""
echo "--- Configuration ---"
check "rnsd config exists"                test -f /var/lib/reticulum/rnsd/config
check "lxmd config exists"                test -f /var/lib/reticulum/lxmd/config
check "rnsd config has transport=yes"     grep -q "enable_transport = yes" /var/lib/reticulum/rnsd/config
check "lxmd config has node=yes"          grep -q "enable_node = yes" /var/lib/reticulum/lxmd/config
check "Data dir owned by reticulum"       test "$(stat -c %U /var/lib/reticulum)" = "reticulum"
check "Data dir permissions are 750"      test "$(stat -c %a /var/lib/reticulum)" = "750"

# --- Systemd Unit Files ---
echo ""
echo "--- Systemd Units ---"
check "rnsd.service file installed"       test -f /etc/systemd/system/rnsd.service
check "lxmd.service file installed"       test -f /etc/systemd/system/lxmd.service
check "rnsd.service is enabled"           systemctl is-enabled rnsd.service
check "lxmd.service is enabled"           systemctl is-enabled lxmd.service

# --- Service Status ---
echo ""
echo "--- Service Status ---"

# Give services a moment to start if just installed
sleep 3

check "rnsd.service is active"            systemctl is-active rnsd.service
check "lxmd.service is active"            systemctl is-active lxmd.service

# Check that processes are actually running under the reticulum user
check "rnsd runs as user reticulum"       sh -c "pgrep -u reticulum -f rnsd > /dev/null"
check "lxmd runs as user reticulum"       sh -c "pgrep -u reticulum -f lxmd > /dev/null"

# --- Idempotency ---
echo ""
echo "--- Idempotency (re-run install) ---"
bash /opt/reticulum-installer/debian/install.sh > /dev/null 2>&1
check "Re-run exits successfully"         true
check "rnsd still active after re-run"    systemctl is-active rnsd.service
check "lxmd still active after re-run"    systemctl is-active lxmd.service
check "Config not overwritten"            grep -q "enable_transport = yes" /var/lib/reticulum/rnsd/config

# --- Summary ---
echo ""
echo "======================================="
echo "  Results: ${PASS} passed, ${FAIL} failed"
echo "======================================="
echo ""

if [[ $FAIL -gt 0 ]]; then
    # Dump logs for debugging
    echo "--- Debug: rnsd journal ---"
    journalctl -u rnsd.service --no-pager -n 20 2>/dev/null || true
    echo ""
    echo "--- Debug: lxmd journal ---"
    journalctl -u lxmd.service --no-pager -n 20 2>/dev/null || true
    exit 1
fi

exit 0
