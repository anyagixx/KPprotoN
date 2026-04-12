#!/usr/bin/env bash

# FILE: ops/certs/reg_ru_dns_cleanup.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Remove REG.RU TXT records created for Let's Encrypt DNS-01 validation.
#   SCOPE: Read root-owned REG.RU credentials, derive the challenge subdomain, and call REG.API 2 zone/remove_record for the exact TXT value.
#   DEPENDS: ops/certs/provision-certs.sh
#   LINKS: M-CERTS, V-M-CERTS
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   compute_subdomain - maps CERTBOT_DOMAIN onto a REG.RU subdomain string
#   reg_api_call - invokes REG.API 2 with JSON input_data
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added REG.RU DNS-01 cleanup hook for automated wildcard certificate issuance.
# END_CHANGE_SUMMARY

set -euo pipefail

CREDENTIALS_FILE="${REGRU_CREDENTIALS_FILE:-/etc/kpproton/reg.ru.credentials}"
BASE_DOMAIN="${BASE_DOMAIN:-}"

fail() {
  printf '[M-CERTS][renew][RENEW_CERT] %s\n' "$*" >&2
  exit 1
}

load_credentials() {
  [[ -f "${CREDENTIALS_FILE}" ]] || fail "missing REG.RU credentials file ${CREDENTIALS_FILE}"
  # shellcheck disable=SC1090
  source "${CREDENTIALS_FILE}"
  [[ -n "${REGRU_API_USERNAME:-}" ]] || fail "REGRU_API_USERNAME missing"
  [[ -n "${REGRU_API_PASSWORD:-}" ]] || fail "REGRU_API_PASSWORD missing"
  [[ -n "${BASE_DOMAIN}" ]] || fail "BASE_DOMAIN missing"
}

compute_subdomain() {
  python3 - <<'PY' "${CERTBOT_DOMAIN}" "${BASE_DOMAIN}"
import sys

certbot_domain = sys.argv[1]
base_domain = sys.argv[2]
normalized = certbot_domain[2:] if certbot_domain.startswith("*.") else certbot_domain
if normalized == base_domain:
    print("_acme-challenge")
elif normalized.endswith("." + base_domain):
    relative = normalized[:-(len(base_domain) + 1)]
    print(f"_acme-challenge.{relative}")
else:
    raise SystemExit("certbot domain does not belong to base domain")
PY
}

reg_api_call() {
  local subdomain="$1"
  local text="$2"
  python3 - <<'PY' "${subdomain}" "${text}" "${REGRU_API_USERNAME}" "${REGRU_API_PASSWORD}" "${BASE_DOMAIN}"
import json
import subprocess
import sys

subdomain, text, username, password, base_domain = sys.argv[1:]
payload = json.dumps({
    "username": username,
    "password": password,
    "domains": [{"dname": base_domain}],
    "subdomain": subdomain,
    "record_type": "TXT",
    "content": text
}, separators=(",", ":"))
cmd = [
    "curl", "-fsS", "https://api.reg.ru/api/regru2/zone/remove_record",
    "--data-urlencode", "input_format=json",
    "--data-urlencode", "input_data=" + payload
]
result = subprocess.run(cmd, capture_output=True, text=True, check=True)
data = json.loads(result.stdout)
if data.get("result") != "success":
    raise SystemExit(result.stdout)
domains = data.get("answer", {}).get("domains", [])
if not domains or domains[0].get("result") != "success":
    raise SystemExit(result.stdout)
PY
}

load_credentials
subdomain="$(compute_subdomain)"
reg_api_call "${subdomain}" "${CERTBOT_VALIDATION}"
