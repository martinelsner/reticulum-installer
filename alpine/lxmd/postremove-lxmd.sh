#!/bin/sh
set -e

echo "==> Post-remove: lxmd"

echo "    Note: Configuration at /etc/lxmd was NOT removed."
echo "    To remove everything: rm -rf /etc/lxmd && deluser lxmd"

echo "    Post-remove complete."