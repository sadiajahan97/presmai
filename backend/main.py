import asyncio
import os
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

load_dotenv()
from prisma import Prisma

from auth import router as auth_router
from chats import router as chats_router
from profile import router as profile_router
from db import set_db
from notifications import notification_loop, router as notifications_router
from storage import router as storage_router
from vector_db import init_chroma
import firebase_admin
from firebase_admin import credentials

prisma = Prisma()

try:
    firebase_admin.get_app()
except ValueError:
    cred_path = "firebase-credentials.json"
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    else:
        firebase_admin.initialize_app()


@asynccontextmanager
async def lifespan(app: FastAPI):
    await prisma.connect()
    set_db(prisma)
    init_chroma()
    task = asyncio.create_task(notification_loop())
    yield
    task.cancel()
    await prisma.disconnect()


app = FastAPI(
    title="PresMAI API",
    description="FastAPI backend for PresMAI",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(chats_router)
app.include_router(profile_router)
app.include_router(notifications_router)
app.include_router(storage_router)

os.makedirs("storage", exist_ok=True)
app.mount("/storage", StaticFiles(directory="storage"), name="storage")


@app.get("/")
async def root():
    return {"message": "Hello from PresMAI API"}


@app.get("/health")
async def health():
    return {"status": "ok"}
