# Debian Installation

Automated deployment for Debian-based systems. This environment leverages `apt` for system dependencies and `systemd` for hardened, self-healing background daemons.

## Quick Install

To install `rnsd` and `lxmd` directly on any Debian-based machine, run the following command:

```bash
curl -sSL <YOUR_URL_HERE> | sudo bash
```

> **Note:** Replace `<YOUR_URL_HERE>` with the final URL when deployed.

## What This Does

Running the installer script will:

1. Install required system packages (`python3`, `python3-pip`, `python3-venv`).
2. Build a virtual environment at `/opt/reticulum` and securely install `rns` and `lxmf`.
3. Create the `reticulum` unprivileged system user.
4. Establish `/var/lib/reticulum` as the data layout directory and copy across default OS-agnostic configurations.
5. Create, harden, enable, and start the systemd unit files: `rnsd.service` and `lxmd.service`.
6. Symlink the software to `/usr/local/bin` for system-wide accessibility.

## Managing the Service

**Service Status:**
```bash
sudo systemctl status rnsd lxmd
```

**Viewing Logs:**
```bash
sudo journalctl -u rnsd -f
sudo journalctl -u lxmd -f
```

**Restarting After Config Changes:**
```bash
sudo systemctl restart rnsd lxmd
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
