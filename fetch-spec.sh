#!/usr/bin/env bash
# Fetch the MultiWA OpenAPI spec at build time so the image is self-contained.
set -euo pipefail

SPEC_URL="${MULTIWA_SPEC_URL:-https://multiwa-api.v244.net/api/docs-json}"
OUT="${SPEC_CACHE_PATH:-/app/openapi.json}"

echo "[fetch-spec] Fetching OpenAPI spec from ${SPEC_URL}"
if [[ -n "${MULTIWA_API_KEY:-}" ]]; then
    curl -fsS -H "x-api-key: ${MULTIWA_API_KEY}" -o "${OUT}" "${SPEC_URL}"
else
    curl -fsS -o "${OUT}" "${SPEC_URL}"
fi

if [[ ! -s "${OUT}" ]]; then
    echo "[fetch-spec] ERROR: spec is empty" >&2
    exit 1
fi

python -c "import json,sys; json.load(open('${OUT}'))" || {
    echo "[fetch-spec] ERROR: spec is not valid JSON" >&2
    exit 1
}

OPS=$(python -c "import json; d=json.load(open('${OUT}')); print(sum(1 for p in d.get('paths',{}).values() for m in p if m in ('get','post','put','delete','patch')))")
echo "[fetch-spec] Cached spec with ${OPS} operations at ${OUT}"
