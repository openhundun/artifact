#!/usr/bin/env bash
set -euo pipefail

readonly ARG_JOB="${1:-}"
readonly ARG_STEP="${2:-}"
readonly GIT_REPOSITORY_URL="https://github.com/openhundun/artifact"
readonly GIT_REPOSITORY_DIR="$(cd "$(dirname "$(dirname "${0}")")" && pwd)"
readonly IMAGE_REGISTRY="${IMAGE_REGISTRY:-ghcr.io}"
readonly IMAGE_REPOSITORY_OWNER="${IMAGE_REPOSITORY_OWNER:-openhundun}"
readonly IMAGE_PLATFORM="linux/amd64,linux/arm64"
readonly NIX_BIN="/nix/var/nix/profiles/default/bin"
readonly NIX_SYSTEM_ARCH_MAPPING_LIST=(
    "x86_64-linux:amd64"
    "aarch64-linux:arm64"
)
readonly ALPINE_DIR_LIST=(
    "alpine"
    "alpine-llvm"
    "alpine-llvm-zig"
    "alpine-llvm-zig-rust"
)
readonly DEBIAN_DIR_LIST=(
    "debian"
)
readonly UBUNTU_DIR_LIST=(
    "ubuntu"
    "ubuntu-bun"
    "ubuntu-go"
    "ubuntu-jdk"
    "ubuntu-jdk-maven"
    "ubuntu-llvm"
    "ubuntu-llvm-zig"
    "ubuntu-llvm-zig-rust"
    "ubuntu-python"
    "ubuntu-python-uv"
)

export PATH="${NIX_BIN}:${PATH}"

function help() {
    echo "USAGE: ${0} <job__nix [step__xxx | all] | job__alpine [step__xxx | all] | job__debian [step__xxx | all] | job__ubuntu [step__xxx | all]>"
}

function job__nix() {
    function step__build() {
        local image_raw="$(nix eval --raw --apply 'x: builtins.concatStringsSep "\n" (builtins.attrNames x)' "path:${GIT_REPOSITORY_DIR}/image/nix#packages.x86_64-linux")"
        local image_list=()
        mapfile -t image_list <<< "${image_raw}"
        for image in "${image_list[@]}"; do
            echo "=== ${IMAGE_REGISTRY}/${IMAGE_REPOSITORY_OWNER}/${image} ==="
            local ref_list=()
            for mapping in "${NIX_SYSTEM_ARCH_MAPPING_LIST[@]}"; do
                local system="${mapping%%:*}"
                local arch="${mapping#*:}"
                local archive="$(nix build --no-link --print-out-paths "path:${GIT_REPOSITORY_DIR}/image/nix#packages.${system}.\"${image}\"")"
                local ref="${IMAGE_REGISTRY}/${IMAGE_REPOSITORY_OWNER}/${image}-${arch}"
                skopeo copy --quiet --format oci --dest-tls-verify=false "docker-archive:${archive}" "docker://${ref}"
                ref_list+=("${ref}")
            done
            docker buildx imagetools create --annotation "index:org.opencontainers.image.source=${GIT_REPOSITORY_URL}" --tag "${IMAGE_REGISTRY}/${IMAGE_REPOSITORY_OWNER}/${image}" "${ref_list[@]}"
        done
    }

    function all() {
        step__build
    }

    case "${ARG_STEP}" in
    step__build) step__build ;;
    *) all ;;
    esac
}

function job__alpine() {
    function step__build() {
        for dir in "${ALPINE_DIR_LIST[@]}"; do
            for file in "${GIT_REPOSITORY_DIR}"/image/"${dir}"/*.dockerfile; do
                local image="$(basename "${file}" .dockerfile)"
                echo "=== ${IMAGE_REGISTRY}/${IMAGE_REPOSITORY_OWNER}/${image} ==="
                docker buildx build --file "${file}" --build-arg IMAGE_REGISTRY="${IMAGE_REGISTRY}" --tag "${IMAGE_REGISTRY}/${IMAGE_REPOSITORY_OWNER}/${image}" --platform "${IMAGE_PLATFORM}" --provenance false --sbom false --annotation "index:org.opencontainers.image.source=${GIT_REPOSITORY_URL}" --push "${GIT_REPOSITORY_DIR}"
            done
        done
    }

    function all() {
        step__build
    }

    case "${ARG_STEP}" in
    step__build) step__build ;;
    *) all ;;
    esac
}

function job__debian() {
    function step__build() {
        for dir in "${DEBIAN_DIR_LIST[@]}"; do
            for file in "${GIT_REPOSITORY_DIR}"/image/"${dir}"/*.dockerfile; do
                local image="$(basename "${file}" .dockerfile)"
                echo "=== ${IMAGE_REGISTRY}/${IMAGE_REPOSITORY_OWNER}/${image} ==="
                docker buildx build --file "${file}" --build-arg IMAGE_REGISTRY="${IMAGE_REGISTRY}" --tag "${IMAGE_REGISTRY}/${IMAGE_REPOSITORY_OWNER}/${image}" --platform "${IMAGE_PLATFORM}" --provenance false --sbom false --annotation "index:org.opencontainers.image.source=${GIT_REPOSITORY_URL}" --push "${GIT_REPOSITORY_DIR}"
            done
        done
    }

    function all() {
        step__build
    }

    case "${ARG_STEP}" in
    step__build) step__build ;;
    *) all ;;
    esac
}

function job__ubuntu() {
    function step__build() {
        for dir in "${UBUNTU_DIR_LIST[@]}"; do
            for file in "${GIT_REPOSITORY_DIR}"/image/"${dir}"/*.dockerfile; do
                local image="$(basename "${file}" .dockerfile)"
                echo "=== ${IMAGE_REGISTRY}/${IMAGE_REPOSITORY_OWNER}/${image} ==="
                docker buildx build --file "${file}" --build-arg IMAGE_REGISTRY="${IMAGE_REGISTRY}" --tag "${IMAGE_REGISTRY}/${IMAGE_REPOSITORY_OWNER}/${image}" --platform "${IMAGE_PLATFORM}" --provenance false --sbom false --annotation "index:org.opencontainers.image.source=${GIT_REPOSITORY_URL}" --push "${GIT_REPOSITORY_DIR}"
            done
        done
    }

    function all() {
        step__build
    }

    case "${ARG_STEP}" in
    step__build) step__build ;;
    *) all ;;
    esac
}

case "${ARG_JOB}" in
job__nix) job__nix ;;
job__alpine) job__alpine ;;
job__debian) job__debian ;;
job__ubuntu) job__ubuntu ;;
*) help ;;
esac
