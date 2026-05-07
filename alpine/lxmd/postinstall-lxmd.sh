#!/bin/sh
set -e

echo "==> Post-install: lxmd"

addgroup -S lxmd 2>/dev/null || true
adduser -S -H -h /sbin/nologin -s /sbin/nologin -G lxmd lxmd 2>/dev/null || true

openrc boot 2>/dev/null || true

rc-update add rnsd default 2>/dev/null || true
rc-update add lxmd default 2>/dev/null || true
rc-service rnsd start 2>/dev/null || true

i=0
while [ $i -lt 5 ]; do
    if rc-service lxmd status >/dev/null 2>&1; then
        break
    fi
    i=$((i + 1))
    sleep 1
done

echo "    lxmd enabled and started."
echo "    Post-install complete."