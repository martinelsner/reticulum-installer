#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/alpine/build"
OUT_DIR="${BUILD_DIR}/out"

echo "==> Building Alpine packages with abuild"

rm -rf "$BUILD_DIR" 2>/dev/null || true
mkdir -p "$OUT_DIR"

cat > /tmp/build-apk.sh << 'SCRIPT_EOF'
#!/bin/sh
set -e

echo "--- Installing build dependencies ---"
apk add --no-cache bash abuild alpine-sdk sudo doas python3 py3-pip

addgroup -S abuild 2>/dev/null || true
adduser -D -u 1000 -G abuild abuild 2>/dev/null || true

mkdir -p /home/abuild/.abuild
chown abuild:abuild /home/abuild/.abuild 2>/dev/null || true

openssl genrsa -out /home/abuild/.abuild/builder.rsa 4096
openssl rsa -in /home/abuild/.abuild/builder.rsa -pubout -out /home/abuild/.abuild/builder.rsa.pub
cp /home/abuild/.abuild/builder.rsa.pub /etc/apk/keys/

echo "PACKAGER_PRIVKEY=/home/abuild/.abuild/builder.rsa" > /home/abuild/.abuild/abuild.conf
chown abuild:abuild /home/abuild/.abuild/abuild.conf
chown abuild:abuild /home/abuild/.abuild/builder.rsa
chmod 600 /home/abuild/.abuild/builder.rsa

echo "abuild ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

ABUILD_DIR=/home/abuild/packages
mkdir -p "$ABUILD_DIR"
chown abuild:abuild "$ABUILD_DIR"

echo "--- Building rnsd package ---"
mkdir -p /tmp/build-rnsd
cp /src/alpine/rnsd/APKBUILD /tmp/build-rnsd/
cp /src/alpine/rnsd/rnsd.initd /tmp/build-rnsd/
cp /src/alpine/rnsd/sudoers-rnsd /tmp/build-rnsd/
cp /src/alpine/rnsd/rnsd.pre-install /tmp/build-rnsd/
cp /src/alpine/rnsd/rnsd.post-install /tmp/build-rnsd/
cp /src/config/rnsd.config /tmp/build-rnsd/config

chown -R abuild:abuild /tmp/build-rnsd
chmod 755 /tmp/build-rnsd/APKBUILD

sudo -u abuild sh -c "cd /tmp/build-rnsd && /usr/bin/abuild checksum"
sudo -u abuild sh -c "cd /tmp/build-rnsd && /usr/bin/abuild -F -r"

echo "--- Copying rnsd package ---"
find /home/abuild/packages/ -name "rnsd-*.apk" -exec cp {} /out/ \; 2>/dev/null || true
ls -la /out/

echo ""
echo "==> rnsd package built successfully!"
ls -lh /out/
SCRIPT_EOF

chmod +x /tmp/build-apk.sh

docker run --rm \
    -v "$PROJECT_DIR:/src:ro" \
    -v "$OUT_DIR:/out:rw" \
    -v /tmp/build-apk.sh:/build-apk.sh:ro \
    alpine:3.21 sh /build-apk.sh