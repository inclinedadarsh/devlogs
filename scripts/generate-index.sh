#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

shopt -s nullglob
files=(content/*.md)

if [ ${#files[@]} -eq 0 ]; then
    echo "{}" > content/index.json
    exit 0
fi

awk '
BEGIN { printf "{\n"; first = 1 }

FNR == 1 {
    if (!first) {
        if (closed) printf "  },\n"
        else printf "\n  },\n"
    }
    first = 0
    fname = FILENAME; gsub(/.*\//, "", fname)
    printf "  \"%s\": {\n", fname
    in_fm = 1; ffirst = 1; closed = 0
    next
}

in_fm && /^---$/ {
    in_fm = 0; closed = 1; printf "\n"
    next
}

in_fm && /^[a-zA-Z_][a-zA-Z0-9_]*:/ {
    if (!ffirst) printf ",\n"
    ffirst = 0
    key = $1; sub(/:$/, "", key)
    value = substr($0, index($0, ":") + 2)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
    if (value ~ /^".*"$/) value = substr(value, 2, length(value) - 2)
    gsub(/\\/, "\\\\", value)
    gsub(/"/, "\\\"", value)
    printf "    \"%s\": \"%s\"", key, value
    next
}

END {
    if (!first) print "  }"
    print "}"
}
' "${files[@]}" > content/index.json
