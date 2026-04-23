# KPprotoN MTProto Edge Routing

## Shared 443 Contract
- External listener port is `443`.
- TLS files are read from `/certs/live/<BASE_DOMAIN>/fullchain.pem` and `/certs/live/<BASE_DOMAIN>/privkey.pem`.
- Standard HTTPS requests fall through to Cowboy on `127.0.0.1:8080`.
- Domain-fronted MTProto requests are matched by SNI and resolved through the policy store.

## Policy Reload Model
- New user SNI domains are added through `apply_domain_policy`.
- Policy reload must be observable and reversible.
- If policy update fails, issuance must not be reported as successful.

## Per-SNI Rollout
- `per_sni_secrets` is enabled for the public listener.
- Changing `PROXY_SECRET_HEX` or `PROXY_SECRET_SALT` invalidates all previously issued `tg://proxy` links.
- After access-hardening rollout or any later secret rotation, every user must request a fresh email or reopen `/verify` to receive a reissued link for the same SNI.
