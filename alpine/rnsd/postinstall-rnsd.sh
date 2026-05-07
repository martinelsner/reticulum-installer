#!/bin/sh
set -e

echo "==> Post-install: rnsd"

addgroup -S rnsd 2>/dev/null || true
adduser -S -H -h /sbin/nologin -s /sbin/nologin -G rnsd rnsd 2>/dev/null || true
addgroup rnsd dialout 2>/dev/null || true

openrc boot 2>/dev/null || true

rc-update add rnsd default 2>/dev/null || true
rc-service rnsd start 2>/dev/null || true

i=0
while [ $i -lt 5 ]; do
    if rc-service rnsd status >/dev/null 2>&1; then
        break
    fi
    i=$((i + 1))
    sleep 1
done

echo "    rnsd enabled and started."
echo "    Post-install complete."