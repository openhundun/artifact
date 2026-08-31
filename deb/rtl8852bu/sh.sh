#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${0}")" && pwd)"
PKG="$(basename "${HERE}")"

REPO="https://github.com/morrownr/rtl8852bu-20250826"
HOMEPAGE="https://github.com/morrownr/rtl8852bu-20250826"
DEPENDS="dkms, usb-modeswitch, bc"
DESCRIPTION="DKMS driver for RTL8852BU/RTL8832BU Wi-Fi 6 USB adapters"

REV="1"
ROOT="$(mktemp -d)"
repo="${ROOT}/repo"
trap 'rm -rf "${ROOT}"' EXIT

main() {
    echo "== [1/4] apt install =="
    sudo apt-get install -y git dpkg-dev > /dev/null

    echo "== [2/4] git clone =="
    git clone --quiet --depth 1 "${REPO}" "${repo}"

    echo "== [3/4] apply patch =="
    sed -i 's/"build time: %s %s\\n", __DATE__, __TIME__/"build time: n\/a\\n"/' "${repo}/core/rtw_debug.c"
    grep -q 'n/a' "${repo}/core/rtw_debug.c"

    echo "== [4/4] build deb =="
    MODULE="$(sed -n 's/^PACKAGE_NAME="\([^"]*\)"/\1/p' "${repo}/dkms.conf" | head -1)"
    VER="$(sed -n 's/^PACKAGE_VERSION="\([^"]*\)"/\1/p' "${repo}/dkms.conf" | head -1)"

    mkdir -p "${ROOT}/usr/src/${MODULE}-${VER}" "${ROOT}/DEBIAN"
    cp -a "${HERE}/rootfs/." "${ROOT}/"
    cp -a "${repo}/." "${ROOT}/usr/src/${MODULE}-${VER}/"
    rm -rf "${ROOT}/usr/src/${MODULE}-${VER}/.git"

    sed \
        -e "s|@PKG@|${PKG}|g" \
        -e "s|@VER@|${VER}|g" \
        -e "s|@REV@|${REV}|g" \
        -e "s|@HOMEPAGE@|${HOMEPAGE}|g" \
        -e "s|@DEPENDS@|${DEPENDS}|g" \
        -e "s|@DESCRIPTION@|${DESCRIPTION}|g" \
        "${HERE}/debian/control.in" \
        > "${ROOT}/DEBIAN/control"
    sed \
        -e "s|@PKG@|${PKG}|g" \
        -e "s|@MODULE@|${MODULE}|g" \
        -e "s|@VER@|${VER}|g" \
        "${HERE}/debian/postinst.in" \
        > "${ROOT}/DEBIAN/postinst"
    sed \
        -e "s|@MODULE@|${MODULE}|g" \
        -e "s|@VER@|${VER}|g" \
        "${HERE}/debian/prerm.in" \
        > "${ROOT}/DEBIAN/prerm"
    chmod 755 "${ROOT}/DEBIAN/postinst" "${ROOT}/DEBIAN/prerm"

    PKGFILE="${PKG}_${VER}-${REV}_all.deb"
    dpkg-deb --build --root-owner-group "${ROOT}" "${HERE}/${PKGFILE}" > /dev/null
    echo "Built: ${HERE}/${PKGFILE}"
}

main
