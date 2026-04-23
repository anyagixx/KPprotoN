<!-- FILE: ops/certs/README.md -->
<!-- VERSION: 1.0.0 -->
<!-- START_MODULE_CONTRACT -->
<!--   PURPOSE: Explain the certificate issuance, reuse, and mount contract that secures the shared 443 edge. -->
<!--   SCOPE: Guided DNS-01 flow, reuse of existing certs, host/container path mapping, and VPS-to-VPS certificate transfer. -->
<!--   DEPENDS: M-CONFIG -->
<!--   LINKS: M-CERTS, M-INSTALL, M-PROXY-BRIDGE -->
<!-- END_MODULE_CONTRACT -->
<!-- -->
<!-- START_MODULE_MAP -->
<!--   Guided Manual DNS-01 - wildcard issuance workflow -->
<!--   Mount Contract - host and container TLS paths -->
<!--   Existing Certificate Reuse - import path for pre-issued certs -->
<!--   VPS Transfer - export/import helpers for repeated deployments -->
<!-- END_MODULE_MAP -->
<!-- -->
<!-- START_CHANGE_SUMMARY -->
<!--   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for the certificate operations README. -->
<!-- END_CHANGE_SUMMARY -->
<!-- -->
<!-- START_BLOCK_CERT_GUIDE -->
# KPprotoN Certificate Bootstrap

KPprotoN uses a guided manual DNS-01 flow for wildcard certificate issuance.

## Why
- `*.example.com` cannot be issued through plain HTTP-01.
- For a wildcard certificate, the installer must stop and wait until you really add the TXT record and confirm propagation.

## Guided Manual DNS-01
1. Run `install.sh`.
2. Choose `TLS_MODE=issue-new`.
3. The installer calls `ops/certs/provision-certs.sh` in guided manual DNS-01 mode.
4. The installer prints the exact TXT record name and value for `_acme-challenge.<BASE_DOMAIN>`.
5. You add the TXT record in your DNS panel, verify propagation yourself, and press `Enter`.
6. The hook checks that the TXT value is publicly visible via `dig`.
7. Only after the TXT is visible does Certbot continue and issue the apex + wildcard certificate into `/etc/letsencrypt/live/<BASE_DOMAIN>/`.

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

Important:
- a self-signed certificate is suitable only for web-panel smoke testing
- Telegram fake-TLS proxy checks may still reject self-signed certificates as `Not Available`
- for real proxy usage, import a publicly trusted wildcard certificate for `<BASE_DOMAIN>` and `*.<BASE_DOMAIN>`

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
<!-- END_BLOCK_CERT_GUIDE -->
