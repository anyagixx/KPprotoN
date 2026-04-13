# KPprotoN Certificate Bootstrap

REG.RU DNS-01 automation is the preferred wildcard strategy for KPprotoN when API credentials are available.

## Why
- `*.example.com` cannot be issued through plain HTTP-01.
- `install.sh` still prompts only for `BASE_DOMAIN` and `RESEND_API_KEY`, so REG.RU credentials are consumed from pre-exported shell env instead of new prompts.

## Automated REG.RU Flow
1. Export `REGRU_API_USERNAME` and `REGRU_API_PASSWORD` before running `install.sh`.
2. The installer persists them into `/etc/kpproton/reg.ru.credentials` with `0600` permissions.
3. `ops/certs/provision-certs.sh` detects the credential file and runs Certbot with `reg_ru_dns_auth.sh` and `reg_ru_dns_cleanup.sh`.
4. Certbot requests the apex and wildcard certificate and writes them into `/etc/letsencrypt/live/<BASE_DOMAIN>/`.
5. Docker bind-mounts that tree into `/certs`.

## Manual Fallback
1. Run `install.sh`.
2. If REG.RU credentials are not available, the installer calls `ops/certs/provision-certs.sh` in guided manual DNS-01 mode.
3. The installer prints the exact TXT record name and value for `_acme-challenge.<BASE_DOMAIN>`.
4. You add the TXT record in your DNS panel, verify propagation yourself, and press `Enter`.
5. The hook checks that the TXT value is publicly visible via `dig`.
6. Only after the TXT is visible does Certbot continue and issue the apex + wildcard certificate into `/etc/letsencrypt/live/<BASE_DOMAIN>/`.

## Mount Contract
- Host source: `/etc/letsencrypt`
- Container target: `/certs`
- Runtime cert path: `/certs/live/<BASE_DOMAIN>/fullchain.pem`
- Runtime key path: `/certs/live/<BASE_DOMAIN>/privkey.pem`
