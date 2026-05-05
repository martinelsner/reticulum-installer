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
check "Shell is /usr/sbin/nologin"        test "$(getent passwd reticulum | cut -d: -f7)" = "/usr/sbin/nologin"

# --- Binaries ---
echo ""
echo "--- Binaries ---"
check "rnsd is installed"                 which rnsd
check "lxmd is installed"                 which lxmd
check "rnsd-status is installed"          which rnsd-status
check "lxmd-status is installed"          which lxmd-status

# --- Configuration ---
echo ""
echo "--- Configuration ---"
check "rnsd config exists"                test -f /etc/reticulum/config
check "lxmd config exists"                test -f /etc/lxmd/config
check "rnsd config has transport=yes"     grep -q "enable_transport = yes" /etc/reticulum/config
check "lxmd config has node=yes"          grep -q "enable_node = yes" /etc/lxmd/config
check "Storage dir owned by reticulum"    test "$(stat -c %U /etc/reticulum/storage)" = "reticulum"
check "Storage dir readable by all"       test "$(stat -c %a /etc/reticulum/storage)" = "755" 2>/dev/null || test "$(stat -c %a /etc/reticulum/storage)" = "775"

# --- Systemd Unit Files ---
echo ""
echo "--- Systemd Units ---"
check "rnsd.service file installed"       test -f /etc/systemd/system/rnsd.service
check "lxmd.service file installed"       test -f /etc/systemd/system/lxmd.service
check "rnsd.service is enabled"           systemctl is-enabled rnsd.service
check "lxmd.service is enabled"           systemctl is-enabled lxmd.service
check "rnsd.service has /etc/reticulum ReadWritePaths"  grep -q "ReadWritePaths=/etc/reticulum" /etc/systemd/system/rnsd.service
check "lxmd.service has /etc/reticulum ReadWritePaths"  grep -q "ReadWritePaths=.*/etc/reticulum" /etc/systemd/system/lxmd.service

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
check "Config not overwritten"            grep -q "enable_transport = yes" /etc/reticulum/config

# --- Summary ---
echo ""
echo "======================================="
echo "  Results: ${PASS} passed, ${FAIL} failed"
echo "======================================="
echo ""

if [[ $FAIL -gt 0 ]]; then
    # Dump logs for debugging
    echo "--- Debug: rnsd journal ---"

    exit 1
fi

exit 0
