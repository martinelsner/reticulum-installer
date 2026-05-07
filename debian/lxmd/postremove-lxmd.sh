#!/usr/bin/env bash
set -euo pipefail

echo "==> Post-remove: lxmd"

systemctl daemon-reload

echo "    Note: Configuration at /etc/lxmd was NOT removed."
echo "    To remove everything: rm -rf /etc/lxmd && userdel lxmd"

echo "    Post-remove complete."