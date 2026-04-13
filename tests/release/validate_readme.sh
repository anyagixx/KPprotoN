#!/usr/bin/env bash
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

[[ -f "${FILE}" ]] || fail "missing README.md"
require_pattern '^# KPprotoN'
require_pattern 'one-script deployment with `install\.sh`'
require_pattern 'TLS_MODE'
require_pattern 'issue-new'
require_pattern 'use-existing'
require_pattern 'export-existing-cert\.sh'
require_pattern 'import-existing-cert\.sh'
require_pattern 'docker compose logs --tail=200'

echo "[M-DOCS-README][readme][VERIFY] ok"
