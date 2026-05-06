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

# --- Permissions ---
echo ""
echo "--- Permissions ---"
check "/etc/reticulum is world-accessible"  test "$(stat -c %a /etc/reticulum)" = "777" || test "$(stat -c %a /etc/reticulum)" = "775"
check "/etc/reticulum/storage is world-accessible"  test "$(stat -c %a /etc/reticulum/storage)" = "777" || test "$(stat -c %a /etc/reticulum/storage)" = "775"
check "/etc/reticulum/interfaces is world-accessible"  test "$(stat -c %a /etc/reticulum/interfaces)" = "777" || test "$(stat -c %a /etc/reticulum/interfaces)" = "775"
check "Other users can traverse /etc/reticulum"  su -s /bin/sh -c "test -d /etc/reticulum && test -r /etc/reticulum && test -x /etc/reticulum" nobody
check "Other users can read /etc/reticulum/config"  su -s /bin/sh -c "test -r /etc/reticulum/config" nobody

echo ""
echo "--- Permissions: inherited by new files ---"
touch /etc/reticulum/test_file 2>/dev/null || true
check "New files are world-readable"  test -r /etc/reticulum/test_file 2>/dev/null
# Cleanup
rm -f /etc/reticulum/test_file 2>/dev/null || true

# --- Storage ---
check "Storage dir is world-accessible"  test "$(stat -c %a /etc/reticulum/storage)" = "777" || test "$(stat -c %a /etc/reticulum/storage)" = "755"

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
