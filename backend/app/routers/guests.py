from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel, EmailStr
from datetime import datetime

from ..database import get_db
from ..models import Guest
from ..auth import verify_token, check_permission

router = APIRouter()

class GuestCreate(BaseModel):
    first_name: str
    last_name: str
    email: EmailStr
    phone: str
    address: Optional[str] = None
    id_number: str
    date_of_birth: Optional[datetime] = None
    nationality: Optional[str] = None

class GuestResponse(BaseModel):
    id: int
    first_name: str
    last_name: str
    email: str
    phone: str
    address: Optional[str] = None
    id_number: str
    date_of_birth: Optional[datetime] = None
    nationality: Optional[str] = None
    vip_status: bool
    created_at: datetime

@router.get("/", response_model=List[GuestResponse])
async def get_guests(db: Session = Depends(get_db), current_user = Depends(verify_token)):
    if not check_permission(current_user, "guests"):
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    guests = db.query(Guest).all()
    return [GuestResponse(
        id=guest.id,
        first_name=guest.first_name,
        last_name=guest.last_name,
        email=guest.email,
        phone=guest.phone,
        address=guest.address,
        id_number=guest.id_number,
        date_of_birth=guest.date_of_birth,
        nationality=guest.nationality,
        vip_status=guest.vip_status,
        created_at=guest.created_at
    ) for guest in guests]

@router.post("/", response_model=GuestResponse)
async def create_guest(guest: GuestCreate, db: Session = Depends(get_db), current_user = Depends(verify_token)):
    if not check_permission(current_user, "guests"):
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    # Check if guest already exists
    db_guest = db.query(Guest).filter(Guest.email == guest.email).first()
    if db_guest:
        raise HTTPException(status_code=400, detail="Guest with this email already exists")
    
    # Create new guest
    db_guest = Guest(
        first_name=guest.first_name,
        last_name=guest.last_name,
        email=guest.email,
        phone=guest.phone,
        address=guest.address,
        id_number=guest.id_number,
        date_of_birth=guest.date_of_birth,
        nationality=guest.nationality
    )
    db.add(db_guest)
    db.commit()
    db.refresh(db_guest)
    
    return GuestResponse(
        id=db_guest.id,
        first_name=db_guest.first_name,
        last_name=db_guest.last_name,
        email=db_guest.email,
        phone=db_guest.phone,
        address=db_guest.address,
        id_number=db_guest.id_number,
        date_of_birth=db_guest.date_of_birth,
        nationality=db_guest.nationality,
        vip_status=db_guest.vip_status,
        created_at=db_guest.created_at
    )