#!/usr/bin/env bash
set -euo pipefail

readonly IMAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_DIR="$(dirname "${IMAGE_DIR}")"
readonly REGISTRY="${IMAGE_REGISTRY:-ghcr.io/openhundun}"
readonly BUILDER="${BUILDX_BUILDER:-multiarch}"
readonly PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"

function docker_cmd() {
    if docker info > /dev/null 2>&1; then
        echo "docker"
        return 0
    fi
    echo "sudo -n docker"
}

function help() {
    echo "usage: ${0} {list|build|publish} <image|all>"
    echo "       ${0} -h | --help"
    echo
    echo "image   形如 ubuntu-llvm-zig，all 表示全部镜像"
    echo "registry 由 IMAGE_REGISTRY 覆盖，当前 ${REGISTRY}"
    echo "builder  由 BUILDX_BUILDER 覆盖，当前 ${BUILDER}"
    echo "platform 由 PLATFORMS 覆盖，当前 ${PLATFORMS}"
}

function list_family() {
    local family="${1:?family}"
    local file
    if [ ! -d "${family}" ]; then
        echo "ERROR: 未找到镜像 ${family#"${IMAGE_DIR}"/}" >&2
        return 1
    fi
    for file in "${family}"*.dockerfile; do
        [ -e "${file}" ] || continue
        file="$(basename "${file}")"
        echo "${file%.dockerfile}"
    done
}

function list() {
    local family
    for family in "${IMAGE_DIR}"/*/; do
        list_family "${family}"
    done
}

function each_image() {
    local selector="${1:?selector}"
    case "${selector}" in
    all) list ;;
    *:*) echo "${selector}" ;;
    *) list_family "${IMAGE_DIR}/${selector}/" ;;
    esac
}

function build_one() {
    local image="${1:?image}"
    local mode="${2:?mode}"
    local name="${image%%:*}"
    local file="${IMAGE_DIR}/${name}/${image}.dockerfile"
    local args=(
        --builder "${BUILDER}"
        --file "${file}"
        --platform "${PLATFORMS}"
        --provenance=false
        --sbom=false
    )
    if [ ! -f "${file}" ]; then
        echo "ERROR: dockerfile 不存在 ${file}" >&2
        return 1
    fi
    if [ "${mode}" = "publish" ]; then
        args+=(--tag "${REGISTRY}/${image}" --push)
    else
        args+=(--output type=cacheonly)
    fi
    echo "==> ${image} (${mode})" >&2
    $(docker_cmd) buildx build "${args[@]}" "${REPO_DIR}"
}

function build() {
    local selector="${1:?selector}"
    local mode="${2:?mode}"
    local images
    images="$(each_image "${selector}")"
    if [ -z "${images}" ]; then
        echo "ERROR: 选择器 ${selector} 没有匹配到任何镜像" >&2
        return 1
    fi
    while IFS= read -r image; do
        build_one "${image}" "${mode}"
    done <<< "${images}"
}

case "${1:-}" in
list) list ;;
build) build "${2:-}" build ;;
publish) build "${2:-}" publish ;;
*) help ;;
esac
