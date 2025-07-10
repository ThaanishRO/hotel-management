from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime

from ..database import get_db
from ..models import Task, TaskType, TaskStatus, Priority
from ..auth import verify_token, check_permission

router = APIRouter()

class TaskCreate(BaseModel):
    room_id: int
    title: str
    description: Optional[str] = None
    task_type: str
    priority: str = "medium"
    due_date: Optional[datetime] = None

class TaskResponse(BaseModel):
    id: int
    room_id: int
    title: str
    description: Optional[str] = None
    task_type: str
    priority: str
    status: str
    assigned_to: Optional[int] = None
    due_date: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    created_at: datetime

@router.get("/", response_model=List[TaskResponse])
async def get_tasks(db: Session = Depends(get_db), current_user = Depends(verify_token)):
    if not check_permission(current_user, "tasks"):
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    tasks = db.query(Task).all()
    return [TaskResponse(
        id=task.id,
        room_id=task.room_id,
        title=task.title,
        description=task.description,
        task_type=task.task_type.value,
        priority=task.priority.value,
        status=task.status.value,
        assigned_to=task.assigned_to,
        due_date=task.due_date,
        completed_at=task.completed_at,
        created_at=task.created_at
    ) for task in tasks]

@router.post("/", response_model=TaskResponse)
async def create_task(task: TaskCreate, db: Session = Depends(get_db), current_user = Depends(verify_token)):
    if not check_permission(current_user, "tasks"):
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    # Create new task
    db_task = Task(
        room_id=task.room_id,
        title=task.title,
        description=task.description,
        task_type=TaskType(task.task_type),
        priority=Priority(task.priority),
        due_date=task.due_date
    )
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    
    return TaskResponse(
        id=db_task.id,
        room_id=db_task.room_id,
        title=db_task.title,
        description=db_task.description,
        task_type=db_task.task_type.value,
        priority=db_task.priority.value,
        status=db_task.status.value,
        assigned_to=db_task.assigned_to,
        due_date=db_task.due_date,
        completed_at=db_task.completed_at,
        created_at=db_task.created_at
    )