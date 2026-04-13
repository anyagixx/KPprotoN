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

## Reusing an Existing Certificate
`install.sh` also supports a reuse path for already issued certificates.

1. Start `install.sh`.
2. Choose `TLS_MODE=use-existing`.
3. Provide paths to:
   - `EXISTING_CERT_FULLCHAIN_PATH`
   - `EXISTING_CERT_PRIVKEY_PATH`
4. The installer validates the certificate/key pair and copies them into `/etc/letsencrypt/live/<BASE_DOMAIN>/`.
5. The Docker runtime then uses the imported files through the same `/certs/live/<BASE_DOMAIN>/...` mount contract.

## Exporting and Importing Between VPS Hosts
To avoid hitting Let’s Encrypt issuance limits for repeated test deployments, you can move an already issued certificate pair between VPS hosts.

Use the provided helpers:
- `ops/certs/export-existing-cert.sh`
- `ops/certs/import-existing-cert.sh`

### Export from the source VPS
```bash
sudo ./ops/certs/export-existing-cert.sh <BASE_DOMAIN> /root/<BASE_DOMAIN>-cert-export.tar.gz
```

This creates an archive containing:
- `fullchain.pem`
- `privkey.pem`
- `manifest.env`

### Import on the target VPS
```bash
sudo ./ops/certs/import-existing-cert.sh /root/<BASE_DOMAIN>-cert-export.tar.gz <BASE_DOMAIN>
```

After that you can run:
```bash
bash install.sh
```
and choose:
- `TLS_MODE=use-existing`

or directly point `install.sh` at the same extracted `fullchain.pem` and `privkey.pem`.
