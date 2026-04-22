#!/usr/bin/env bash
#
# Reticulum + LXMF Uninstaller for Debian
#
# Removes the systemd services, virtualenv, and system binaries.
# Leaves configuration and user data intact.
#
# Usage: sudo bash uninstall.sh
#

set -uo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root (sudo)."
    exit 1
fi

echo "==> Reticulum + LXMF Uninstaller"
echo ""

# ---------- Stop & Disable ----------

echo "--- Stopping and disabling services ---"
systemctl stop lxmd.service rnsd.service 2>/dev/null || true
systemctl disable lxmd.service rnsd.service 2>/dev/null || true

# ---------- Service Files ----------

echo "--- Removing systemd service files ---"
rm -f /etc/systemd/system/rnsd.service
rm -f /etc/systemd/system/lxmd.service
systemctl daemon-reload

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
echo "Note: The configuration and data directories were NOT removed:"
echo "  - Reticulum: /etc/reticulum (config and shared storage)"
echo "  - LXMF & home: /var/lib/reticulum (lxmd data, user files)"
echo "The system user 'reticulum' was also NOT removed."
echo "To remove everything, run:"
echo "    rm -rf /etc/reticulum /var/lib/reticulum"
echo "    userdel reticulum"
echo ""
