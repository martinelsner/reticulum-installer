#!/bin/sh

echo "==> Pre-install: rnsd"

if ! getent group rnsd > /dev/null 2>&1; then
    addgroup -S rnsd
    echo "    Created group: rnsd"
fi

if ! id rnsd > /dev/null 2>&1; then
    adduser -S -G rnsd -s /sbin/nologin -D rnsd
    addgroup rnsd dialout 2>/dev/null || true
    echo "    Created user: rnsd"
fi

mkdir -p /etc/reticulum/storage
mkdir -p /etc/reticulum/interfaces

setfacl -R -m u::rwX /etc/reticulum 2>/dev/null || chmod -R ugo+rwX /etc/reticulum
setfacl -R -d -m u::rwX /etc/reticulum 2>/dev/null || true
setfacl -R -d -m o::rwX /etc/reticulum 2>/dev/null || true

echo "    Pre-install complete."

exit 0