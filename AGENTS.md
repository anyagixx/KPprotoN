# MyGRACE Working Agreement for KPprotoN

## Project Context
KPprotoN is a production-oriented Erlang/DevOps project that combines `mtproto_proxy` and `personal_mtproxy` into a single deployable system with email verification through Resend.

## Mandatory Navigation
1. Read `docs/graph-index.xml` first.
2. Open only the specific `docs/modules/M-XXX.xml`, `docs/plans/Phase-N.xml`, and `docs/verification/V-M-XXX.xml` files needed for the current task.
3. Do not create or rely on monolithic `knowledge-graph.xml`, `development-plan.xml`, or `verification-plan.xml`.

## Engineering Rules
1. Prefer `rtk`-prefixed shell commands.
2. Do not write governed source code before a module contract exists.
3. Keep `docs/graph-index.xml`, `docs/plan-index.xml`, and `docs/verification-index.xml` current when architecture changes.
4. Preserve OTP reliability properties, clear error handling, and deployment reproducibility.
5. For infrastructure work, favor idempotent scripts and explicit operator feedback.

## Initial Scope Anchors
- Unified Erlang release for proxy core and web portal
- Email magic-link issuance through Resend
- Dockerized deployment on Ubuntu VPS
- TLS/domain-fronting on port 443
- Persistent DETS storage and certificate mounts
