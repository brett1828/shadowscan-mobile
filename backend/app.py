import hashlib
import hmac
import os
import secrets
import smtplib
import sqlite3
from datetime import datetime, timedelta, timezone
from email.message import EmailMessage

import requests
from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": os.getenv("ALLOWED_ORIGIN", "*")}})
limiter = Limiter(get_remote_address, app=app, default_limits=["200 per day", "50 per hour"])

DB_PATH = os.getenv("DB_PATH", "shadowscan_v1.db")
OTP_TTL_MINUTES = int(os.getenv("OTP_TTL_MINUTES", "10"))
OTP_SECRET = os.getenv("OTP_SECRET", "")
HIBP_API_KEY = os.getenv("HIBP_API_KEY", "")
HIBP_USER_AGENT = os.getenv("HIBP_USER_AGENT", "ShadowScan-Mobile/1.0 contact@quantumshadowblackops.com")


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def db() -> sqlite3.Connection:
    connection = sqlite3.connect(DB_PATH)
    connection.row_factory = sqlite3.Row
    return connection


def init_db() -> None:
    with db() as connection:
        connection.executescript(
            """
            CREATE TABLE IF NOT EXISTS verification_requests (
                id TEXT PRIMARY KEY,
                email TEXT NOT NULL,
                code_hash TEXT NOT NULL,
                expires_at TEXT NOT NULL,
                attempts INTEGER NOT NULL DEFAULT 0,
                verified_at TEXT
            );

            CREATE TABLE IF NOT EXISTS verified_identities (
                id TEXT PRIMARY KEY,
                email TEXT UNIQUE NOT NULL,
                verified_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS exposure_findings (
                id TEXT PRIMARY KEY,
                identity_id TEXT NOT NULL,
                breach_name TEXT NOT NULL,
                breach_domain TEXT,
                breach_date TEXT,
                added_date TEXT,
                description TEXT,
                data_classes TEXT NOT NULL,
                severity TEXT NOT NULL,
                provider TEXT NOT NULL,
                created_at TEXT NOT NULL,
                UNIQUE(identity_id, breach_name)
            );
            """
        )


def normalize_email(value: str) -> str:
    return value.strip().lower()


def hash_code(email: str, code: str) -> str:
    if not OTP_SECRET:
        raise RuntimeError("OTP_SECRET is not configured")
    payload = f"{email}:{code}".encode()
    return hmac.new(OTP_SECRET.encode(), payload, hashlib.sha256).hexdigest()


def send_verification_email(email: str, code: str) -> None:
    host = os.getenv("SMTP_HOST", "")
    port = int(os.getenv("SMTP_PORT", "587"))
    username = os.getenv("SMTP_USERNAME", "")
    password = os.getenv("SMTP_PASSWORD", "")
    sender = os.getenv("SMTP_FROM", "")

    if not all([host, username, password, sender]):
        raise RuntimeError("SMTP settings are incomplete")

    message = EmailMessage()
    message["Subject"] = "Your ShadowScan verification code"
    message["From"] = sender
    message["To"] = email
    message.set_content(
        f"Your ShadowScan verification code is {code}. "
        f"It expires in {OTP_TTL_MINUTES} minutes. "
        "If you did not request this code, ignore this email."
    )

    with smtplib.SMTP(host, port, timeout=20) as smtp:
        smtp.starttls()
        smtp.login(username, password)
        smtp.send_message(message)


def severity_for(data_classes: list[str]) -> str:
    values = {item.lower() for item in data_classes}
    critical_terms = {"passwords", "authentication tokens", "credit cards", "bank account numbers"}
    high_terms = {"password hints", "security questions and answers", "phone numbers", "dates of birth"}
    moderate_terms = {"physical addresses", "ip addresses", "geographic locations"}

    if values & critical_terms:
        return "critical"
    if values & high_terms:
        return "high"
    if values & moderate_terms:
        return "moderate"
    return "low"


@app.get("/health")
def health():
    return jsonify({"status": "ok", "service": "shadowscan-v1-backend"})


@app.post("/api/v1/verification/request")
@limiter.limit("5 per hour")
def request_verification():
    body = request.get_json(silent=True) or {}
    email = normalize_email(body.get("email", ""))
    consent = body.get("consentGranted") is True

    if "@" not in email or len(email) > 254:
        return jsonify({"error": "invalid_email"}), 400
    if not consent:
        return jsonify({"error": "consent_required"}), 400

    code = f"{secrets.randbelow(1_000_000):06d}"
    request_id = f"vr_{secrets.token_urlsafe(18)}"
    expires_at = utc_now() + timedelta(minutes=OTP_TTL_MINUTES)

    try:
        code_hash = hash_code(email, code)
        send_verification_email(email, code)
    except RuntimeError as exc:
        app.logger.exception("Verification configuration error")
        return jsonify({"error": "verification_unavailable", "message": str(exc)}), 503
    except Exception:
        app.logger.exception("Verification email delivery failed")
        return jsonify({"error": "email_delivery_failed"}), 502

    with db() as connection:
        connection.execute(
            "INSERT INTO verification_requests (id, email, code_hash, expires_at) VALUES (?, ?, ?, ?)",
            (request_id, email, code_hash, expires_at.isoformat()),
        )

    return jsonify({"requestId": request_id, "expiresInSeconds": OTP_TTL_MINUTES * 60}), 201


