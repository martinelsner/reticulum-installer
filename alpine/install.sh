#!/bin/sh
#
# Reticulum + LXMF Installer for Alpine Linux
#
# Installs rnsd and lxmd as OpenRC services with a dedicated
# system user, init scripts, and default configurations.
#
# Usage: sudo sh install.sh
#

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

CONFIG_DIR="/etc/reticulum"

# ---------- Preflight ----------

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root (sudo)."
    exit 1
fi

echo "==> Reticulum + LXMF Installer (Alpine)"
echo ""

# ---------- Dependencies ----------

echo "--- Installing system dependencies ---"
apk update
apk add python3 python3-dev py3-pip py3-virtualenv py3-cryptography py3-cffi build-base libffi-dev pkgconf
echo "    System packages installed."

VENV_DIR="/opt/reticulum"

echo "--- Installing Python packages ---"
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv --system-site-packages "$VENV_DIR"
    echo "    Created virtualenv at $VENV_DIR"
fi
# 'bleak' is included to support running RNodes via Bluetooth
"$VENV_DIR/bin/pip" install rns lxmf bleak
echo "    rns, lxmf, and bleak installed in virtualenv."

# Symlink binaries to system PATH
for bin in rnsd lxmd; do
    ln -sf "$VENV_DIR/bin/${bin}" "/usr/local/bin/${bin}"
    echo "    Symlinked ${bin} -> /usr/local/bin/${bin}"
done

# Symlink status wrapper scripts
for wrapper in rnsd-status lxmd-status; do
    ln -sf "${SCRIPT_DIR}/${wrapper}" "/usr/local/bin/${wrapper}"
    echo "    Symlinked ${wrapper} -> /usr/local/bin/${wrapper}"
done

# ---------- User & Group ----------

echo ""
echo "--- Creating system user and group ---"

if ! getent group reticulum > /dev/null 2>&1; then
    addgroup -S reticulum
    echo "    Created group: reticulum"
else
    echo "    Group 'reticulum' already exists."
fi

if ! id reticulum > /dev/null 2>&1; then
    adduser -S -G reticulum -s /sbin/nologin -D reticulum
    # Add to dialout group for RNode serial port access
    addgroup reticulum dialout 2>/dev/null || true
    echo "    Created user: reticulum (with dialout access for RNodes)"
else
    echo "    User 'reticulum' already exists."
    addgroup reticulum dialout 2>/dev/null || true
fi

# ---------- Configuration ----------

echo ""
echo "--- Installing configuration files ---"

# Create /etc/reticulum directory structure
mkdir -p "${CONFIG_DIR}"
# Storage directory for shared instance data
mkdir -p "${CONFIG_DIR}/storage"

# rnsd creates these at runtime — pre-create with correct ownership
mkdir -p "${CONFIG_DIR}/interfaces"
chown reticulum:reticulum "${CONFIG_DIR}/interfaces"

install_config() {
    src="$1"
    dest="$2"

    mkdir -p "$(dirname "$dest")"

    if [ -f "$dest" ]; then
        echo "    SKIP $dest (already exists, not overwriting)"
    else
        cp "$src" "$dest"
        echo "    Installed $dest"
    fi
}

install_config "${SCRIPT_DIR}/../config/rnsd.config" "${CONFIG_DIR}/config"
install_config "${SCRIPT_DIR}/../config/lxmd.config" "/etc/lxmd/config"

# Ensure /etc/reticulum is fully accessible by all users.
# ACLs ensure new files/dirs automatically inherit rwX for all.
setfacl -R -m u::rwX /etc/reticulum 2>/dev/null || chmod -R ugo+rwX /etc/reticulum
setfacl -R -d -m u::rwX /etc/reticulum 2>/dev/null || true
setfacl -R -d -m o::rwX /etc/reticulum 2>/dev/null || true

chmod ugo+rwX "${CONFIG_DIR}"
chmod ugo+rwX "${CONFIG_DIR}/storage"
chmod ugo+rwX "${CONFIG_DIR}/interfaces"

# Ensure lxmd data directory is owned by reticulum
chown -R reticulum:reticulum "/etc/lxmd"

echo "    Permissions set for shared-instance mode."

# ---------- OpenRC Init Scripts ----------

echo ""
echo "--- Installing OpenRC init scripts ---"

install -m 755 "${SCRIPT_DIR}/rnsd.initd" /etc/init.d/rnsd
install -m 755 "${SCRIPT_DIR}/lxmd.initd" /etc/init.d/lxmd
echo "    Installed /etc/init.d/rnsd"
echo "    Installed /etc/init.d/lxmd"

# ---------- Enable & Start ----------

echo ""
echo "--- Enabling and starting services ---"

rc-update add rnsd default
rc-service rnsd start
echo "    rnsd: enabled and started."

rc-update add lxmd default
rc-service lxmd start
echo "    lxmd: enabled and started."

# ---------- Summary ----------

echo ""
echo "==========================================="
echo "  Installation complete!"
echo "==========================================="
echo ""
echo "  Services:"
echo "    rnsd  -> rc-service rnsd status"
echo "    lxmd  -> rc-service lxmd status"
echo ""
echo "  Configuration:"
echo "    rnsd  -> ${CONFIG_DIR}/config"
echo "    lxmd  -> /etc/lxmd/config"
echo ""
echo "  Logs:"
echo "    rc-service rnsd status        # View rnsd status and recent logs"
echo "    rc-service lxmd status        # View lxmd status and recent logs"
echo "    # If log_file is configured:"
echo "    tail -f /var/log/rnsd.log"
echo "    tail -f /var/log/lxmd.log"
echo ""
echo "  To reconfigure, edit the config files and run:"
echo "    rc-service rnsd restart && rc-service lxmd restart"
echo ""
