#!/bin/sh
#
# Reticulum + LXMF Uninstaller for Alpine Linux
#
# Removes the OpenRC services, virtualenv, and system binaries.
# Leaves configuration and user data intact.
#
# Usage: sudo sh uninstall.sh
#

set -u

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root (sudo)."
    exit 1
fi

echo "==> Reticulum + LXMF Uninstaller (Alpine)"
echo ""

# ---------- Stop & Disable ----------

echo "--- Stopping and disabling services ---"
rc-service lxmd stop 2>/dev/null || true
rc-service rnsd stop 2>/dev/null || true
rc-update del lxmd default 2>/dev/null || true
rc-update del rnsd default 2>/dev/null || true

# ---------- Service Files ----------

echo "--- Removing OpenRC init scripts ---"
rm -f /etc/init.d/rnsd
rm -f /etc/init.d/lxmd

# ---------- Binaries & Venv ----------

echo "--- Removing executables and virtualenv ---"
rm -f /usr/local/bin/rnsd
rm -f /usr/local/bin/lxmd
rm -f /usr/local/bin/rnsd-status
rm -f /usr/local/bin/lxmd-status
rm -rf /opt/reticulum

# ---------- Summary ----------

echo ""
echo "==========================================="
echo "  Uninstallation complete!"
echo "==========================================="
echo ""
echo "Note: The config/data directory (/var/lib/reticulum) and the user 'reticulum' were NOT removed."
echo "If you wish to remove them completely, run:"
echo "    rm -rf /var/lib/reticulum"
echo "    deluser reticulum"
echo ""
