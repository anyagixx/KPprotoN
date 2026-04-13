#!/usr/bin/env bash

# FILE: ops/certs/import-existing-cert.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Import a portable certificate archive into the runtime TLS layout expected by KPprotoN.
#   SCOPE: Unpack `fullchain.pem` and `privkey.pem`, validate them, and install them into `/etc/letsencrypt/live/<BASE_DOMAIN>/`.
#   DEPENDS: export-existing-cert.sh output, openssl
#   LINKS: M-CERTS, M-INSTALL
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   fail - exits with a structured import error
#   run_privileged - executes privileged filesystem writes
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added certificate archive import helper for preparing `TLS_MODE=use-existing` inputs.
# END_CHANGE_SUMMARY

set -euo pipefail

ARCHIVE_PATH="${1:-}"
BASE_DOMAIN="${2:-}"
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

run_privileged() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

cleanup() {
  [[ -n "${WORK_DIR}" && -d "${WORK_DIR}" ]] && rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

[[ -n "${ARCHIVE_PATH}" && -n "${BASE_DOMAIN}" ]] || fail "usage: import-existing-cert.sh <archive-path> <base-domain>"
[[ -f "${ARCHIVE_PATH}" ]] || fail "archive not found: ${ARCHIVE_PATH}"

WORK_DIR="$(mktemp -d)"
tar -C "${WORK_DIR}" -xzf "${ARCHIVE_PATH}"

[[ -f "${WORK_DIR}/fullchain.pem" ]] || fail "archive does not contain fullchain.pem"
[[ -f "${WORK_DIR}/privkey.pem" ]] || fail "archive does not contain privkey.pem"

openssl x509 -in "${WORK_DIR}/fullchain.pem" -noout >/dev/null 2>&1 || fail "invalid X.509 certificate in archive"
openssl pkey -in "${WORK_DIR}/privkey.pem" -noout >/dev/null 2>&1 || fail "invalid private key in archive"

if ! openssl x509 -in "${WORK_DIR}/fullchain.pem" -noout -text | grep -Eq "DNS:${BASE_DOMAIN}|DNS:\\*\\.${BASE_DOMAIN}"; then
  fail "archive certificate does not contain ${BASE_DOMAIN} or *.${BASE_DOMAIN} in SAN"
fi

DEST_DIR="/etc/letsencrypt/live/${BASE_DOMAIN}"
run_privileged install -d -m 755 "${DEST_DIR}"
run_privileged install -m 644 "${WORK_DIR}/fullchain.pem" "${DEST_DIR}/fullchain.pem"
run_privileged install -m 600 "${WORK_DIR}/privkey.pem" "${DEST_DIR}/privkey.pem"
log_line "PERSIST_PATHS" "certificate archive imported into ${DEST_DIR}"
