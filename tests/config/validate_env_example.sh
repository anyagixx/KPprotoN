#!/usr/bin/env bash

# FILE: tests/config/validate_env_example.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that deploy/.env.example contains the required shared configuration keys.
#   SCOPE: Presence checks for the canonical env contract used by foundation modules.
#   DEPENDS: deploy/.env.example
#   LINKS: M-CONFIG, V-M-CONFIG
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_key - asserts that an env key exists in deploy/.env.example
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added foundational env contract validation for shared config keys.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${ROOT_DIR}/deploy/.env.example"

fail() {
  echo "[M-CONFIG][validate][VALIDATE_REQUIRED] $*" >&2
  exit 1
}

# START_BLOCK_VALIDATE_FILE
[[ -f "${ENV_FILE}" ]] || fail "missing ${ENV_FILE}"
# END_BLOCK_VALIDATE_FILE

require_key() {
  local key="$1"
  if ! grep -Eq "^${key}=" "${ENV_FILE}"; then
    fail "missing key ${key}"
  fi
}

# START_BLOCK_VALIDATE_KEYS
while IFS= read -r key; do
  [[ -n "${key}" ]] || continue
  require_key "${key}"
done <<'EOF_KEYS'
BASE_DOMAIN
PORTAL_URL
PROXY_HOST
RESEND_API_KEY
RESEND_FROM
PROXY_SECRET_HEX
PROXY_PORT
PROXY_AD_TAG
PROXY_LISTEN_IP
PORTAL_DOMAIN_FRONTING
DOMAIN_FRONTING_TIMEOUT_SEC
CORE_API_HTTP_TIMEOUT_MS
MAX_CONNECTIONS_PER_DOMAIN
MTPROXY_BOOT_RETRY_SECONDS
TOKEN_TTL_SECONDS
TLS_CERT_PATH
TLS_KEY_PATH
TLS_WILDCARD_DOMAIN
TLS_CERTBOT_EMAIL
DETS_DATA_DIR
TOKEN_DATA_DIR
CERTS_HOST_DIR
DATA_HOST_DIR
APP_IMAGE
COMPOSE_PROJECT_NAME
RELEASE_NODE_NAME
RELEASE_COOKIE
ERLANG_DISTRIBUTION_PORT
PORTAL_HTTP_INTERNAL_PORT
EOF_KEYS
# END_BLOCK_VALIDATE_KEYS

echo "[M-CONFIG][validate][VALIDATE_REQUIRED] ok"
