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

install_config "${SCRIPT_DIR}/../config/rnsd.config" "${DATA_DIR}/rnsd/config"
install_config "${SCRIPT_DIR}/../config/lxmd.config" "${DATA_DIR}/lxmd/config"

chown -R reticulum:reticulum "$DATA_DIR"
chmod 750 "$DATA_DIR"

echo "    Ownership set to reticulum:reticulum on ${DATA_DIR}"

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
echo "    rnsd  -> ${DATA_DIR}/rnsd/config"
echo "    lxmd  -> ${DATA_DIR}/lxmd/config"
echo ""
echo "  Logs:"
echo "    journalctl -u rnsd -f"
echo "    journalctl -u lxmd -f"
echo ""
echo "  To reconfigure, edit the config files and run:"
echo "    systemctl restart rnsd lxmd"
echo ""
