#!/usr/bin/env bash
set -euo pipefail

readonly ARG_JOB="${1:-}"
readonly ARG_STEP="${2:-}"
readonly GIT_REPOSITORY_DIR="$(cd "$(dirname "$(dirname "$(dirname "${0}")")")" && pwd)"
readonly PRODUCT_DIR="${GIT_REPOSITORY_DIR}/json/oh-my-pi"
readonly PACKAGE_NAME="@oh-my-pi/pi-catalog"
readonly PRETTIER_VERSION="3.9.10"
readonly PRETTIER_BIOME_VERSION="2.5.20261019043419"

function help() {
    echo "USAGE: ${0} <job__omp> [step__generate | step__commit | step__push]"
}

function job__omp() {
    function step__generate() {
        local version="${OMP_CATALOG_VERSION:-$(curl -fsSL "https://registry.npmjs.org/@oh-my-pi%2Fpi-catalog" | jq -r '."dist-tags".latest')}"
        local tmp_dir="${GIT_REPOSITORY_DIR}/out/omp"
        rm -rf "${tmp_dir}"
        mkdir -p "${tmp_dir}"
        echo '{"name":"omp-models-catalog","private":true}' > "${tmp_dir}/package.json"
        cat > "${tmp_dir}/dump-catalog.ts" << "EOF"
import fs from "node:fs";
import { getBundledModels, getBundledProviders } from "@oh-my-pi/pi-catalog/models";

const out: Record<string, unknown> = {};
for (const provider of getBundledProviders()) {
    const models = getBundledModels(provider);
    if (models.length === 0) {
        continue;
    }
    out[provider] = Object.fromEntries(models.map(model => [model.id, model]));
}
fs.writeFileSync(process.env.CATALOG_OUT!, JSON.stringify(out));
EOF
        echo "=== ${PACKAGE_NAME}@${version} ==="
        (cd "${tmp_dir}" && bun add "${PACKAGE_NAME}@${version}" "prettier@${PRETTIER_VERSION}" "prettier-plugin-biome@${PRETTIER_BIOME_VERSION}")
        (cd "${tmp_dir}" && bunx "prettier@${PRETTIER_VERSION}" --no-config --plugin prettier-plugin-biome --write dump-catalog.ts)
        (cd "${tmp_dir}" && CATALOG_OUT="${PRODUCT_DIR}/models.json" bun run dump-catalog.ts)
        rm -rf "${tmp_dir}"
    }

    function step__commit() {
        git -C "${GIT_REPOSITORY_DIR}" add json/oh-my-pi/models.json
        git -C "${GIT_REPOSITORY_DIR}" diff --cached --quiet || git -C "${GIT_REPOSITORY_DIR}" -c user.name=openhundun-admin -c user.email=openhundun-admin@outlook.com commit -m 1
    }

    function step__push() {
        git -C "${GIT_REPOSITORY_DIR}" push
    }

    function all() {
        step__generate
        step__commit
        step__push
    }

    case "${ARG_STEP}" in
    step__generate) step__generate ;;
    step__commit) step__commit ;;
    step__push) step__push ;;
    *) all ;;
    esac
}

case "${ARG_JOB}" in
job__omp) job__omp ;;
*) help ;;
esac
