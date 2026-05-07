#!/usr/bin/env bash
set -euo pipefail

echo "==> Pre-remove: rnsd"

systemctl stop rnsd.service 2>/dev/null || true
systemctl disable rnsd.service 2>/dev/null || true

echo "    Pre-remove complete."