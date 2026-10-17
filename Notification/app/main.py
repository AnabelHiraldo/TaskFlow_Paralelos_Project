import base64
import binascii
import logging
import os
import smtplib
import ssl
from email.message import EmailMessage

from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel, EmailStr, Field, ValidationError, field_validator

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
logger = logging.getLogger("taskflow.notifications")
app = FastAPI(title="TaskFlow Notification Service", version="1.0.0")


class Notification(BaseModel):
    email: EmailStr
    subject: str = Field(min_length=1, max_length=200)
    message: str = Field(min_length=1, max_length=10000)

    @field_validator("subject")
    @classmethod
    def subject_is_single_line(cls, value: str) -> str:
        if "\r" in value or "\n" in value or not value.strip():
            raise ValueError("Asunto inválido")
        return value.strip()

    @field_validator("message")
    @classmethod
    def message_is_not_blank(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("El mensaje no puede estar vacío")
        return value.strip()


@app.get("/health")
def health():
    return {"status": "ok"}


def send_email(notification: Notification) -> None:
    host = os.environ["SMTP_HOST"]
    port = int(os.getenv("SMTP_PORT", "587"))
    username = os.environ["SMTP_USERNAME"]
    # Google displays app passwords in four-character groups; remove copied whitespace before SMTP auth.
    password = "".join(os.environ["SMTP_PASSWORD"].split())
    sender = os.environ["SMTP_FROM"]

    email = EmailMessage()
    email["From"] = sender
    email["To"] = str(notification.email)
    email["Subject"] = notification.subject
    email.set_content(notification.message)

    if port == 465:
        with smtplib.SMTP_SSL(host, port, context=ssl.create_default_context(), timeout=20) as smtp:
            smtp.login(username, password)
            smtp.send_message(email)
        return

    with smtplib.SMTP(host, port, timeout=20) as smtp:
        smtp.ehlo()
        smtp.starttls(context=ssl.create_default_context())
        smtp.ehlo()
        smtp.login(username, password)
        smtp.send_message(email)


@app.post("/pubsub")
async def receive_pubsub(request: Request):
    try:
        envelope = await request.json()
        encoded = envelope["message"]["data"]
        message_id = envelope["message"].get("messageId", "desconocido")
        decoded = base64.b64decode(encoded, validate=True)
        notification = Notification.model_validate_json(decoded)
    except (ValueError, KeyError, TypeError, binascii.Error, ValidationError) as exc:
        logger.exception("Mensaje Pub/Sub inválido")
        raise HTTPException(status_code=400, detail="Mensaje Pub/Sub inválido") from exc

    try:
        send_email(notification)
    except Exception as exc:
        logger.exception("Falló el envío del correo", extra={"message_id": message_id})
        # Pub/Sub retries non-2xx deliveries, so transient SMTP failures are not acknowledged.
        raise HTTPException(status_code=500, detail="No se pudo enviar el correo") from exc

    logger.info(
        "Correo enviado correctamente",
        extra={"message_id": message_id, "recipient": str(notification.email)},
    )
    return {"status": "sent", "message_id": message_id}
