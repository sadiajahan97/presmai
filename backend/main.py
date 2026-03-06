from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

load_dotenv()
from prisma import Prisma

from auth import router as auth_router
from db import set_db

prisma = Prisma()


@asynccontextmanager
async def lifespan(app: FastAPI):
    await prisma.connect()
    set_db(prisma)
    yield
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


@app.get("/")
async def root():
    return {"message": "Hello from PresMAI API"}


@app.get("/health")
async def health():
    return {"status": "ok"}
