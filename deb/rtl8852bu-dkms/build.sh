#!/bin/bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
VER="20250826"
REV="5"
PKG="rtl8852bu-dkms_${VER}-${REV}_all.deb"
OUT="${OUT:-$HERE}"
SRC="${SRC:-}"
FIRMWARE="${FIRMWARE:-$HERE/firmware/rtl8852bfw_rom.bin}"
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT

echo "== [1/4] source =="
if [ -n "$SRC" ]; then mkdir -p "$BUILD/src" && tar xf "$SRC" -C "$BUILD/src" --strip-components=1; else git clone --quiet --depth 1 https://github.com/morrownr/rtl8852bu-20250826 "$BUILD/src"; fi

echo "== [2/4] apply patches =="
sed -i 's/"build time: %s %s\\n", __DATE__, __TIME__/"build time: n\/a\\n"/' "$BUILD/src/core/rtw_debug.c"

echo "== [3/4] assemble package tree =="
ROOT="$BUILD/root"
mkdir -p "$ROOT/usr/src/rtl8852bu-$VER" "$ROOT/DEBIAN" "$ROOT/lib/firmware/rtl8852b" "$ROOT/etc/usb_modeswitch.d"
cp -a "$BUILD/src/." "$ROOT/usr/src/rtl8852bu-$VER/"
rm -rf "$ROOT/usr/src/rtl8852bu-$VER/.git"
cp "$HERE/dkms.conf" "$ROOT/usr/src/rtl8852bu-$VER/dkms.conf"
cp "$FIRMWARE" "$ROOT/lib/firmware/rtl8852b/"
cp "$HERE/modeswitch.0bda-1a2b" "$ROOT/etc/usb_modeswitch.d/0bda:1a2b"
cp "$HERE/debian/control" "$ROOT/DEBIAN/control"
cp "$HERE/debian/postinst" "$ROOT/DEBIAN/postinst"
cp "$HERE/debian/prerm" "$ROOT/DEBIAN/prerm"
chmod 755 "$ROOT/DEBIAN/postinst" "$ROOT/DEBIAN/prerm"

echo "== [4/4] build deb =="
dpkg-deb --build --root-owner-group "$ROOT" "$OUT/$PKG" > /dev/null
echo "Built: $OUT/$PKG"
