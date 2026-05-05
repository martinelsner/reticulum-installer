#!/usr/bin/env bash
#
# Verification script — runs inside the NixOS VM after nixos-rebuild.
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
echo "  (NixOS)"
echo "======================================="

# --- User & Group ---
echo ""
echo "--- User & Group ---"
check "Group 'reticulum' exists"          getent group reticulum
check "User 'reticulum' exists"           id reticulum
check "User is in 'dialout' group"        id -nG reticulum | grep -qw dialout
check "Shell is /run/wrappers/bin/false"  test "$(getent passwd reticulum | cut -d: -f7)" = "/run/wrappers/bin/false"

# --- Binaries ---
echo ""
echo "--- Binaries ---"
check "rnsd is installed"                 which rnsd
check "lxmd is installed"                 which lxmd

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
check "rnsd.service file exists"          test -f /etc/systemd/system/rnsd.service
check "lxmd.service file exists"          test -f /etc/systemd/system/lxmd.service
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
check "rnsd runs as user reticulum"       pgrep -u reticulum -f rnsd
check "lxmd runs as user reticulum"       pgrep -u reticulum -f lxmd

# --- Summary ---
echo ""
echo "======================================="
echo "  Results: ${PASS} passed, ${FAIL} failed"
echo "======================================="
echo ""

if [[ $FAIL -gt 0 ]]; then
    echo "--- Debug: rnsd journal ---"
    journalctl -u rnsd --no-pager -n 20 || true
    echo "--- Debug: lxmd journal ---"
    journalctl -u lxmd --no-pager -n 20 || true

    exit 1
fi

exit 0