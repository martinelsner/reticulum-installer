#!/bin/sh
set -e

echo "==> Pre-install: lxmd"

if ! getent group lxmd > /dev/null 2>&1; then
    addgroup -S lxmd
    echo "    Created group: lxmd"
fi

if ! id lxmd > /dev/null 2>&1; then
    adduser -S -G lxmd -s /sbin/nologin -D lxmd
    echo "    Created user: lxmd"
fi

mkdir -p /etc/lxmd

setfacl -R -m u::rwX /etc/lxmd 2>/dev/null || chmod -R ugo+rwX /etc/lxmd
setfacl -R -d -m u::rwX /etc/lxmd 2>/dev/null || true
setfacl -R -d -m o::rwX /etc/lxmd 2>/dev/null || true

echo "    Pre-install complete."