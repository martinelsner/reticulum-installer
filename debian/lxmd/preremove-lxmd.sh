#!/usr/bin/env bash
set -euo pipefail

echo "==> Pre-remove: lxmd"

systemctl stop lxmd.service 2>/dev/null || true
systemctl disable lxmd.service 2>/dev/null || true

echo "    Pre-remove complete."