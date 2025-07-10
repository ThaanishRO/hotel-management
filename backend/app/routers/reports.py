from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime

from ..database import get_db
from ..models import Report
from ..auth import verify_token, check_permission

router = APIRouter()

class ReportCreate(BaseModel):
    title: str
    report_type: str
    period_start: datetime
    period_end: datetime
    data: str

class ReportResponse(BaseModel):
    id: int
    title: str
    report_type: str
    period_start: datetime
    period_end: datetime
    data: str
    created_at: datetime

@router.get("/", response_model=List[ReportResponse])
async def get_reports(db: Session = Depends(get_db), current_user = Depends(verify_token)):
    if not check_permission(current_user, "reports"):
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    reports = db.query(Report).all()
    return [ReportResponse(
        id=report.id,
        title=report.title,
        report_type=report.report_type,
        period_start=report.period_start,
        period_end=report.period_end,
        data=report.data,
        created_at=report.created_at
    ) for report in reports]

@router.post("/", response_model=ReportResponse)
async def create_report(report: ReportCreate, db: Session = Depends(get_db), current_user = Depends(verify_token)):
    if not check_permission(current_user, "reports"):
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    # Create new report
    db_report = Report(
        title=report.title,
        report_type=report.report_type,
        period_start=report.period_start,
        period_end=report.period_end,
        data=report.data
    )
    db.add(db_report)
    db.commit()
    db.refresh(db_report)
    
    return ReportResponse(
        id=db_report.id,
        title=db_report.title,
        report_type=db_report.report_type,
        period_start=db_report.period_start,
        period_end=db_report.period_end,
        data=db_report.data,
        created_at=db_report.created_at
    )