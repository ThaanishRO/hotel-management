from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime

from ..database import get_db
from ..models import Booking, BookingStatus
from ..auth import verify_token, check_permission

router = APIRouter()

class BookingCreate(BaseModel):
    guest_id: int
    room_id: int
    check_in_date: datetime
    check_out_date: datetime
    total_amount: float
    number_of_guests: int = 1
    special_requests: Optional[str] = None

class BookingResponse(BaseModel):
    id: int
    guest_id: int
    room_id: int
    check_in_date: datetime
    check_out_date: datetime
    status: str
    total_amount: float
    paid_amount: float
    number_of_guests: int
    special_requests: Optional[str] = None
    created_by: int
    created_at: datetime

@router.get("/", response_model=List[BookingResponse])
async def get_bookings(db: Session = Depends(get_db), current_user = Depends(verify_token)):
    if not check_permission(current_user, "bookings"):
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    bookings = db.query(Booking).all()
    return [BookingResponse(
        id=booking.id,
        guest_id=booking.guest_id,
        room_id=booking.room_id,
        check_in_date=booking.check_in_date,
        check_out_date=booking.check_out_date,
        status=booking.status.value,
        total_amount=booking.total_amount,
        paid_amount=booking.paid_amount,
        number_of_guests=booking.number_of_guests,
        special_requests=booking.special_requests,
        created_by=booking.created_by,
        created_at=booking.created_at
    ) for booking in bookings]

@router.post("/", response_model=BookingResponse)
async def create_booking(booking: BookingCreate, db: Session = Depends(get_db), current_user = Depends(verify_token)):
    if not check_permission(current_user, "bookings"):
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    # Create new booking
    db_booking = Booking(
        guest_id=booking.guest_id,
        room_id=booking.room_id,
        check_in_date=booking.check_in_date,
        check_out_date=booking.check_out_date,
        total_amount=booking.total_amount,
        number_of_guests=booking.number_of_guests,
        special_requests=booking.special_requests,
        created_by=current_user.id
    )
    db.add(db_booking)
    db.commit()
    db.refresh(db_booking)
    
    return BookingResponse(
        id=db_booking.id,
        guest_id=db_booking.guest_id,
        room_id=db_booking.room_id,
        check_in_date=db_booking.check_in_date,
        check_out_date=db_booking.check_out_date,
        status=db_booking.status.value,
        total_amount=db_booking.total_amount,
        paid_amount=db_booking.paid_amount,
        number_of_guests=db_booking.number_of_guests,
        special_requests=db_booking.special_requests,
        created_by=db_booking.created_by,
        created_at=db_booking.created_at
    )