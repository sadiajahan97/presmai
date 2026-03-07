from fastapi import APIRouter, Depends, HTTPException

from prisma import Prisma

from auth import verify_access_token, UserResponse, user_to_response
from db import get_db

router = APIRouter(prefix="/profile", tags=["profile"])


@router.get("/", response_model=UserResponse)
async def get_profile(
    user_id: str = Depends(verify_access_token),
    db: Prisma = Depends(get_db),
):
    user = await db.user.find_unique(where={"id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user_to_response(user)
