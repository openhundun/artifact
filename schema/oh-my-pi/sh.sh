#!/usr/bin/env bash
set -euo pipefail

readonly ARG_JOB="${1:-}"
readonly ARG_STEP="${2:-}"
readonly GIT_REPOSITORY_DIR="$(cd "$(dirname "$(dirname "$(dirname "${0}")")")" && pwd)"
readonly PRODUCT_DIR="${GIT_REPOSITORY_DIR}/schema/oh-my-pi"
readonly PACKAGE_NAME="@oh-my-pi/pi-coding-agent"
readonly JSON_SCHEMA_TYPES_VERSION="9.0.0"
readonly PRETTIER_VERSION="3.9.10"
readonly PRETTIER_BIOME_VERSION="2.5.20261019043419"

function help() {
    echo "USAGE: ${0} <job__oh-my-pi> [step__generate | step__commit | step__push]"
}

function job__oh-my-pi() {
    function step__generate() {
        local version="${OMP_PI_VERSION:-$(curl -fsSL "https://registry.npmjs.org/@oh-my-pi%2Fpi-coding-agent" | jq -r '."dist-tags".latest')}"
        local tmp_dir="${GIT_REPOSITORY_DIR}/out/oh-my-pi"
        rm -rf "${tmp_dir}"
        mkdir -p "${tmp_dir}"
        echo '{"name":"oh-my-pi-schema","private":true}' > "${tmp_dir}/package.json"
        cat > "${tmp_dir}/gen-schema.ts" << "EOF"
import fs from "node:fs";
import { $schema, type JSONSchema } from "json-schema-typed/2020-12";
import "@oh-my-pi/pi-coding-agent/config/all-settings";
import { all, type SettingDefinition } from "@oh-my-pi/pi-coding-agent/config/registry";

type SchemaNode = JSONSchema.Interface<unknown>;
const settings = all();
const OUT = process.env.SCHEMA_OUT!;

function toLeaf(definition: SettingDefinition): SchemaNode {
    const node: SchemaNode = {};
    switch (definition.type) {
        case "enum":
            node.type = "string";
            node.enum = definition.values;
            break;
        case "boolean":
            node.type = "boolean";
            break;
        case "number":
            node.type = "number";
            break;
        case "array":
            node.type = "array";
            break;
        case "record":
            node.type = "object";
            break;
        default:
            node.type = "string";
    }
    if (definition.default !== undefined) {
        node.default = definition.default;
    }
    if (definition.ui?.description) {
        node.description = definition.ui.description;
    }
    if (definition.ui?.label) {
        node.title = definition.ui.label;
    }
    return node;
}

const root: SchemaNode = {
    $schema,
    additionalProperties: true,
    properties: {},
    type: "object",
};
for (const setting of settings) {
    const parts = setting.id.split(".");
    let current = root.properties as Record<string, SchemaNode>;
    for (let i = 0; i < parts.length - 1; i++) {
        const segment = parts[i];
        const existing = current[segment];
        if (existing?.properties) {
            current = existing.properties as Record<string, SchemaNode>;
            continue;
        }
        const created: SchemaNode = {
            additionalProperties: true,
            properties: {},
            type: "object",
        };
        current[segment] = created;
        current = created.properties as Record<string, SchemaNode>;
    }
    current[parts.at(-1)!] = toLeaf(setting.definition);
}

fs.writeFileSync(OUT, `${JSON.stringify(root, null, 2)}\n`);
EOF
        echo "=== ${PACKAGE_NAME}@${version} ==="
        (cd "${tmp_dir}" && bun add "${PACKAGE_NAME}@${version}" "json-schema-typed@${JSON_SCHEMA_TYPES_VERSION}" "prettier@${PRETTIER_VERSION}" "prettier-plugin-biome@${PRETTIER_BIOME_VERSION}")
        (cd "${tmp_dir}" && bunx "prettier@${PRETTIER_VERSION}" --no-config --plugin prettier-plugin-biome --write gen-schema.ts)
        (cd "${tmp_dir}" && SCHEMA_OUT="${PRODUCT_DIR}/config.schema.json" bun run gen-schema.ts)
        bunx "prettier@${PRETTIER_VERSION}" --no-config --print-width 1000 --write "${PRODUCT_DIR}/config.schema.json"
        rm -rf "${tmp_dir}"
    }

    function step__commit() {
        git -C "${GIT_REPOSITORY_DIR}" add schema/oh-my-pi/config.schema.json
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
job__oh-my-pi) job__oh-my-pi ;;
*) help ;;
esac
