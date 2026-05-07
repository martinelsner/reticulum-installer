# Debian Installation

Three packages must be installed in order:

1. **`reticulum-common`** - Python virtualenv with rns, lxmf, bleak + config directories
2. **`rnsd`** - Reticulum Network Stack daemon (depends on reticulum-common)
3. **`lxmd`** - LXMF Router daemon (depends on reticulum-common)

## Quick Install

```bash
sudo dpkg -i reticulum-common_0.1.0_amd64.deb rnsd_0.1.0_amd64.deb lxmd_0.1.0_amd64.deb
```

## What This Does

The package installer will:

1. Create dedicated users `rnsd` and `lxmd` (each with their own group).
2. Establish `/etc/reticulum` for Reticulum config, `/etc/lxmd` for LXMF config.
3. Install the Python virtual environment at `/opt/reticulum` with `rns`, `lxmf`, and `bleak`.
4. Create systemd service files and enable/start the services.
5. Symlink binaries to `/usr/local/bin` for system-wide accessibility.

## Data Files

Reticulum configuration is stored in `/etc/reticulum/`:
- **`rnsd` config**: `/etc/reticulum/config`

Shared instance storage (identities, path tables, caches) is at `/etc/reticulum/storage/`.

LXMF configuration and data are stored in `/etc/lxmd/`:
- **`lxmd` config**: `/etc/lxmd/config`

## Managing the Services

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

The packages provide wrapper scripts for quick status checks:

- **`rnsd-status`** - Runs `rnstatus` to display Reticulum network interfaces and transport status.
- **`lxmd-status`** - Runs `lxmd --status` to display LXMF router status.

Both scripts automatically use the correct configuration paths.

```bash
# Check Reticulum status
rnsd-status

# Check LXMF status
lxmd-status
```

## Uninstallation

```bash
sudo dpkg -r lxmd rnsd reticulum-common
```

To purge the deployment entirely (including identities, messages and databases), also run:
```bash
sudo rm -rf /etc/reticulum /etc/lxmd
sudo userdel rnsd lxmd
```