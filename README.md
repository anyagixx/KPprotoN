# KPprotoN

KPprotoN is a turnkey personal MTProto proxy stack for a clean Ubuntu VPS.

What it includes:
- Erlang/OTP runtime
- Cowboy web portal on `https://BASE_DOMAIN`
- personal proxy issuance after email verification
- Resend magic-link delivery
- DETS-backed registry
- shared `:443` edge for HTTPS portal and MTProto fake-TLS
- one-script deployment with `install.sh`

## What the project does

1. You deploy KPprotoN on a fresh Ubuntu 22.04/24.04 VPS.
2. A user opens the web page and enters an email.
3. The system sends a verification email with a magic link.
4. After verification, the user gets a personal `tg://proxy` link and manual MTProto fields.

## One-script VPS deployment

On a clean VPS:

```bash
git clone https://github.com/anyagixx/KPprotoN.git
cd KPprotoN
bash install.sh
```

The installer asks for:
- `BASE_DOMAIN`
- `RESEND_API_KEY`
- `TLS_MODE`

`TLS_MODE` supports:
- `issue-new`
- `use-existing`

## TLS modes

### 1. Issue a new wildcard certificate

Choose:

```text
TLS_MODE=issue-new
```

Then the installer will:
- print the TXT record name/value
- wait for your `Enter`
- verify TXT propagation with `dig`
- continue only after propagation is visible

### 2. Reuse an existing certificate

Choose:

```text
TLS_MODE=use-existing
```

Then provide:
- `EXISTING_CERT_FULLCHAIN_PATH`
- `EXISTING_CERT_PRIVKEY_PATH`

The installer validates the pair and stages it into:

```text
/etc/letsencrypt/live/<BASE_DOMAIN>/
```

## Reusing certificates between VPS hosts

To avoid unnecessary Let’s Encrypt reissuance for repeated test deployments:

Export on the source VPS:

```bash
sudo ./ops/certs/export-existing-cert.sh <BASE_DOMAIN> /root/<BASE_DOMAIN>-cert-export.tar.gz
```

Import on the target VPS:

```bash
sudo ./ops/certs/import-existing-cert.sh /root/<BASE_DOMAIN>-cert-export.tar.gz <BASE_DOMAIN>
```

Then run:

```bash
bash install.sh
```

and use `TLS_MODE=use-existing`.

## Resend

You need a valid Resend API key:

```text
RESEND_API_KEY=re_...
```

The project sends a branded verification email and only issues a proxy after the user confirms the email address.

## After installation

The installer prints:

```text
https://<BASE_DOMAIN>
```

That page is the user-facing portal for requesting proxy access.

## Runtime data

Persistent data:
- DETS files
- token storage
- imported or issued TLS material

Runtime TLS contract:
- host: `/etc/letsencrypt`
- container: `/certs`
- certificate: `/certs/live/<BASE_DOMAIN>/fullchain.pem`
- key: `/certs/live/<BASE_DOMAIN>/privkey.pem`

## Useful commands

Check containers:

```bash
docker compose ps
```

Check logs:

```bash
docker compose logs --tail=200
```

Rebuild and restart:

```bash
docker compose --env-file .env up -d --build
```

## Project highlights

- one-command VPS bootstrap
- wildcard TLS support
- guided manual DNS-01
- copyable proxy delivery UX
- personal fake-TLS proxy links for Telegram
