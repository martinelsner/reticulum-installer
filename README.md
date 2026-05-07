# Reticulum + LXMF Installer

This repository provides native packages for deploying [Reticulum Network Stack](https://reticulum.network/) and [LXMF](https://github.com/markqvist/LXMF) as background services.

## Packages

Three packages are provided:

| Package | Description |
|---------|-------------|
| `reticulum-common` | Python virtualenv with rns, lxmf, bleak + config directories |
| `rnsd` | Reticulum Network Stack daemon (depends on reticulum-common) |
| `lxmd` | LXMF Router daemon (depends on reticulum-common) |

Each service runs under its own dedicated user.

## Supported Architectures

- **Debian / Ubuntu / Linux Mint** - Install via `.deb` packages
- **Alpine Linux** - Install via `.apk` packages
- **NixOS** - Uses NixOS module (separate, not packaged here)

## Quick Install

### Debian/Ubuntu

```bash
sudo dpkg -i reticulum-common_0.1.0_amd64.deb rnsd_0.1.0_amd64.deb lxmd_0.1.0_amd64.deb
```

### Alpine

```bash
sudo apk add --allow-untrusted reticulum-common_0.1.0_x86_64.apk rnsd_0.1.0_x86_64.apk lxmd_0.1.0_x86_64.apk
```

## Building from Source

This project uses [nfpm](https://nfpm.goreleaser.com/) for packaging. To build packages:

```bash
nix-shell --run "make build"
```

## Features
- **Isolated:** Each service runs under its own dedicated user (`rnsd`, `lxmd`).
- **Shared runtime:** Python virtualenv at `/opt/reticulum` is shared but configs are separate.
- **Default Configuration:** Includes baseline configurations for typical router node setups.
- **Package-based:** Uses native package managers for clean installation/removal.

## See Also

- [SHARED](SHARED.md) - Running a system-wide Reticulum instance that all users can share

## License

This project is open-source and licensed under the [MIT License](LICENSE). You are free to use, modify, and distribute it as you see fit.

## AI Contribution

AI tools were used to help build this project. Generated code is reviewed by a seasoned developer exercising common sense and practical experience. If you happen to spot any bugs or edge cases, please feel free to open an issue or pull request.