# Debian Installation

Automated deployment for Debian-based systems. This environment leverages `apt` for system dependencies and `systemd` for hardened, self-healing background daemons.

## Quick Install

To install `rnsd` and `lxmd` cleanly with all configurations and service dependencies, download the deployment files and run the installer from a temporary directory:

```bash
sudo apt install curl
curl -sSL https://codeberg.org/melsner/reticulum-installer/archive/main.tar.gz | tar -xz -C /tmp
cd /tmp/reticulum-installer/debian
sudo bash install.sh
```

## What This Does

Running the installer script will:

1. Install required system packages (`python3`, `python3-pip`, `python3-venv`).
2. Build a virtual environment at `/opt/reticulum` and securely install `rns` and `lxmf`.
3. Create the `reticulum` unprivileged system user.
4. Establish `/var/lib/reticulum` as the data layout directory and copy across default OS-agnostic configurations.
5. Create, harden, enable, and start the systemd unit files: `rnsd.service` and `lxmd.service`.
6. Symlink the software and status wrappers to `/usr/local/bin` for system-wide accessibility.

## Data Files

Service data is stored at `/var/lib/reticulum/` with per-service subdirectories:
- **`rnsd`**: `/var/lib/reticulum/rnsd/`
- **`lxmd`**: `/var/lib/reticulum/lxmd/`

## Managing the Service

**Service Status:**
```bash
sudo systemctl status rnsd lxmd
```

**Viewing Logs:**
```bash
# Individual logs
sudo journalctl -u rnsd -f
sudo journalctl -u lxmd -f

# Combined logs
sudo journalctl -u rnsd -u lxmd -f
```

**Restarting After Config Changes:**
```bash
sudo systemctl restart rnsd lxmd
```

## Status Monitoring

The installer also provides wrapper scripts for quick status checks:

- **`rnsd-status`** - Runs `rnstatus` to display Reticulum network interfaces and transport status.
- **`lxmd-status`** - Runs `lxmd --status` to display LXMF router status, including peer connections and message statistics.

Both scripts automatically use the correct configuration paths. No additional arguments are required, but any extra arguments will be passed through to the underlying command.

```bash
# Check Reticulum status
rnsd-status

# Check LXMF status
lxmd-status
```

## Uninstallation

If you wish to cleanly tear down the virtual environment and stop the services completely, while leaving your user data and identity intact, run the uninstall script:

```bash
sudo bash uninstall.sh
```

To purge the deployment entirely (including identities, messages and databases), also run:
```bash
sudo rm -rf /var/lib/reticulum
sudo userdel reticulum
```
