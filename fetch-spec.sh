#!/usr/bin/env bash
# Fetch the MultiWA OpenAPI spec at build time so the image is self-contained.
# Requires MULTIWA_SPEC_URL and (optional) MULTIWA_API_KEY build args.
set -euo pipefail

SPEC_URL="${MULTIWA_SPEC_URL:-https://multiwa-api.v244.net/api/docs-json}"
OUT="${SPEC_CACHE_PATH:-/app/openapi.json}"
API_BASE="${MULTIWA_API_URL:-https://multiwa-api.v244.net}"

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

# Validate JSON
python -c "import json,sys; json.load(open('${OUT}'))" || {
    echo "[fetch-spec] ERROR: spec is not valid JSON" >&2
    exit 1
}

API_BASE="${API_BASE%/}"
OUT="${OUT}" API_BASE="${API_BASE}" python -c "
import json, os
path = os.environ['OUT']
api_base = os.environ['API_BASE']
with open(path) as f:
    spec = json.load(f)
spec['servers'] = [{'url': api_base, 'description': 'MultiWA API'}]
with open(path, 'w') as f:
    json.dump(spec, f, indent=2)
    f.write('\n')
print(f'[fetch-spec] Set servers[0].url to {api_base}')
"

OPS=$(python -c "import json; d=json.load(open('${OUT}')); print(sum(1 for p in d.get('paths',{}).values() for m in p if m in ('get','post','put','delete','patch')))")
echo "[fetch-spec] Cached spec with ${OPS} operations at ${OUT}"