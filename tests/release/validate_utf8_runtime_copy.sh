#!/usr/bin/env bash

# FILE: tests/release/validate_utf8_runtime_copy.sh
# VERSION: 1.1.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that compiled beams emit readable UTF-8 user-facing copy for the email and verify flows.
#   SCOPE: Compile the project, execute runtime functions, and assert readable Russian text in returned binaries and maps.
#   DEPENDS: rebar.config, apps/kpproton_portal/src/integrations/resend/kpproton_email_template.erl, apps/kpproton_portal/src/http/kpproton_request_handler.erl, apps/kpproton_portal/src/http/kpproton_verify_handler.erl
#   LINKS: M-RELEASE, M-EMAIL-TEMPLATE, M-WEB-API, V-M-RELEASE
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   fail - prints a release-level verification failure
#   run_runtime_probe - compiles the project and evaluates runtime text assertions
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.1.0 - Extended the runtime probe with rollout copy that warns users to trust only the freshest reissued link.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

fail() {
  echo "[M-RELEASE][boot][START_RUNTIME] $*" >&2
  exit 1
}

run_runtime_probe() {
  cd "${ROOT_DIR}"
  rebar3 compile >/dev/null
  erl -noshell -pa _build/default/lib/*/ebin \
    -eval '
      Template = kpproton_email_template:build_magic_link_email(
                   <<"example.com">>,
                   <<"https://example.com/verify?token=abc">>,
                   <<"user@example.com">>),
      SubjectExpected = unicode:characters_to_binary([1055,1086,1076,1090,1074,1077,1088,1076,1080,1090,1077,32,101,109,97,105,108]),
      TextExpected = unicode:characters_to_binary([1045,1089,1083,1080,32,1074,1099,32,1085,1077,32,1079,1072,1087,1088,1072,1096,1080,1074,1072,1083,1080,32,1087,1088,1086,1082,1089,1080]),
      ReissueEmailExpected = unicode:characters_to_binary([1089,1072,1084,1091,1102,32,1089,1074,1077,1078,1091,1102,32,1089,1089,1099,1083,1082,1091]),
      true = (binary:match(maps:get(subject, Template), SubjectExpected) =/= nomatch),
      true = (binary:match(maps:get(text, Template), TextExpected) =/= nomatch),
      true = (binary:match(maps:get(text, Template), ReissueEmailExpected) =/= nomatch),
      Accepted = kpproton_request_handler:handle_request(<<"user@example.com">>),
      true = (maps:get(message, Accepted) =:= unicode:characters_to_binary([1055,1088,1086,1074,1077,1088,1100,1090,1077,32,1087,1086,1095,1090,1091])),
      ErrorHtml = kpproton_verify_handler:render_verify_result(undefined),
      true = (binary:match(ErrorHtml, unicode:characters_to_binary([1057,1089,1099,1083,1082,1072,32,1085,1077,1076,1077,1081,1089,1090,1074,1080,1090,1077,1083,1100,1085,1072])) =/= nomatch),
      SuccessHtml = kpproton_verify_handler:render_verify_result(
                      #{email => <<"user@example.com">>,
                        tg_link => <<"tg://proxy?server=alice.example.com&port=443&secret=ee001122">>,
                        sni => <<"alice.example.com">>}),
      true = (binary:match(SuccessHtml, unicode:characters_to_binary([1055,1088,1086,1082,1089,1080,32,1075,1086,1090,1086,1074])) =/= nomatch),
      true = (binary:match(SuccessHtml, unicode:characters_to_binary([1057,1077,1088,1074,1077,1088])) =/= nomatch),
      true = (binary:match(SuccessHtml, unicode:characters_to_binary([1090,1086,1083,1100,1082,1086,32,1101,1090,1091,32,1089,1089,1099,1083,1082,1091])) =/= nomatch),
      halt(0).
    ' >/dev/null 2>&1
}

# START_BLOCK_RUNTIME_PROBE
run_runtime_probe || fail "compiled runtime output lost readable UTF-8 copy"
# END_BLOCK_RUNTIME_PROBE

echo "[M-RELEASE][boot][START_RUNTIME] utf8-runtime-ok"
