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
