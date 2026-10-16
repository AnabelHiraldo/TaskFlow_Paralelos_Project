import json
import logging
import os

from fastapi import APIRouter, Depends, HTTPException, status
from google.cloud import pubsub_v1
from pydantic import BaseModel, EmailStr, Field, field_validator

from ..models import User
from ..security import get_current_user

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/notifications", tags=["Notifications"])


class NotificationRequest(BaseModel):
    email: EmailStr
    subject: str = Field(min_length=1, max_length=200)
    message: str = Field(min_length=1, max_length=10000)

    @field_validator("subject")
    @classmethod
    def subject_is_single_line(cls, value: str) -> str:
        if "\r" in value or "\n" in value:
            raise ValueError("El asunto debe ocupar una sola línea")
        return value.strip()

    @field_validator("message", "subject")
    @classmethod
    def text_is_not_blank(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("Este campo no puede estar vacío")
        return value.strip()


@router.post("/send", status_code=status.HTTP_202_ACCEPTED)
def send_notification(
    data: NotificationRequest,
    user: User = Depends(get_current_user),
):
    project_id = os.getenv("GCP_PROJECT_ID")
    topic_id = os.getenv("NOTIFICATION_TOPIC", "taskflow-notifications")
    if not project_id:
        logger.error("No está configurado GCP_PROJECT_ID")
        raise HTTPException(status_code=503, detail="Servicio de notificaciones no configurado")

    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project_id, topic_id)
    payload = json.dumps(data.model_dump(), ensure_ascii=False).encode("utf-8")
    try:
        message_id = publisher.publish(
            topic_path,
            payload,
            requested_by=str(user.id),
        ).result(timeout=10)
    except Exception as exc:
        logger.exception("No se pudo publicar la notificación")
        raise HTTPException(status_code=502, detail="No se pudo poner el mensaje en cola") from exc

    logger.info("Notificación publicada en Pub/Sub", extra={"message_id": message_id})
    return {"message": "Mensaje enviado correctamente.", "message_id": message_id}
