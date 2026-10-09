import os
from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import FileRecord, User
from ..schemas import FileOut
from ..security import get_current_user

router = APIRouter(prefix="/upload", tags=["Files"])

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

ALLOWED_TYPES = {"image/jpeg", "image/png", "application/pdf"}
MAX_SIZE = 5 * 1024 * 1024


@router.post("", response_model=FileOut, status_code=201)
async def upload_file(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=400,
            detail="Solo se permiten JPG, PNG o PDF",
        )

    content = await file.read()

    if len(content) > MAX_SIZE:
        raise HTTPException(
            status_code=400,
            detail="El archivo supera 5 MB",
        )

    bucket_name = os.getenv("GCS_BUCKET_NAME")
    safe_filename = Path(file.filename or "archivo").name
    stored_name = f"{uuid4().hex}_{safe_filename}"
    content_type = file.content_type or "application/octet-stream"

    if bucket_name:
        from google.cloud import storage

        client = storage.Client()
        bucket = client.bucket(bucket_name)
        blob = bucket.blob(stored_name)
        blob.upload_from_string(content, content_type=content_type)
        stored_path = f"gs://{bucket_name}/{stored_name}"
    else:
        path = UPLOAD_DIR / stored_name
        path.write_bytes(content)
        stored_path = str(path)

    record = FileRecord(
        filename=safe_filename,
        stored_name=stored_name,
        content_type=content_type,
        size=len(content),
        path=stored_path,
        user_id=user.id,
    )

    db.add(record)
    db.commit()
    db.refresh(record)
    return record


@router.delete("/{file_id}", status_code=204)
def delete_file(
    file_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    record = db.scalar(
        select(FileRecord).where(
            FileRecord.id == file_id,
            FileRecord.user_id == user.id,
        )
    )

    if not record:
        raise HTTPException(
            status_code=404,
            detail="Archivo no encontrado",
        )

    if record.path.startswith("gs://"):
        from google.cloud import storage

        location = record.path[len("gs://"):]
        bucket_name, object_name = location.split("/", 1)

        client = storage.Client()
        blob = client.bucket(bucket_name).blob(object_name)

        if blob.exists():
            blob.delete()
    else:
        path = Path(record.path)
        if path.exists():
            path.unlink()

    db.delete(record)
    db.commit()
