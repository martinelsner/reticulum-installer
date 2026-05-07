#!/usr/bin/env bash
set -euo pipefail

echo "==> Post-install: lxmd"

systemctl daemon-reload
systemctl enable lxmd.service
systemctl start lxmd.service

echo "    lxmd enabled and started."
echo "    Post-install complete."