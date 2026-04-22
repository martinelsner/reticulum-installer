# NixOS Module for Reticulum

This module installs Reticulum Network Stack (`rnsd`) and LXMF Router (`lxmd`) as systemd services using NixOS packages.

## Usage

```nix
let
  unstable = import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {};
  reticulum = import (builtins.fetchTarball "https://codeberg.org/melsner/reticulum-installer/archive/main.tar.gz") {
    pkgs = unstable;
  };
in
{
  imports = [ reticulum.nixos ];
  services.reticulum.enable = true;
}
```

## What It Does

- Creates the `reticulum` system user (uid 987) with `dialout` group for RNode access
- Installs configs to `/etc/reticulum/config` and `/var/lib/reticulum/lxmd/config`
- Sets up systemd services `rnsd.service` and `lxmd.service`

## Configuration

Edit the configuration files after installation:

- `/etc/reticulum/config` - RNS daemon configuration
- `/var/lib/reticulum/lxmd/config` - LXMF daemon configuration

Then restart services:

```bash
systemctl restart rnsd lxmd
```
