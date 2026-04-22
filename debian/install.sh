#!/usr/bin/env bash
#
# Reticulum + LXMF Installer for Debian
#
# Installs rnsd and lxmd as systemd services with a dedicated
# system user, hardened unit files, and default configurations.
#
# Usage: sudo bash install.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONFIG_DIR="/etc/reticulum"
DATA_DIR="/var/lib/reticulum"

# ---------- Preflight ----------

if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root (sudo)."
    exit 1
fi

echo "==> Reticulum + LXMF Installer"
echo ""

# ---------- Dependencies ----------

echo "--- Installing system dependencies ---"
apt-get update
apt-get install -y python3 python3-pip python3-venv
echo "    System packages installed."

VENV_DIR="/opt/reticulum"

echo "--- Installing Python packages ---"
if [[ ! -d "$VENV_DIR" ]]; then
    python3 -m venv "$VENV_DIR"
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
    groupadd --system reticulum
    echo "    Created group: reticulum"
else
    echo "    Group 'reticulum' already exists."
fi

if ! id reticulum > /dev/null 2>&1; then
    useradd \
        --system \
        --gid reticulum \
        --groups dialout \
        --home-dir "$DATA_DIR" \
        --create-home \
        --shell /usr/sbin/nologin \
        reticulum
    echo "    Created user: reticulum (with dialout access for RNodes)"
else
    echo "    User 'reticulum' already exists."
    usermod --append --groups dialout reticulum 2>/dev/null || true
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
    local src="$1"
    local dest="$2"

    mkdir -p "$(dirname "$dest")"

    if [[ -f "$dest" ]]; then
        echo "    SKIP $dest (already exists, not overwriting)"
    else
        cp "$src" "$dest"
        echo "    Installed $dest"
    fi
}

install_config "${SCRIPT_DIR}/../config/rnsd.config" "${CONFIG_DIR}/config"
install_config "${SCRIPT_DIR}/../config/lxmd.config" "${DATA_DIR}/lxmd/config"

# Set permissions per SHARED.md for shared-instance mode:
# - /etc/reticulum: root:reticulum 775 (group write for daemon, world read/execute for clients)
chown root:reticulum "${CONFIG_DIR}"
chmod 775 "${CONFIG_DIR}"

chmod 644 "${CONFIG_DIR}/config"
chmod 644 "${DATA_DIR}/lxmd/config"

# Writable subdirs owned by reticulum
chown -R reticulum:reticulum "${CONFIG_DIR}/storage"
chown reticulum:reticulum "${CONFIG_DIR}/interfaces"
# Ensure storage is world-readable (dirs 755, files get o+r via umask or explicit)
chmod 755 "${CONFIG_DIR}/storage"
chmod -R o+rX "${CONFIG_DIR}/storage"

# Ensure lxmd data directory is owned by reticulum and readable by all for client access
chown -R reticulum:reticulum "${DATA_DIR}/lxmd"
chmod -R o+rX "${DATA_DIR}/lxmd"

echo "    Permissions set for shared-instance mode."

# Keep the daemon's home directory traversable by all (shared-instance clients need access)
chmod 755 "$DATA_DIR"

# ---------- Systemd Units ----------

echo ""
echo "--- Installing systemd service files ---"

cp "${SCRIPT_DIR}/rnsd.service" /etc/systemd/system/rnsd.service
cp "${SCRIPT_DIR}/lxmd.service" /etc/systemd/system/lxmd.service
echo "    Installed rnsd.service"
echo "    Installed lxmd.service"

systemctl daemon-reload
echo "    Reloaded systemd daemon."

# ---------- Enable & Start ----------

echo ""
echo "--- Enabling and starting services ---"

systemctl enable rnsd.service
systemctl start rnsd.service
echo "    rnsd: enabled and started."

systemctl enable lxmd.service
systemctl start lxmd.service
echo "    lxmd: enabled and started."

# ---------- Summary ----------

echo ""
echo "==========================================="
echo "  Installation complete!"
echo "==========================================="
echo ""
echo "  Services:"
echo "    rnsd  -> systemctl status rnsd"
echo "    lxmd  -> systemctl status lxmd"
echo ""
echo "  Configuration:"
echo "    rnsd  -> ${CONFIG_DIR}/config"
echo "    lxmd  -> ${DATA_DIR}/lxmd/config"
echo ""
echo "  Logs:"
echo "    journalctl -u rnsd -f"
echo "    journalctl -u lxmd -f"
echo ""
echo "  To reconfigure, edit the config files and run:"
echo "    systemctl restart rnsd lxmd"
echo ""
