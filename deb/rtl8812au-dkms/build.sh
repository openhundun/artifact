#!/bin/bash
set -euo pipefail

HERE="$(cd "$(dirname "${0}")" && pwd)"
VER="5.6.4.2"
REV="1"
PKG="rtl8812au-dkms_${VER}-${REV}_all.deb"
BUILD="$(mktemp -d)"
trap 'rm -rf "${BUILD}"' EXIT

main() {
    echo "== [1/4] install dependencies =="
    sudo apt-get install -y git dpkg-dev > /dev/null

    echo "== [2/4] clone source =="
    git clone --quiet --depth 1 https://github.com/aircrack-ng/rtl8812au "${BUILD}/src"

    echo "== [3/4] apply patch =="
    sed -i 's/KERNEL_VERSION(6, 13, 0)/KERNEL_VERSION(6, 12, 0)/' "${BUILD}/src/os_dep/linux/ioctl_cfg80211.c"
    if ! grep -q 'KERNEL_VERSION(6, 12, 0)' "${BUILD}/src/os_dep/linux/ioctl_cfg80211.c"; then
        echo "patch not applied (upstream source changed?)" >&2
        exit 1
    fi

    echo "== [4/4] build deb =="
    ROOT="${BUILD}/root"
    mkdir -p "${ROOT}/usr/src/rtl8812au-${VER}" "${ROOT}/DEBIAN"
    cp -a "${BUILD}/src/." "${ROOT}/usr/src/rtl8812au-${VER}/"
    rm -rf "${ROOT}/usr/src/rtl8812au-${VER}/.git"
    cp "${HERE}/dkms.conf" "${ROOT}/usr/src/rtl8812au-${VER}/dkms.conf"
    cp "${HERE}/debian/control" "${ROOT}/DEBIAN/control"
    cp "${HERE}/debian/postinst" "${ROOT}/DEBIAN/postinst"
    cp "${HERE}/debian/prerm" "${ROOT}/DEBIAN/prerm"
    chmod 755 "${ROOT}/DEBIAN/postinst" "${ROOT}/DEBIAN/prerm"
    dpkg-deb --build --root-owner-group "${ROOT}" "${HERE}/${PKG}" > /dev/null
    echo "Built: ${HERE}/${PKG}"
}

main
