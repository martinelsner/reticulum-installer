#!/bin/sh
set -e

echo "==> Post-remove: rnsd"

echo "    Note: Configuration at /etc/reticulum was NOT removed."
echo "    To remove everything: rm -rf /etc/reticulum && deluser rnsd"

echo "    Post-remove complete."