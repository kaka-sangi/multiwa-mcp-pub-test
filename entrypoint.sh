#!/usr/bin/env bash
# Runtime entrypoint: prefetch spec if missing, then run mcp-proxy over
# awslabs.openapi-mcp-server (stdio) exposing SSE + Streamable HTTP.
set -euo pipefail

SPEC="${SPEC_CACHE_PATH:-/app/openapi.json}"
SPEC_URL="${MULTIWA_SPEC_URL:-https://multiwa-api.v244.net/api/docs-json}"

if [[ ! -f "${SPEC}" || ! -s "${SPEC}" ]]; then
    echo "[entrypoint] Spec not baked in; fetching from ${SPEC_URL}"
    if [[ -n "${MULTIWA_API_KEY:-}" ]]; then
        curl -fsS -H "x-api-key: ${MULTIWA_API_KEY}" -o "${SPEC}" "${SPEC_URL}" || {
            echo "[entrypoint] ERROR: could not fetch spec" >&2
            exit 1
        }
    else
        curl -fsS -o "${SPEC}" "${SPEC_URL}" || {
            echo "[entrypoint] ERROR: could not fetch spec" >&2
            exit 1
        }
    fi
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
HOST="${MCP_PROXY_HOST:-0.0.0.0}"
PORT="${MCP_PROXY_PORT:-8050}"

echo "[entrypoint] Starting awslabs.openapi-mcp-server (stdio) behind mcp-proxy on ${HOST}:${PORT}"

exec mcp-proxy \
    --host "${HOST}" \
    --port "${PORT}" \
    --pass-environment \
    --expose-header Mcp-Session-Id \
    --allow-origin "*" \
    -- \
    awslabs.openapi-mcp-server
