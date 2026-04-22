# Alpine Installation

Automated deployment for Alpine Linux. This environment leverages `apk` for system dependencies and `OpenRC` for lightweight background daemon persistence.

## Quick Install

To install `rnsd` and `lxmd` cleanly with all configurations and service dependencies, download the deployment files and run the installer from a temporary directory:

```bash
sudo apk add curl
curl -sSL https://codeberg.org/melsner/reticulum-installer/archive/main.tar.gz | tar -xz -C /tmp
cd /tmp/reticulum-installer/alpine
sudo sh install.sh
```

## What This Does

Running the installer script will:

1. Install required system packages (`python3`, `py3-pip`, `py3-virtualenv`).
2. Build a virtual environment at `/opt/reticulum` and securely install `rns` and `lxmf`.
3. Create the `reticulum` unprivileged system user.
4. Establish `/etc/reticulum` for Reticulum config, `/var/lib/reticulum/lxmd` for LXMF config, and `/etc/reticulum/storage` for shared storage.
5. Setup, enable, and start the OpenRC initialization scripts: `/etc/init.d/rnsd` and `/etc/init.d/lxmd`.
6. Symlink the software and status wrappers to `/usr/local/bin` for system-wide accessibility.

## Data Files

Reticulum configuration is stored in `/etc/reticulum/`:
- **`rnsd` config**: `/etc/reticulum/config`

Shared instance storage (identities, path tables, caches) is at `/etc/reticulum/storage/`.

LXMF configuration and data are stored in `/var/lib/reticulum/lxmd/`:
- **`lxmd` config**: `/var/lib/reticulum/lxmd/config`

## Managing the Service

**Service Status:**
```bash
rc-service rnsd status
rc-service lxmd status
```

**Viewing Logs:**
```bash
# System logs via OpenRC
rc-service rnsd status
rc-service lxmd status

# If log_file is configured in the config:
sudo tail -f /var/log/rnsd.log
sudo tail -f /var/log/lxmd.log
```

**Restarting After Config Changes:**
```bash
rc-service rnsd restart && rc-service lxmd restart
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
sudo sh uninstall.sh
```

To purge the deployment entirely (including identities, messages and databases), also run:
```bash
sudo rm -rf /etc/reticulum /var/lib/reticulum
sudo deluser reticulum
```
