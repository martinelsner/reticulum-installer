#!/usr/bin/env bash
set -euo pipefail

echo "==> Post-install: rnsd"

systemctl daemon-reload
systemctl enable rnsd.service
systemctl start rnsd.service

echo "    rnsd enabled and started."
echo "    Post-install complete."