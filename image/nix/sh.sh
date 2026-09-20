#!/usr/bin/env bash
set -euo pipefail

readonly FLAKE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FLAKE_REF="path:${FLAKE_DIR}"
readonly REGISTRY="${IMAGE_REGISTRY:-192.168.100.101:3000/openhundun}"
readonly SOURCE_URL="https://github.com/openhundun/artifact"
readonly SYSTEM_AMD64="x86_64-linux"
readonly SYSTEM_ARM64="aarch64-linux"
readonly ARCH_AMD64="amd64"
readonly ARCH_ARM64="arm64"

function nix_cmd() {
    if command -v nix > /dev/null; then
        echo "nix"
        return 0
    fi
    echo "/nix/var/nix/profiles/default/bin/nix"
}

function help() {
    echo "usage: ${0} {list|build|load|publish} <image|all> [system]"
    echo "       ${0} -h | --help"
    echo
    echo "image   形如 nix-python:2.35.2-3.13；也可只写 nix-python 表示该名字的全部 tag；all 表示全部镜像"
    echo "system  ${SYSTEM_AMD64} | ${SYSTEM_ARM64}"
    echo "registry 由 IMAGE_REGISTRY 覆盖，当前 ${REGISTRY}"
}

function list() {
    local system="${1:-${SYSTEM_AMD64}}"
    "$(nix_cmd)" eval --raw --apply 'x: builtins.concatStringsSep "\n" (builtins.attrNames x)' "${FLAKE_REF}#packages.${system}"
}

function each_image() {
    local selector="${1:?selector}"
    local system="${2:-${SYSTEM_AMD64}}"
    local image
    case "${selector}" in
    all) list "${system}" ;;
    *:*) echo "${selector}" ;;
    *)
        while IFS= read -r image; do
            case "${image}" in
            "${selector}":*) echo "${image}" ;;
            esac
        done <<< "$(list "${system}")"
        ;;
    esac
}

function build_one() {
    local image="${1:?image}"
    local system="${2:-${SYSTEM_AMD64}}"
    "$(nix_cmd)" build --no-link --print-out-paths "${FLAKE_REF}#packages.${system}.\"${image}\""
}

function images_or_die() {
    local selector="${1:?selector}"
    local system="${2:-${SYSTEM_AMD64}}"
    local images
    images="$(each_image "${selector}" "${system}")"
    if [ -z "${images}" ]; then
        echo "ERROR: 选择器 ${selector} 没有匹配到任何镜像" >&2
        return 1
    fi
    echo "${images}"
}

function build() {
    local selector="${1:?selector}"
    local system="${2:-${SYSTEM_AMD64}}"
    local images
    images="$(images_or_die "${selector}" "${system}")"
    while IFS= read -r image; do
        echo "==> ${image} (${system})" >&2
        build_one "${image}" "${system}"
    done <<< "${images}"
}

function load() {
    local selector="${1:?selector}"
    local system="${2:-${SYSTEM_AMD64}}"
    each_image "${selector}" "${system}" | while IFS= read -r image; do
        echo "==> ${image} (${system})" >&2
        docker load --input "$(build_one "${image}" "${system}")"
    done
}

function arch() {
    case "${1}" in
    "${SYSTEM_AMD64}") echo "${ARCH_AMD64}" ;;
    "${SYSTEM_ARM64}") echo "${ARCH_ARM64}" ;;
    *) return 1 ;;
    esac
}

function dest_tls() {
    case "${REGISTRY}" in
    ghcr.io/*) echo "--dest-tls-verify=true" ;;
    *) echo "--dest-tls-verify=false" ;;
    esac
}

function push() {
    local image="${1:?image}"
    local system="${2:?system}"
    local name="${image%%:*}"
    local tag="${image#*:}"
    local arch_name="$(arch "${system}")"
    local tar="$(build_one "${image}" "${system}")"
    if [ -z "${tar}" ] || [ ! -e "${tar}" ]; then
        echo "ERROR: ${image} (${system}) 构建未产出镜像，跳过推送" >&2
        return 1
    fi
    skopeo copy \
        --format oci \
        "$(dest_tls)" \
        "docker-archive:${tar}" \
        "docker://${REGISTRY}/${name}:${tag}-${arch_name}"
}

function publish() {
    local selector="${1:?selector}"
    local system="${SYSTEM_AMD64}"
    local images
    images="$(images_or_die "${selector}" "${system}")"
    while IFS= read -r image; do
        echo "==> ${image}" >&2
        local name="${image%%:*}"
        local tag="${image#*:}"
        push "${image}" "${SYSTEM_AMD64}"
        push "${image}" "${SYSTEM_ARM64}"
        docker buildx imagetools create \
            --builder default \
            --annotation "index:org.opencontainers.image.source=${SOURCE_URL}" \
            --tag "${REGISTRY}/${name}:${tag}" \
            "${REGISTRY}/${name}:${tag}-${ARCH_AMD64}" \
            "${REGISTRY}/${name}:${tag}-${ARCH_ARM64}"
    done <<< "${images}"
}

case "${1:-}" in
list) list "${2:-}" ;;
build) build "${2:-}" "${3:-}" ;;
load) load "${2:-}" "${3:-}" ;;
publish) publish "${2:-}" ;;
*) help ;;
esac
