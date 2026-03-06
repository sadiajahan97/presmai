import os
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr

from prisma import Prisma

from db import get_db

pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

JWT_SECRET = os.getenv("JWT_SECRET", "change-me-in-production")
JWT_ALGORITHM = "HS256"
JWT_EXPIRE_MINUTES = 60 * 24 * 7
security = HTTPBearer()

router = APIRouter(prefix="/auth", tags=["auth"])


async def verify_access_token(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> str:
    token = credentials.credentials
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        user_id: str = payload.get("sub")
        return user_id
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
        )


class SignUpRequest(BaseModel):
    email: EmailStr
    password: str
    name: str
    profession: str


class SignInRequest(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: str
    email: str
    name: str
    created_at: datetime

    class Config:
        from_attributes = True


class AuthResponse(BaseModel):
    user: UserResponse
    access_token: str
    token_type: str = "bearer"


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_access_token(sub: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=JWT_EXPIRE_MINUTES)
    payload = {"sub": sub, "exp": expire}
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def user_to_response(user) -> UserResponse:
    return UserResponse(
        id=user.id,
        email=user.email,
        name=user.name,
        created_at=user.createdAt,
    )


@router.post("/sign-up", response_model=AuthResponse)
async def sign_up(body: SignUpRequest, db: Prisma = Depends(get_db)):
    existing = await db.user.find_unique(where={"email": body.email})
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")

    hashed = hash_password(body.password)
    user = await db.user.create(
        data={
            "email": body.email,
            "hashedPassword": hashed,
            "name": body.name,
            "profession": body.profession,
        }
    )

    token = create_access_token(user.id)
    return AuthResponse(user=user_to_response(user), access_token=token)


@router.post("/sign-in", response_model=AuthResponse)
async def sign_in(body: SignInRequest, db: Prisma = Depends(get_db)):
    user = await db.user.find_unique(where={"email": body.email})
    if not user or not verify_password(body.password, user.hashedPassword):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    token = create_access_token(user.id)
    return AuthResponse(
        user=user_to_response(user),
        access_token=token,
    )
