#!/usr/bin/env bash
set -euo pipefail

readonly ARG_JOB="${1:-}"
readonly ARG_STEP="${2:-}"
readonly GIT_REPOSITORY_DIR="$(cd "$(dirname "$(dirname "${0}")")" && pwd)"
readonly CHART_REGISTRY="${CHART_REGISTRY:-ghcr.io}"
readonly CHART_REPOSITORY_OWNER="${CHART_REPOSITORY_OWNER:-openhundun}"

function help() {
    echo "USAGE: ${0} <job__check [step__xxx | all] | job__chart [step__xxx | all]>"
}

function job__check() {
    function step__lint() {
        for chart_yaml in "${GIT_REPOSITORY_DIR}"/chart/*/Chart.yaml; do
            local dir="$(basename "$(dirname "${chart_yaml}")")"
            echo "=== ${dir} ==="
            helm lint --strict "${GIT_REPOSITORY_DIR}/chart/${dir}"
            helm template "${dir}" "${GIT_REPOSITORY_DIR}/chart/${dir}" > /dev/null
        done
    }

    function all() {
        step__lint
    }

    case "${ARG_STEP}" in
    step__lint) step__lint ;;
    *) all ;;
    esac
}

function job__chart() {
    function step__package() {
        local chart_yaml_list=("${GIT_REPOSITORY_DIR}"/chart/*/Chart.yaml)
        local tmp_dir="${GIT_REPOSITORY_DIR}/out/chart"
        rm -rf "${tmp_dir}"
        mkdir -p "${tmp_dir}"
        for chart_yaml in "${chart_yaml_list[@]}"; do
            local dir="$(basename "$(dirname "${chart_yaml}")")"
            helm package "${GIT_REPOSITORY_DIR}/chart/${dir}" --destination "${tmp_dir}"
        done
    }

    function step__push() {
        for chart_yaml in "${GIT_REPOSITORY_DIR}"/chart/*/Chart.yaml; do
            local dir="$(basename "$(dirname "${chart_yaml}")")"
            local archive_list=("${GIT_REPOSITORY_DIR}/out/chart/${dir}"-*.tgz)
            echo "=== oci://${CHART_REGISTRY}/${CHART_REPOSITORY_OWNER}/charts ==="
            helm push "${archive_list[0]}" "oci://${CHART_REGISTRY}/${CHART_REPOSITORY_OWNER}/charts"
        done
        rm -rf "${GIT_REPOSITORY_DIR}/out/chart"
    }

    function all() {
        step__package
        step__push
    }

    case "${ARG_STEP}" in
    step__package) step__package ;;
    step__push) step__push ;;
    *) all ;;
    esac
}

case "${ARG_JOB}" in
job__check) job__check ;;
job__chart) job__chart ;;
*) help ;;
esac
