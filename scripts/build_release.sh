#!/usr/bin/env bash

# FILE: scripts/build_release.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Build the relx release from an ASCII-only staging path to avoid local rebar/relx path-format failures.
#   SCOPE: Stage project files into /tmp, run `rebar3 as prod release`, and sync the resulting `_build/prod/rel/kpproton` back.
#   DEPENDS: rebar.config, config/, src/, apps/
#   LINKS: M-RELEASE, V-M-RELEASE
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   stage_workspace - copies the project into an ASCII-only temp directory
#   sync_release_back - copies the built release back into the source workspace
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added ASCII staging wrapper for local relx release assembly.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGE_DIR="/tmp/kpproton_release_ascii"
TARGET_REL_DIR="${ROOT_DIR}/_build/prod/rel/kpproton"

log_line() {
  local block="$1"
  shift
  echo "[M-RELEASE][build][${block}] $*"
}

stage_workspace() {
  rm -rf "${STAGE_DIR}"
  mkdir -p "${STAGE_DIR}"
  tar \
    --exclude='./_build' \
    --exclude='./deps' \
    --exclude='./.git' \
    -cf - \
    -C "${ROOT_DIR}" . | tar -xf - -C "${STAGE_DIR}"
}

sync_release_back() {
  rm -rf "${TARGET_REL_DIR}"
  mkdir -p "$(dirname "${TARGET_REL_DIR}")"
  cp -a "${STAGE_DIR}/_build/prod/rel/kpproton" "${TARGET_REL_DIR}"
}

log_line "FETCH_DEPS" "staging workspace into ASCII-only path ${STAGE_DIR}"
stage_workspace

log_line "ASSEMBLE_RELEASE" "running relx release in staged workspace"
(
  cd "${STAGE_DIR}"
  rebar3 as prod release
)

log_line "ASSEMBLE_RELEASE" "syncing built release back into source workspace"
sync_release_back
