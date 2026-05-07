#!/bin/sh
set -e

echo "==> Pre-remove: lxmd"

rc-service lxmd stop 2>/dev/null || true
rc-update del lxmd default 2>/dev/null || true

echo "    Pre-remove complete."