#!/usr/bin/env bash

# FILE: tests/install/validate_install_syntax.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Provide deterministic syntax verification for install.sh.
#   SCOPE: Bash parser validation for the installer entry point.
#   DEPENDS: install.sh
#   LINKS: M-INSTALL, V-M-INSTALL
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   none - delegates to bash parser
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added installer syntax validation.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INSTALL_FILE="${ROOT_DIR}/install.sh"

bash -n "${INSTALL_FILE}"
echo "[M-INSTALL][run][VALIDATE_INPUT] syntax-ok"
