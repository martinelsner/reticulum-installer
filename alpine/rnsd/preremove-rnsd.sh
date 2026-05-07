#!/bin/sh
set -e

echo "==> Pre-remove: rnsd"

rc-service rnsd stop 2>/dev/null || true
rc-update del rnsd default 2>/dev/null || true

echo "    Pre-remove complete."