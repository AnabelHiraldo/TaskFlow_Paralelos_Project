
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

ALLOWED_EXTENSIONS = {
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".png": "image/png",
    ".pdf": "application/pdf",
}

MAX_SIZE = 5 * 1024 * 1024


@router.post("", response_model=FileOut, status_code=201)
async def upload_file(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    # Obtener un nombre seguro y validar la extensión.
    safe_filename = Path(file.filename or "archivo").name
    extension = Path(safe_filename).suffix.lower()

    if extension not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail="Solo se permiten archivos JPG, JPEG, PNG o PDF",
        )

    # Asignar el tipo MIME según la extensión.
    content_type = ALLOWED_EXTENSIONS[extension]

    # Leer el contenido y validar el tamaño real.
    content = await file.read()

    if len(content) > MAX_SIZE:
        raise HTTPException(
            status_code=400,
            detail="El archivo supera 5 MB",
        )

    bucket_name = os.getenv("GCS_BUCKET_NAME")
    stored_name = f"{uuid4().hex}_{safe_filename}"

    if bucket_name:
        from google.cloud import storage

        client = storage.Client()
        bucket = client.bucket(bucket_name)
        blob = bucket.blob(stored_name)

        blob.upload_from_string(
            content,
            content_type=content_type,
        )

        stored_path = f"gs://{bucket_name}/{stored_name}"
    else:
        path = UPLOAD_DIR / stored_name
        path.write_bytes(content)
        stored_path = str(path)

    # Guardar los metadatos en PostgreSQL.
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
