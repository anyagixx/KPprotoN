#!/usr/bin/env bash

# FILE: tests/release/validate_dockerfile.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that the Dockerfile exposes the expected foundation image contract.
#   SCOPE: Presence checks for base image, entrypoint, copied env contract, and exposed ports.
#   DEPENDS: Dockerfile
#   LINKS: M-RELEASE, V-M-RELEASE
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts that a Dockerfile line matches the expected build contract
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added deterministic Dockerfile structure validation.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCKERFILE="${ROOT_DIR}/Dockerfile"

fail() {
  echo "[M-RELEASE][build][ASSEMBLE_RELEASE] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq "${pattern}" "${DOCKERFILE}" || fail "missing pattern: ${pattern}"
}

# START_BLOCK_VALIDATE_DOCKERFILE
[[ -f "${DOCKERFILE}" ]] || fail "missing Dockerfile"
require_pattern '^FROM erlang:'
require_pattern 'rebar3'
require_pattern '^COPY docker/entrypoint\.sh '
require_pattern '^EXPOSE 443 8080$'
require_pattern '^ENTRYPOINT \['
# END_BLOCK_VALIDATE_DOCKERFILE

echo "[M-RELEASE][build][ASSEMBLE_RELEASE] ok"
