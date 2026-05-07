#!/usr/bin/env bash
set -euo pipefail

echo "==> Post-remove: rnsd"

systemctl daemon-reload

echo "    Note: Configuration at /etc/reticulum was NOT removed."
echo "    To remove everything: rm -rf /etc/reticulum && userdel rnsd"

echo "    Post-remove complete."