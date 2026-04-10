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
4. Establish `/var/lib/reticulum` as the data layout directory and copy across default OS-agnostic configurations.
5. Setup, enable, and start the OpenRC initialization scripts: `/etc/init.d/rnsd` and `/etc/init.d/lxmd`.
6. Symlink the software to `/usr/local/bin` for system-wide accessibility.

## Data Files

Service data is stored at `/var/lib/reticulum/` with per-service subdirectories:
- **`rnsd`**: `/var/lib/reticulum/rnsd/`
- **`lxmd`**: `/var/lib/reticulum/lxmd/`

## Managing the Service

**Service Status:**
```bash
rc-service rnsd status
rc-service lxmd status
```

**Viewing Logs:**
```bash
# Individual logs
sudo tail -f /var/lib/reticulum/rnsd/logfile
sudo tail -f /var/lib/reticulum/lxmd/logfile

# Combined logs
sudo tail -f /var/lib/reticulum/rnsd/logfile /var/lib/reticulum/lxmd/logfile
```

**Restarting After Config Changes:**
```bash
rc-service rnsd restart && rc-service lxmd restart
```

## Uninstallation

If you wish to cleanly tear down the virtual environment and stop the services completely, while leaving your user data and identity intact, run the uninstall script:

```bash
sudo sh uninstall.sh
```

To purge the deployment entirely (including identities, messages and databases), also run:
```bash
sudo rm -rf /var/lib/reticulum
sudo deluser reticulum
```
