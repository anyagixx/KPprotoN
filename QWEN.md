# QWEN Workspace Notes for KPprotoN

## Read Order
1. `docs/graph-index.xml`
2. Needed module files in `docs/modules/`
3. Needed phase files in `docs/plans/`
4. Needed verification files in `docs/verification/`

## Project Summary
KPprotoN provisions personal MTProto proxies from a web portal. A user requests access with an email address, confirms ownership via a Resend-delivered magic link, and then receives a personal `tg://proxy` link backed by DETS state and SNI-based domain fronting.

## Working Constraints
- Use MyGRACE index-based navigation only.
- Keep changes production-oriented and operationally reproducible.
- Treat install automation, TLS issuance, email delivery, and proxy issuance as critical surfaces.
- Update documentation indexes when adding modules, phases, or verification contracts.
