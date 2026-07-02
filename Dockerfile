# MultiWA MCP — OpenAPI-to-MCP bridge
FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    NODE_ENV=production

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --upgrade pip \
    && pip install "awslabs.openapi-mcp-server[yaml]==1.1.0"

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g mcp-proxy

WORKDIR /app
COPY entrypoint.sh /app/entrypoint.sh
COPY fetch-spec.sh /app/fetch-spec.sh
RUN chmod +x /app/entrypoint.sh /app/fetch-spec.sh

ENV API_NAME="multiwa" \
    AUTH_TYPE="api_key" \
    AUTH_API_KEY_NAME="x-api-key" \
    AUTH_API_KEY_IN="header" \
    INCLUDE_TAGS="Profiles,Messages,Contacts,Conversations,Groups,Webhooks,Health" \
    EXCLUDE_TAGS="" \
    VALIDATE_OUTPUT="false" \
    LOG_LEVEL="INFO" \
    ENABLE_OPERATION_PROMPTS="true" \
    MCP_PROXY_HOST="0.0.0.0" \
    MCP_PROXY_PORT="8050" \
    SPEC_CACHE_PATH="/app/openapi.json"

EXPOSE 8050

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -fsS http://127.0.0.1:8050/ || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
