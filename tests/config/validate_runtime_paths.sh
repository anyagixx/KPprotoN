#!/usr/bin/env bash

# FILE: tests/config/validate_runtime_paths.sh
# VERSION: 1.1.0
# START_MODULE_CONTRACT
#   PURPOSE: Check that shared runtime path and URL-related env values remain aligned in deploy/.env.example.
#   SCOPE: Basic format checks for portal URL, cert paths, storage path prefixes, and per-SNI secret salt safety.
#   DEPENDS: deploy/.env.example
#   LINKS: M-CONFIG, V-M-CONFIG
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   read_value - extracts a key from deploy/.env.example
#   assert_prefix - validates a value starts with the expected prefix
#   assert_regex - validates a value matches the expected pattern
#   assert_distinct - validates that two values are not identical
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.1.0 - Added distinct per-SNI salt validation for the canonical runtime env.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${ROOT_DIR}/deploy/.env.example"

fail() {
  echo "[M-CONFIG][render][EMIT_RUNTIME] $*" >&2
  exit 1
}

read_value() {
  local key="$1"
  grep -E "^${key}=" "${ENV_FILE}" | head -n1 | cut -d'=' -f2-
}

assert_prefix() {
  local value="$1"
  local prefix="$2"
  local label="$3"
  [[ "${value}" == "${prefix}"* ]] || fail "${label} must start with ${prefix}"
}

assert_regex() {
  local value="$1"
  local pattern="$2"
  local label="$3"
  [[ "${value}" =~ ${pattern} ]] || fail "${label} has invalid format"
}

assert_distinct() {
  local left="$1"
  local right="$2"
  local label="$3"
  [[ "${left}" != "${right}" ]] || fail "${label} must not match PROXY_SECRET_HEX"
}

# START_BLOCK_VALIDATE_RUNTIME_VALUES
portal_url="$(read_value PORTAL_URL)"
proxy_secret_hex="$(read_value PROXY_SECRET_HEX)"
proxy_secret_salt="$(read_value PROXY_SECRET_SALT)"
tls_cert_path="$(read_value TLS_CERT_PATH)"
tls_key_path="$(read_value TLS_KEY_PATH)"
dets_dir="$(read_value DETS_DATA_DIR)"
token_dir="$(read_value TOKEN_DATA_DIR)"

assert_prefix "${portal_url}" "https://" "PORTAL_URL"
assert_regex "${proxy_secret_hex}" '^[0-9a-f]{32}$' "PROXY_SECRET_HEX"
assert_regex "${proxy_secret_salt}" '^[0-9a-f]{32}$' "PROXY_SECRET_SALT"
assert_distinct "${proxy_secret_salt}" "${proxy_secret_hex}" "PROXY_SECRET_SALT"
assert_prefix "${tls_cert_path}" "/certs/" "TLS_CERT_PATH"
assert_prefix "${tls_key_path}" "/certs/" "TLS_KEY_PATH"
assert_prefix "${dets_dir}" "/" "DETS_DATA_DIR"
assert_prefix "${token_dir}" "/" "TOKEN_DATA_DIR"
# END_BLOCK_VALIDATE_RUNTIME_VALUES

echo "[M-CONFIG][render][EMIT_RUNTIME] ok"
