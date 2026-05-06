# NixOS Module for Reticulum

This module installs Reticulum Network Stack (`rnsd`) and LXMF Router (`lxmd`) as systemd services using NixOS packages.

## Usage

```nix
let
  reticulum-src = builtins.fetchTarball "https://codeberg.org/melsner/reticulum-installer/archive/main.tar.gz";
in
{
  imports = [ "${reticulum-src}/nixos" ];
  services.rnsd.enable = true;
  services.lxmd.enable = true;
}
```

### Using packages from unstable

```nix
let
  unstable = import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {
    config = { allowUnfree = true; };
  };
  reticulum-src = builtins.fetchTarball "https://codeberg.org/melsner/reticulum-installer/archive/main.tar.gz";
in
{
  imports = [ "${reticulum-src}/nixos" ];
  services.rnsd.enable = true;
  services.rnsd.package = unstable.python313Packages.rns;
  services.lxmd.enable = true;
  services.lxmd.package = unstable.python313Packages.lxmf;
}
```

## What It Does

- Creates the `reticulum` system user (uid 987) with `dialout` group for RNode access
- Installs configs to `/etc/reticulum/config` and `/etc/lxmd/config`
- Sets up systemd services `rnsd.service` and `lxmd.service`

## Configuration

### Service Options

Each service has the following options:

- `services.rnsd.enable` - Enable the Reticulum Network Stack Daemon
- `services.rnsd.package` - Reticulum package to use (default: `pkgs.python313Packages.rns`)
- `services.lxmd.enable` - Enable the LXMF Router Daemon
- `services.lxmd.package` - LXMF package to use (default: `pkgs.python313Packages.lxmf`)

Edit the configuration files after installation:

- `/etc/reticulum/config` - RNS daemon configuration
- `/etc/lxmd/config` - LXMF daemon configuration

Then restart services:

```bash
systemctl restart rnsd lxmd
```
