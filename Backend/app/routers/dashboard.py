import asyncio
from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import Task, User
from ..security import get_current_user

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])

async def profile_data(user: User):
    await asyncio.sleep(0.15)
    return {"id": user.id, "nombre": user.nombre, "apellido": user.apellido, "email": user.email}

async def stats_data(user_id: int, db: Session):
    await asyncio.sleep(0.15)
    total = db.scalar(select(func.count(Task.id)).where(Task.user_id == user_id)) or 0
    completed = db.scalar(select(func.count(Task.id)).where(Task.user_id == user_id, Task.completada == True)) or 0
    return {"total_tasks": total, "completed_tasks": completed}

async def notifications_data():
    await asyncio.sleep(0.15)
    return {"items": ["Bienvenido a TaskFlow", "Revisa tus tareas pendientes"]}

async def task_summary(user_id: int, db: Session):
    await asyncio.sleep(0.15)
    pending = db.scalar(select(func.count(Task.id)).where(Task.user_id == user_id, Task.completada == False)) or 0
    return {"pending_tasks": pending}

@router.get("/profile")
async def profile(user: User = Depends(get_current_user)):
    return await profile_data(user)

@router.get("/stats")
async def stats(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return await stats_data(user.id, db)

@router.get("/notifications")
async def notifications(user: User = Depends(get_current_user)):
    return await notifications_data()

@router.get("/task-summary")
async def task_summary_endpoint(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return await task_summary(user.id, db)

@router.get("/sequential")
async def dashboard_sequential(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    profile = await profile_data(user)
    stats = await stats_data(user.id, db)
    notifications = await notifications_data()
    tasks = await task_summary(user.id, db)
    return {"profile": profile, "stats": stats, "notifications": notifications, "tasks": tasks}

@router.get("/concurrent")
async def dashboard_concurrent(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    profile, stats_result, notifications_result, tasks_result = await asyncio.gather(
        profile_data(user),
        stats_data(user.id, db),
        notifications_data(),
        task_summary(user.id, db),
    )
    return {
        "profile": profile,
        "stats": stats_result,
        "notifications": notifications_result,
        "tasks": tasks_result,
    }
