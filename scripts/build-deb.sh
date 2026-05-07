#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/debian/build"
STAGING_DIR="${BUILD_DIR}/staging"
OUT_DIR="${BUILD_DIR}/out"

echo "==> Building Debian packages"

rm -rf "$STAGING_DIR" "$OUT_DIR"
mkdir -p "$STAGING_DIR/opt/reticulum"
mkdir -p "$STAGING_DIR/etc/reticulum/storage"
mkdir -p "$STAGING_DIR/etc/reticulum/interfaces"
mkdir -p "$STAGING_DIR/etc/lxmd"
mkdir -p "$STAGING_DIR/etc/default"
mkdir -p "$STAGING_DIR/usr/local/bin"
mkdir -p "$OUT_DIR"

echo "--- Creating Python virtualenv ---"
python3 -m venv "$STAGING_DIR/opt/reticulum"

echo "--- Installing Python packages ---"
"$STAGING_DIR/opt/reticulum/bin/pip" install --quiet rns lxmf bleak

echo "--- Detecting package versions ---"
RNS_VERSION="$("$STAGING_DIR/opt/reticulum/bin/pip" show rns | grep -E '^Version:' | awk '{print $2}')"
LXMF_VERSION="$("$STAGING_DIR/opt/reticulum/bin/pip" show lxmf | grep -E '^Version:' | awk '{print $2}')"
echo "    rns: $RNS_VERSION"
echo "    lxmf: $LXMF_VERSION"

echo "--- Installing configurations ---"
install -m 644 "$PROJECT_DIR/config/rnsd.config" "$STAGING_DIR/etc/reticulum/config"
install -m 644 "$PROJECT_DIR/config/lxmd.config" "$STAGING_DIR/etc/lxmd/config"

echo "--- Setting permissions ---"
chmod -R u=rwX,go=rX "$STAGING_DIR/etc/reticulum"
chmod -R u=rwX,go=rX "$STAGING_DIR/etc/lxmd"
chmod -R go+X "$STAGING_DIR/opt/reticulum/bin"

# Ensure lxmd config directory exists
mkdir -p "$STAGING_DIR/etc/lxmd"

install -m 644 /dev/null "$STAGING_DIR/etc/default/reticulum"
echo "RETICULUM_USER=rnsd" >> "$STAGING_DIR/etc/default/reticulum"
echo "RETICULUM_GROUP=rnsd" >> "$STAGING_DIR/etc/default/reticulum"

mkdir -p "$STAGING_DIR/debian/rnsd"
for script in "$PROJECT_DIR/debian/rnsd"/*.sh; do
    if [ -f "$script" ]; then
        install -m 755 "$script" "$STAGING_DIR/debian/rnsd/"
    fi
done
install -m 644 "$PROJECT_DIR/debian/rnsd/rnsd.service" "$STAGING_DIR/debian/rnsd/"
install -m 644 "$PROJECT_DIR/debian/rnsd/sudoers-rnsd" "$STAGING_DIR/debian/rnsd/"

mkdir -p "$STAGING_DIR/debian/lxmd"
for script in "$PROJECT_DIR/debian/lxmd"/*.sh; do
    if [ -f "$script" ]; then
        install -m 755 "$script" "$STAGING_DIR/debian/lxmd/"
    fi
done
install -m 644 "$PROJECT_DIR/debian/lxmd/lxmd.service" "$STAGING_DIR/debian/lxmd/"
install -m 644 "$PROJECT_DIR/debian/lxmd/sudoers-lxmd" "$STAGING_DIR/debian/lxmd/"

cd "$STAGING_DIR"

build_pkg() {
    local name="$1"
    local yaml_src="$2"
    local pkg_type="$3"
    local version="$4"
    local tmp_yaml="/tmp/nfpm-${name}.yml"

    sed "s/\${RNS_VERSION:-0.0.0}/$version/g; s/\${LXMF_VERSION:-0.0.0}/$version/g" "$yaml_src" > "$tmp_yaml"
    echo "    Building $name ($version)"
    nfpm package -f "$tmp_yaml" -p "$pkg_type" -t "$OUT_DIR"
    rm -f "$tmp_yaml"
}

echo ""
echo "--- Building packages ---"
build_pkg "rnsd" "$PROJECT_DIR/debian/rnsd/nfpm.yml" deb "$RNS_VERSION"
build_pkg "lxmd" "$PROJECT_DIR/debian/lxmd/nfpm.yml" deb "$LXMF_VERSION"

echo ""
echo "==> Packages built successfully!"
ls -lh "$OUT_DIR/"