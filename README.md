# Reticulum + LXMF Installer

This repository provides automated installation, configuration, and uninstallation scripts for deploying [Reticulum Network Stack](https://reticulum.network/) (`rnsd`) and its messaging router (`lxmd`) as background daemons. 

We support multiple Linux distributions with hardened architectures. All services are deployed over modern Python virtual environments and secured under a dedicated, unprivileged system account.

## Supported Architectures

Choose your operating system to view detailed installation instructions:

- [**Debian / Ubuntu / Linux Mint**](debian/README.md) (uses `systemd` and `apt`)
- [**Alpine Linux**](alpine/README.md) (uses `OpenRC` and `apk`)

## Features
- **Isolated:** Installs Python binaries cleanly using a system-wide Virtual Environment at `/opt/reticulum`.
- **Hardened System Account:** Processes run unprivileged as the `reticulum` user with no login shell. Dialout access is granted to allow hardware interfaces like RNodes.
- **Configured & Ready:** Provides pre-customized, optimal minimal configurations tuned for shared instances and router node topology.
- **Tested:** Tested securely through ephemeral Docker containers.

## License

This project is open-source and licensed under the [MIT License](LICENSE). You are free to use, modify, and distribute it as you see fit.

## AI Contribution

AI tools were used to help build this project, but all generated code remained under the strict control of a seasoned developer exercising common sense and practical experience. If you happen to spot any bugs or edge cases, please feel free to open an issue or pull request.
