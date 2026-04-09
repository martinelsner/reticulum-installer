# Reticulum + LXMF Installer

This repository provides installation, configuration, and uninstallation scripts for deploying [Reticulum Network Stack](https://reticulum.network/) (`rnsd`) and its messaging router (`lxmd`) as background services. 

The scripts set up services within Python virtual environments running under a dedicated system user.

## Supported Architectures

Choose your operating system to view detailed installation instructions:

- [**Debian / Ubuntu / Linux Mint**](debian/README.md) (uses `systemd` and `apt`)
- [**Alpine Linux**](alpine/README.md) (uses `OpenRC` and `apk`)

## Features
- **Isolated:** Installs Python packages into a virtual environment at `/opt/reticulum`.
- **Dedicated System User:** Services run as the unprivileged `reticulum` user. `dialout` access is granted for hardware interfaces like RNodes.
- **Default Configuration:** Includes baseline configurations for typical router node setups.
- **Testing:** Includes Docker-based integration tests.

## License

This project is open-source and licensed under the [MIT License](LICENSE). You are free to use, modify, and distribute it as you see fit.

## AI Contribution

AI tools were used to help build this project. Generated code is reviewed by a seasoned developer exercising common sense and practical experience. If you happen to spot any bugs or edge cases, please feel free to open an issue or pull request.
