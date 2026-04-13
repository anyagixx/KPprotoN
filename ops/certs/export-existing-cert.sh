#!/usr/bin/env bash

# FILE: ops/certs/export-existing-cert.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Export an already issued certificate pair into a portable archive for reuse on another VPS.
#   SCOPE: Read `fullchain.pem` and `privkey.pem` from the Let’s Encrypt live path, add a small manifest, and pack them into a tar.gz bundle.
#   DEPENDS: /etc/letsencrypt/live/<BASE_DOMAIN>/
#   LINKS: M-CERTS
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   fail - exits with a structured export error
#   write_manifest - writes basic metadata alongside exported certificate files
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added portable certificate export helper for reuse across test VPS deployments.
# END_CHANGE_SUMMARY

set -euo pipefail

BASE_DOMAIN="${1:-}"
OUTPUT_ARCHIVE="${2:-}"
SOURCE_DIR=""
WORK_DIR=""

log_line() {
  local block="$1"
  shift
  printf '[M-CERTS][bootstrap][%s] %s\n' "${block}" "$*"
}

fail() {
  log_line "ERROR" "$*"
  exit 1
}

cleanup() {
  [[ -n "${WORK_DIR}" && -d "${WORK_DIR}" ]] && rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

write_manifest() {
  local manifest_path="$1"
  cat >"${manifest_path}" <<EOF
BASE_DOMAIN=${BASE_DOMAIN}
EXPORTED_AT_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
}

[[ -n "${BASE_DOMAIN}" ]] || fail "usage: export-existing-cert.sh <base-domain> [output-archive]"
SOURCE_DIR="/etc/letsencrypt/live/${BASE_DOMAIN}"
[[ -d "${SOURCE_DIR}" ]] || fail "certificate directory not found: ${SOURCE_DIR}"
[[ -f "${SOURCE_DIR}/fullchain.pem" ]] || fail "missing fullchain.pem in ${SOURCE_DIR}"
[[ -f "${SOURCE_DIR}/privkey.pem" ]] || fail "missing privkey.pem in ${SOURCE_DIR}"

if [[ -z "${OUTPUT_ARCHIVE}" ]]; then
  OUTPUT_ARCHIVE="${PWD}/${BASE_DOMAIN}-cert-export.tar.gz"
fi

WORK_DIR="$(mktemp -d)"
cp "${SOURCE_DIR}/fullchain.pem" "${WORK_DIR}/fullchain.pem"
cp "${SOURCE_DIR}/privkey.pem" "${WORK_DIR}/privkey.pem"
write_manifest "${WORK_DIR}/manifest.env"

tar -C "${WORK_DIR}" -czf "${OUTPUT_ARCHIVE}" fullchain.pem privkey.pem manifest.env
log_line "PERSIST_PATHS" "certificate export archive created at ${OUTPUT_ARCHIVE}"
