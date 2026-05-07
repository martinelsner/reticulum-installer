#!/bin/sh
#
# Verification script for rnsd package on Alpine Linux.
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
echo "  rnsd Package — Verification"
echo "  (Alpine Linux)"
echo "======================================="

echo ""
echo "--- Users & Groups ---"
check "Group 'rnsd' exists"              getent group rnsd
check "User 'rnsd' exists"               id rnsd

echo ""
echo "--- Binaries ---"
check "rnsd is installed"                 which rnsd
check "rnstatus is installed"             which rnstatus
check "rnsd-status is installed"          which rnsd-status

echo ""
echo "--- Python Virtualenv ---"
check "/usr/lib/rnsd exists"             test -d /usr/lib/rnsd
check "rnsd binary in venv"              test -x /usr/lib/rnsd/bin/rnsd

echo ""
echo "--- Configuration ---"
check "/etc/reticulum/config exists"      test -f /etc/reticulum/config

echo ""
echo "--- OpenRC Init Scripts ---"
check "rnsd init script installed"        test -x /etc/init.d/rnsd

echo ""
echo "--- Service Status ---"
sleep 2
check "rnsd service is started"           rc-service rnsd status
check "rnsd runs as user rnsd"            pgrep -u rnsd -f rnsd

echo ""
echo "======================================="
echo "  Results: ${PASS} passed, ${FAIL} failed"
echo "======================================="

if [ "$FAIL" -gt 0 ]; then
    echo "--- Debug: rnsd status ---"
    rc-service rnsd status || true
    exit 1
fi

exit 0