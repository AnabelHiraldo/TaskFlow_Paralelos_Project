from datetime import datetime
from pydantic import BaseModel, ConfigDict, EmailStr

class UserCreate(BaseModel):
    nombre: str
    apellido: str
    email: EmailStr
    password: str

class UserUpdate(BaseModel):
    nombre: str | None = None
    apellido: str | None = None
    email: EmailStr | None = None

class UserOut(BaseModel):
    id: int
    nombre: str
    apellido: str
    email: EmailStr
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class TaskCreate(BaseModel):
    titulo: str
    descripcion: str | None = None

class TaskUpdate(BaseModel):
    titulo: str | None = None
    descripcion: str | None = None
    completada: bool | None = None

class TaskOut(BaseModel):
    id: int
    titulo: str
    descripcion: str | None
    completada: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class FileOut(BaseModel):
    id: int
    filename: str
    content_type: str
    size: int
    path: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
