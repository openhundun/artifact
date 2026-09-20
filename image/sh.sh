#!/usr/bin/env bash
set -euo pipefail

readonly IMAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_DIR="$(dirname "${IMAGE_DIR}")"
readonly REGISTRY="${IMAGE_REGISTRY:-ghcr.io/openhundun}"
readonly BUILDER="${BUILDX_BUILDER:-multiarch}"
readonly PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
readonly SOURCE_URL="https://github.com/openhundun/artifact"

function docker_cmd() {
    if docker info > /dev/null 2>&1; then
        echo "docker"
        return 0
    fi
    echo "sudo -n docker"
}

function help() {
    echo "usage: ${0} {list|build|publish} [selector]"
    echo "       ${0} -h | --help"
    echo
    echo "selector 缺省 all："
    echo "  all             全部 dockerfile 家族"
    echo "  <分组>          家族名前缀，如 debian 覆盖 debian / debian-jdk / debian-jdk-maven …"
    echo "  <家族>          单个家族，如 ubuntu-llvm-zig"
    echo "  <家族>:<tag>    单个镜像，如 ubuntu-llvm-zig:24-21-0.16"
    echo
    echo "registry 由 IMAGE_REGISTRY 覆盖，当前 ${REGISTRY}"
    echo "builder  由 BUILDX_BUILDER 覆盖，当前 ${BUILDER}"
    echo "platform 由 PLATFORMS 覆盖，当前 ${PLATFORMS}"
}

function images() {
    local family_dir file
    for family_dir in "${IMAGE_DIR}"/*/; do
        for file in "${family_dir}"*.dockerfile; do
            [ -e "${file}" ] || continue
            file="$(basename "${file}")"
            echo "${file%.dockerfile}"
        done
    done
}

function family_of() {
    echo "${1%%:*}"
}

function group_of() {
    local family
    family="$(family_of "${1:?image}")"
    echo "${family%%-*}"
}

function family_images() {
    local family="${1:?family}"
    local file
    local found=0
    if [ ! -d "${IMAGE_DIR}/${family}" ]; then
        echo "ERROR: 没有家族 ${family}" >&2
        return 1
    fi
    for file in "${IMAGE_DIR}/${family}/"*.dockerfile; do
        [ -e "${file}" ] || continue
        found=1
        file="$(basename "${file}")"
        echo "${file%.dockerfile}"
    done
    if [ "${found}" = "0" ]; then
        echo "ERROR: 家族 ${family} 下没有 dockerfile" >&2
        return 1
    fi
}

function is_group() {
    local want="${1:?group}"
    local image
    while IFS= read -r image; do
        if [ "$(group_of "${image}")" = "${want}" ]; then
            return 0
        fi
    done <<< "$(images)"
    return 1
}

function select_images() {
    local selector="${1:-all}"
    local image
    case "${selector}" in
    all)
        images
        ;;
    *:*)
        echo "${selector}"
        ;;
    *)
        if is_group "${selector}"; then
            while IFS= read -r image; do
                if [ "$(group_of "${image}")" = "${selector}" ]; then
                    echo "${image}"
                fi
            done <<< "$(images)"
        else
            family_images "${selector}"
        fi
        ;;
    esac
}

function build_one() {
    local image="${1:?image}"
    local mode="${2:?mode}"
    local args=(
        --builder "${BUILDER}"
        --file "${IMAGE_DIR}/$(family_of "${image}")/${image}.dockerfile"
        --platform "${PLATFORMS}"
        --provenance=false
        --sbom=false
    )
    if [ "${mode}" = "publish" ]; then
        args+=(
            --annotation "index:org.opencontainers.image.source=${SOURCE_URL}"
            --tag "${REGISTRY}/${image}"
            --push
        )
    else
        args+=(--output type=cacheonly)
    fi
    echo "==> ${image} (${mode})" >&2
    $(docker_cmd) buildx build "${args[@]}" "${REPO_DIR}"
}

function build() {
    local selector="${1:-all}"
    local mode="${2:?mode}"
    local selected
    selected="$(select_images "${selector}")"
    if [ -z "${selected}" ]; then
        echo "ERROR: 选择器 ${selector} 没有匹配到任何镜像" >&2
        return 1
    fi
    while IFS= read -r image; do
        build_one "${image}" "${mode}"
    done <<< "${selected}"
}

case "${1:-}" in
list) select_images "${2:-all}" ;;
build) build "${2:-all}" build ;;
publish) build "${2:-all}" publish ;;
*) help ;;
esac
