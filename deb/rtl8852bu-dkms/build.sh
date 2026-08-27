#!/bin/bash
set -euo pipefail

HERE="$(cd "$(dirname "${0}")" && pwd)"
VER="20250826"
REV="5"
PKG="rtl8852bu-dkms_${VER}-${REV}_all.deb"
OUT="${OUT:-${HERE}}"
SRC="${SRC:-}"
BUILD="$(mktemp -d)"
trap 'rm -rf "${BUILD}"' EXIT

main() {
    mkdir -p "${OUT}"
    for c in git tar dpkg-deb; do
        if ! command -v "${c}" > /dev/null; then
            echo "missing dependency: ${c}" >&2
            exit 1
        fi
    done
    control_ver="$(sed -n 's/^Version: //p' "${HERE}/debian/control")"
    dkms_ver="$(sed -n 's/^PACKAGE_VERSION="\(.*\)"/\1/p' "${HERE}/dkms.conf")"
    if [[ "${control_ver}" != "${VER}-${REV}" ]] || [[ "${dkms_ver}" != "${VER}" ]]; then
        echo "version mismatch: control=${control_ver} dkms=${dkms_ver} expected ${VER}-${REV}/${VER}" >&2
        exit 1
    fi

    echo "== [1/4] fetch source =="
    mkdir -p "${BUILD}/src"
    if [[ -n "${SRC}" ]]; then
        tar xf "${SRC}" -C "${BUILD}/src" --strip-components=1
    else
        git clone --quiet --depth 1 https://github.com/morrownr/rtl8852bu-20250826 "${BUILD}/src"
    fi

    echo "== [2/4] apply patch =="
    sed -i 's/"build time: %s %s\\n", __DATE__, __TIME__/"build time: n\/a\\n"/' "${BUILD}/src/core/rtw_debug.c"
    if ! grep -q 'n/a' "${BUILD}/src/core/rtw_debug.c"; then
        echo "patch not applied (upstream source changed?)" >&2
        exit 1
    fi

    echo "== [3/4] assemble =="
    ROOT="${BUILD}/root"
    mkdir -p "${ROOT}/usr/src/rtl8852bu-${VER}" "${ROOT}/DEBIAN"
    cp -a "${HERE}/rootfs/." "${ROOT}/"
    cp -a "${BUILD}/src/." "${ROOT}/usr/src/rtl8852bu-${VER}/"
    rm -rf "${ROOT}/usr/src/rtl8852bu-${VER}/.git"
    cp "${HERE}/dkms.conf" "${ROOT}/usr/src/rtl8852bu-${VER}/dkms.conf"
    cp "${HERE}/debian/control" "${ROOT}/DEBIAN/control"
    cp "${HERE}/debian/postinst" "${ROOT}/DEBIAN/postinst"
    cp "${HERE}/debian/prerm" "${ROOT}/DEBIAN/prerm"
    chmod 755 "${ROOT}/DEBIAN/postinst" "${ROOT}/DEBIAN/prerm"

    echo "== [4/4] build deb =="
    dpkg-deb --build --root-owner-group "${ROOT}" "${OUT}/${PKG}" > /dev/null
    echo "Built: ${OUT}/${PKG}"
}

main "$@"
