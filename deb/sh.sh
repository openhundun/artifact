#!/usr/bin/env bash
set -euo pipefail

readonly ARG_JOB="${1:-}"
readonly ARG_STEP="${2:-}"
readonly GIT_REPOSITORY_DIR="$(cd "$(dirname "$(dirname "${0}")")" && pwd)"

function help() {
    echo "USAGE: ${0} <job__rtl8852bu [step__xxx | all]>"
}

function job__rtl8852bu() {
    function step__build() {
        sudo apt-get update
        sudo apt-get install -y --no-install-recommends debhelper dh-dkms dpkg-dev fakeroot
        local repository="https://github.com/morrownr/rtl8852bu-20250826"
        local commit="b6a299b4fe95cb6a37eec27a6c3b21cbaa6abfa8"
        local revision="1"
        local package_dir="${GIT_REPOSITORY_DIR}/deb/rtl8852bu"
        local root="${GIT_REPOSITORY_DIR}/out/rtl8852bu"
        rm -rf "${root}"
        mkdir -p "${root}"
        local build_dir="${root}/source"
        local repo_dir="${root}/repo"
        local package_name="$(basename "${package_dir}")"

        mkdir -p "${build_dir}/upstream"
        git init --quiet "${repo_dir}"
        git -C "${repo_dir}" fetch --quiet --depth 1 "${repository}" "${commit}"
        git -C "${repo_dir}" checkout --quiet --detach "${commit}"

        local upstream_name="$(sed -n 's|^PACKAGE_NAME="\([^"]*\)"|\1|p' "${repo_dir}/dkms.conf" | head -1)"
        local package_version="$(sed -n 's|^PACKAGE_VERSION="\([^"]*\)"|\1|p' "${repo_dir}/dkms.conf" | head -1)"
        local package_maintainer="$(sed -n 's|^Maintainer: ||p' "${package_dir}/debian/control" | head -1)"
        local package_date="$(git -C "${repo_dir}" show -s --format=%cd --date=rfc2822 "${commit}")"
        [[ "${upstream_name}" == "${package_name}" ]]
        [[ -n "${package_version}" ]]

        cp -a "${repo_dir}/." "${build_dir}/upstream/"
        rm -rf "${build_dir}/upstream/.git"
        cp -a "${package_dir}/debian" "${build_dir}/debian"
        cp -a "${package_dir}/rootfs" "${build_dir}/rootfs"

        sed -i 's|"build time: %s %s\\n", __DATE__, __TIME__|"build time: n/a\\n"|' "${build_dir}/upstream/core/rtw_debug.c"
        grep -q 'n/a' "${build_dir}/upstream/core/rtw_debug.c"

        printf '%s (%s-%s) unstable; urgency=medium\n\n  * Package upstream %s %s with dh-dkms.\n\n -- %s  %s\n' "${package_name}" "${package_version}" "${revision}" "${package_name}" "${package_version}" "${package_maintainer}" "${package_date}" > "${build_dir}/debian/changelog"
        printf 'upstream/* /usr/src/%s-%s\nrootfs/etc /\nrootfs/lib/firmware/rtl8852b /usr/lib/firmware\n' "${package_name}" "${package_version}" > "${build_dir}/debian/${package_name}.install"

        cd "${build_dir}"
        dpkg-buildpackage -us -uc -b --ignore-builtin-builddeps

        local package_file="${root}/${package_name}_${package_version}-${revision}_all.deb"
        dpkg-deb --info "${package_file}" > "${root}/control.txt"
        grep -q postinst "${root}/control.txt"
        grep -q prerm "${root}/control.txt"
        echo "Built: ${package_file}"
    }

    function step__release() {
        cd "${GIT_REPOSITORY_DIR}"
        if ! gh release view latest > /dev/null 2>&1; then
            gh release create latest --title "latest" --notes "1" --target "$(git rev-parse HEAD)"
        fi
        gh release upload latest --clobber out/rtl8852bu/*.deb
        rm -rf out/rtl8852bu
    }

    function all() {
        step__build
        step__release
    }

    case "${ARG_STEP}" in
    step__build) step__build ;;
    step__release) step__release ;;
    *) all ;;
    esac
}

case "${ARG_JOB}" in
job__rtl8852bu) job__rtl8852bu ;;
*) help ;;
esac
