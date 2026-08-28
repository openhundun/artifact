set -euo pipefail

help() {
    echo "USAGE: ${0} <help | fmt>"
}

fmt() {
    local t="${1:-}"
    local files=()
    if [[ -f "${t}" ]]; then
        files=("${t}")
    elif [[ -d "${t}" ]]; then
        while IFS= read -r f; do files+=("${f}"); done <<< "$(fd -H -t f . "${t}" 2> /dev/null)"
    fi
    for f in "${files[@]}"; do
        case "${f}" in
        *.py)
            uvx ruff check --select I --fix "${f}"
            uvx ruff format "${f}"
            ;;
        *.cjs | *.cts | *.js | *.jsx | *.mjs | *.mts | *.ts | *.tsx)
            bunx @biomejs/biome format --write "${f}"
            ;;
        *.java | *.json | *.md | *.sh | *.yaml)
            bunx prettier --write "${f}"
            ;;
        esac
    done
}

case "${1:-}" in
fmt) fmt "${2:-}" ;;
*) help ;;
esac
