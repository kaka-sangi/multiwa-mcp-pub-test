#!/usr/bin/env bash
set -euo pipefail

SPEC="${SPEC_CACHE_PATH:-/app/openapi.json}"
SPEC_URL="${MULTIWA_SPEC_URL:-https://multiwa-api.v244.net/api/docs-json}"

if [[ ! -f "${SPEC}" || ! -s "${SPEC}" ]]; then
    echo "[entrypoint] Spec not baked in; fetching from ${SPEC_URL}"
    AUTH_HDR=""
    if [[ -n "${MULTIWA_API_KEY:-}" ]]; then
        AUTH_HDR="-H x-api-key: ${MULTIWA_API_KEY}"
    fi
    curl -fsS ${AUTH_HDR} -o "${SPEC}" "${SPEC_URL}" || {
        echo "[entrypoint] ERROR: could not fetch spec" >&2
        exit 1
    }
fi

export API_SPEC_PATH="${SPEC}"
unset API_SPEC_URL

if [[ -n "${MULTIWA_API_KEY:-}" ]]; then
    export AUTH_TYPE="api_key"
    export AUTH_API_KEY="${MULTIWA_API_KEY}"
    export AUTH_API_KEY_NAME="x-api-key"
    export AUTH_API_KEY_IN="header"
fi

echo "[entrypoint] INCLUDE_TAGS=${INCLUDE_TAGS:-} EXCLUDE_TAGS=${EXCLUDE_TAGS:-}"
echo "[entrypoint] Starting awslabs.openapi-mcp-server (stdio) behind mcp-proxy on :${MCP_PROXY_PORT}"

exec mcp-proxy \
    --host "${MCP_PROXY_HOST}" \
    --port "${MCP_PROXY_PORT}" \
    --pass-environment \
    --expose-header Mcp-Session-Id \
    --allow-origin "*" \
    -- \
    awslabs.openapi-mcp-server
