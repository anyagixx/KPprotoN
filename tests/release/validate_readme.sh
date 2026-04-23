#!/usr/bin/env bash

# FILE: tests/release/validate_readme.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that the root README stays aligned with deploy, TLS, and runtime operator guidance.
#   SCOPE: Static checks for project-value text, install flow, TLS modes, certificate reuse, and essential operator commands.
#   DEPENDS: README.md
#   LINKS: M-DOCS-README, V-M-DOCS-README
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required README statements exist
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for root README verification.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/README.md"

fail() {
  echo "[M-DOCS-README][readme][VERIFY] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${FILE}" || fail "missing pattern: ${pattern}"
}

## START_BLOCK_VALIDATE_README
[[ -f "${FILE}" ]] || fail "missing README.md"
require_pattern 'START_MODULE_CONTRACT'
require_pattern 'START_BLOCK_README_GUIDE'
require_pattern 'END_BLOCK_README_GUIDE'
require_pattern '^# KPprotoN'
require_pattern 'one-script deployment with `install\.sh`'
require_pattern 'TLS_MODE'
require_pattern 'issue-new'
require_pattern 'use-existing'
require_pattern 'export-existing-cert\.sh'
require_pattern 'import-existing-cert\.sh'
require_pattern 'self-signed certificate'
require_pattern 'publicly trusted wildcard certificate'
require_pattern 'docker compose logs --tail=200'
## END_BLOCK_VALIDATE_README

echo "[M-DOCS-README][readme][VERIFY] ok"