@app.post("/api/v1/verification/confirm")
@limiter.limit("10 per hour")
def confirm_verification():
    body = request.get_json(silent=True) or {}
    request_id = body.get("requestId", "")
    code = str(body.get("code", "")).strip()

    if len(code) != 6 or not code.isdigit():
        return jsonify({"error": "invalid_code"}), 400

    with db() as connection:
        row = connection.execute(
            "SELECT * FROM verification_requests WHERE id = ?", (request_id,)
        ).fetchone()
        if row is None:
            return jsonify({"error": "verification_not_found"}), 404
        if row["verified_at"]:
            return jsonify({"error": "verification_already_used"}), 409
        if row["attempts"] >= 5:
            return jsonify({"error": "too_many_attempts"}), 429

        connection.execute(
            "UPDATE verification_requests SET attempts = attempts + 1 WHERE id = ?",
            (request_id,),
        )

        if utc_now() > datetime.fromisoformat(row["expires_at"]):
            return jsonify({"error": "verification_expired"}), 410

        expected = row["code_hash"]
        supplied = hash_code(row["email"], code)
        if not hmac.compare_digest(expected, supplied):
            return jsonify({"error": "incorrect_code"}), 401

        verified_at = utc_now().isoformat()
        identity_id = f"id_{hashlib.sha256(row['email'].encode()).hexdigest()[:24]}"
        connection.execute(
            "UPDATE verification_requests SET verified_at = ? WHERE id = ?",
            (verified_at, request_id),
        )
        connection.execute(
            "INSERT INTO verified_identities (id, email, verified_at) VALUES (?, ?, ?) "
            "ON CONFLICT(email) DO UPDATE SET verified_at = excluded.verified_at",
            (identity_id, row["email"], verified_at),
        )

    return jsonify({"identityId": identity_id, "email": row["email"], "verified": True})


@app.post("/api/v1/exposure/scan")
@limiter.limit("10 per day")
def scan_exposure():
    body = request.get_json(silent=True) or {}
    identity_id = body.get("identityId", "")

    with db() as connection:
        identity = connection.execute(
            "SELECT * FROM verified_identities WHERE id = ?", (identity_id,)
        ).fetchone()

    if identity is None:
        return jsonify({"error": "verified_identity_required"}), 403
    if not HIBP_API_KEY:
        return jsonify({"error": "provider_not_configured"}), 503

    response = requests.get(
        f"https://haveibeenpwned.com/api/v3/breachedaccount/{identity['email']}",
        params={"truncateResponse": "false"},
        headers={"hibp-api-key": HIBP_API_KEY, "user-agent": HIBP_USER_AGENT},
        timeout=20,
    )

    if response.status_code == 404:
        return jsonify({"identityId": identity_id, "findings": [], "total": 0})
    if response.status_code == 429:
        return jsonify({"error": "provider_rate_limited"}), 429
    if response.status_code != 200:
        app.logger.error("HIBP request failed: %s %s", response.status_code, response.text[:300])
        return jsonify({"error": "provider_unavailable"}), 502

    findings = []
    with db() as connection:
        for breach in response.json():
            data_classes = breach.get("DataClasses", [])
            severity = severity_for(data_classes)
            finding_id = f"hibp_{hashlib.sha256((identity_id + breach['Name']).encode()).hexdigest()[:24]}"
            normalized = {
                "id": finding_id,
                "identityId": identity_id,
                "sourceName": breach.get("Title") or breach.get("Name"),
                "sourceDomain": breach.get("Domain"),
                "breachDate": breach.get("BreachDate"),
                "addedDate": breach.get("AddedDate"),
                "description": breach.get("Description"),
                "dataClasses": data_classes,
                "severity": severity,
                "status": "action_required",
                "provider": "have_i_been_pwned",
            }
            findings.append(normalized)
            connection.execute(
                """
                INSERT INTO exposure_findings
                (id, identity_id, breach_name, breach_domain, breach_date, added_date,
                 description, data_classes, severity, provider, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(identity_id, breach_name) DO UPDATE SET
                  breach_domain = excluded.breach_domain,
                  breach_date = excluded.breach_date,
                  added_date = excluded.added_date,
                  description = excluded.description,
                  data_classes = excluded.data_classes,
                  severity = excluded.severity
                """,
                (
                    finding_id,
                    identity_id,
                    normalized["sourceName"],
                    normalized["sourceDomain"],
                    normalized["breachDate"],
                    normalized["addedDate"],
                    normalized["description"],
                    ",".join(data_classes),
                    severity,
                    normalized["provider"],
                    utc_now().isoformat(),
                ),
            )

    findings.sort(key=lambda item: item.get("breachDate") or "", reverse=True)
    return jsonify({"identityId": identity_id, "findings": findings, "total": len(findings)})


if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8080")), debug=False)
