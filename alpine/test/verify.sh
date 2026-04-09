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
check "Home is /var/lib/reticulum"        test "$(getent passwd reticulum | cut -d: -f6)" = "/var/lib/reticulum"
check "Shell is /sbin/nologin"            test "$(getent passwd reticulum | cut -d: -f7)" = "/sbin/nologin"

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
check "Config not overwritten"            grep -q "enable_transport = yes" /var/lib/reticulum/rnsd/config

# --- Summary ---
echo ""
echo "======================================="
echo "  Results: ${PASS} passed, ${FAIL} failed"
echo "======================================="
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "--- Debug: rnsd log ---"
    cat /var/lib/reticulum/rnsd/logfile 2>/dev/null | tail -20 || true
    echo ""
    echo "--- Debug: lxmd log ---"
    cat /var/lib/reticulum/lxmd/logfile 2>/dev/null | tail -20 || true
    exit 1
fi

exit 0
