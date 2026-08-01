# ShadowScan Mobile V1 Backend

This service provides the server-side functions that cannot safely be embedded in Flutter:

- real email verification codes
- verified-identity enforcement
- Have I Been Pwned account searches
- provider-key protection
- request throttling
- normalized exposure findings

It is intentionally smaller than ShadowEngine. ShadowScan Mobile V2 can later replace these endpoints with ShadowEngine while preserving the same response shapes.

## Local setup

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Export the environment variables from `.env`, then start the service:

```bash
gunicorn --bind 0.0.0.0:8080 app:app
```

For direct development:

```bash
python app.py
```

## Required production configuration

- `OTP_SECRET`: long random secret used to HMAC verification codes
- SMTP credentials for transactional email delivery
- `HIBP_API_KEY`: Have I Been Pwned API subscription key
- `ALLOWED_ORIGIN`: deployed ShadowScan Mobile web origin during web testing
- durable `DB_PATH` or a future managed database

Generate an OTP secret with:

```bash
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

## API

### Health

```http
GET /health
```

### Request verification

```http
POST /api/v1/verification/request
Content-Type: application/json

{
  "email": "user@example.com",
  "consentGranted": true
}
```

### Confirm verification

```http
POST /api/v1/verification/confirm
Content-Type: application/json

{
  "requestId": "vr_...",
  "code": "123456"
}
```

### Scan verified identity

```http
POST /api/v1/exposure/scan
Content-Type: application/json

{
  "identityId": "id_..."
}
```

## Security boundaries

The mobile client must never contain:

- HIBP API keys
- SMTP credentials
- OTP secrets
- plaintext verification codes after submission
- raw stolen credentials

The API returns breach metadata and normalized severity only. It does not return plaintext passwords, session tokens, or complete leaked records.

## Production hardening before launch

The current SQLite implementation is suitable for development and a controlled pilot. Before public release:

1. move identities, verification requests, and findings to PostgreSQL
2. use Redis-backed distributed rate limiting
3. add authenticated user sessions
4. encrypt verified email addresses at rest
5. place the service behind HTTPS and a managed reverse proxy
6. add structured audit logs without verification codes or provider secrets
7. configure email-domain reputation records: SPF, DKIM, and DMARC
8. add automated tests and dependency scanning
