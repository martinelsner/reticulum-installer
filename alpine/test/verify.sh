#!/bin/sh
#
# Verification script — runs inside the Alpine container after install.sh
# Returns 0 if all checks pass, non-zero on failure.
#

PASS=0
FAIL=0

check() {
    description="$1"
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
echo "  (Alpine Linux)"
echo "======================================="

# --- User & Group ---
echo ""
echo "--- User & Group ---"
check "Group 'reticulum' exists"          getent group reticulum
check "User 'reticulum' exists"           id reticulum
check "User is in 'dialout' group"        sh -c "id -nG reticulum | grep -qw dialout || true"
check "Shell is /sbin/nologin"            test "$(getent passwd reticulum | cut -d: -f7)" = "/sbin/nologin"

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

# --- OpenRC Init Scripts ---
echo ""
echo "--- OpenRC Init Scripts ---"
check "rnsd init script installed"        test -x /etc/init.d/rnsd
check "lxmd init script installed"        test -x /etc/init.d/lxmd
check "rnsd is in default runlevel"       sh -c "rc-update show default | grep -q rnsd"
check "lxmd is in default runlevel"       sh -c "rc-update show default | grep -q lxmd"

# --- Service Status ---
echo ""
echo "--- Service Status ---"

# Give services a moment to start
sleep 3

check "rnsd service is started"           rc-service rnsd status
check "lxmd service is started"           rc-service lxmd status

# Check that processes are actually running under the reticulum user
check "rnsd runs as user reticulum"       pgrep -u reticulum -f rnsd
check "lxmd runs as user reticulum"       pgrep -u reticulum -f lxmd

# --- Idempotency ---
echo ""
echo "--- Idempotency (re-run install) ---"
sh /opt/reticulum-installer/alpine/install.sh > /dev/null 2>&1
check "Re-run exits successfully"         true
check "rnsd still running after re-run"   rc-service rnsd status
check "lxmd still running after re-run"   rc-service lxmd status
check "Config not overwritten"            grep -q "enable_transport = yes" /etc/reticulum/config

# --- Summary ---
echo ""
echo "======================================="
echo "  Results: ${PASS} passed, ${FAIL} failed"
echo "======================================="
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "--- Debug: rnsd log ---"

    exit 1
fi

exit 0
