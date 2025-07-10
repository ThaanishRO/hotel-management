from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime

from ..database import get_db
from ..models import Room, RoomType, RoomStatus
from ..auth import verify_token, check_permission

router = APIRouter()

class RoomCreate(BaseModel):
    room_number: str
    room_type: str
    price_per_night: float
    floor: int
    amenities: Optional[str] = None

class RoomUpdate(BaseModel):
    room_type: Optional[str] = None
    status: Optional[str] = None
    price_per_night: Optional[float] = None
    floor: Optional[int] = None
    amenities: Optional[str] = None

class RoomResponse(BaseModel):
    id: int
    room_number: str
    room_type: str
    status: str
    price_per_night: float
    floor: int
    amenities: Optional[str] = None
    last_cleaned: Optional[datetime] = None
    next_maintenance: Optional[datetime] = None

@router.get("/", response_model=List[RoomResponse])
async def get_rooms(db: Session = Depends(get_db), current_user = Depends(verify_token)):
    if not check_permission(current_user, "rooms"):
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    rooms = db.query(Room).all()
    return [RoomResponse(
        id=room.id,
        room_number=room.room_number,
        room_type=room.room_type.value,
        status=room.status.value,
        price_per_night=room.price_per_night,
        floor=room.floor,
        amenities=room.amenities,
        last_cleaned=room.last_cleaned,
        next_maintenance=room.next_maintenance
    ) for room in rooms]

@router.post("/", response_model=RoomResponse)
async def create_room(room: RoomCreate, db: Session = Depends(get_db), current_user = Depends(verify_token)):
    if not check_permission(current_user, "rooms"):
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    # Check if room number already exists
    db_room = db.query(Room).filter(Room.room_number == room.room_number).first()
    if db_room:
        raise HTTPException(status_code=400, detail="Room number already exists")
    
    # Create new room
    db_room = Room(
        room_number=room.room_number,
        room_type=RoomType(room.room_type),
        price_per_night=room.price_per_night,
        floor=room.floor,
        amenities=room.amenities
    )
    db.add(db_room)
    db.commit()
    db.refresh(db_room)
    
    return RoomResponse(
        id=db_room.id,
        room_number=db_room.room_number,
        room_type=db_room.room_type.value,
        status=db_room.status.value,
        price_per_night=db_room.price_per_night,
        floor=db_room.floor,
        amenities=db_room.amenities,
        last_cleaned=db_room.last_cleaned,
        next_maintenance=db_room.next_maintenance
    )