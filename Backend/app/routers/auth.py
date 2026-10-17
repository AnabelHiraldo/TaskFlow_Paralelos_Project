import json
import logging
import os
from fastapi import APIRouter, Depends, HTTPException
from google.cloud import pubsub_v1
from sqlalchemy import select
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import User
from ..schemas import UserCreate, UserOut, LoginRequest, Token
from ..security import hash_password, verify_password, create_access_token
from ..config import settings

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Auth"])

@router.post("/register", response_model=UserOut, status_code=201)
def register(data: UserCreate, db: Session = Depends(get_db)):
    existing = db.scalar(select(User).where(User.email == data.email))
    if existing:
        raise HTTPException(status_code=409, detail="El email ya está registrado")

    user = User(
        nombre=data.nombre,
        apellido=data.apellido,
        email=data.email,
        password_hash=hash_password(data.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    # La contraseña y su hash nunca se envían a Pub/Sub.
    project_id = os.getenv("GCP_PROJECT_ID") or settings.gcp_project_id
    if project_id:
        try:
            publisher = pubsub_v1.PublisherClient()
            topic_path = publisher.topic_path(project_id, settings.user_sync_topic)
            event = {
                "id": user.id,
                "nombre": user.nombre,
                "apellido": user.apellido,
                "email": user.email,
                "created_at": user.created_at.isoformat(),
                "is_active": user.is_active,
            }
            publisher.publish(topic_path, json.dumps(event).encode("utf-8")).result(timeout=10)
        except Exception:
            logger.exception("No se pudo publicar réplica local de usuario id=%s", user.id)
    return user

@router.post("/login", response_model=Token)
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = db.scalar(select(User).where(User.email == data.email))
    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")

    return {
        "access_token": create_access_token(user.id),
        "token_type": "bearer",
    }
