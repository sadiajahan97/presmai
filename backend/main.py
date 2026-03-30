import asyncio
import os
import mimetypes
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from botocore.exceptions import ClientError

load_dotenv()
from prisma import Prisma

from auth import router as auth_router
from chats import router as chats_router
from profile import router as profile_router
from prescriptions import router as prescriptions_router
from db import set_db
from notifications import notification_loop, router as notifications_router
from storage import router as storage_router
from vector_db import init_qdrant
from s3 import AWS_BUCKET_NAME, s3_client
import firebase_admin
from firebase_admin import credentials

prisma = Prisma()

def _init_firebase() -> None:
    try:
        firebase_admin.get_app()
        return
    except ValueError:
        pass

    required_env_keys = [
        "FIREBASE_AUTH_PROVIDER_X509_CERT_URL",
        "FIREBASE_AUTH_URI",
        "FIREBASE_CLIENT_EMAIL",
        "FIREBASE_CLIENT_ID",
        "FIREBASE_CLIENT_X509_CERT_URL",
        "FIREBASE_PRIVATE_KEY",
        "FIREBASE_PRIVATE_KEY_ID",
        "FIREBASE_PROJECT_ID",
        "FIREBASE_TOKEN_URI",
        "FIREBASE_TYPE",
        "FIREBASE_UNIVERSE_DOMAIN",
    ]

    env_has_all = all(os.getenv(k) for k in required_env_keys)
    if env_has_all:
        private_key = os.environ["FIREBASE_PRIVATE_KEY"].replace("\\n", "\n")
        cred_info = {
            "auth_provider_x509_cert_url": os.environ["FIREBASE_AUTH_PROVIDER_X509_CERT_URL"],
            "auth_uri": os.environ["FIREBASE_AUTH_URI"],
            "client_email": os.environ["FIREBASE_CLIENT_EMAIL"],
            "client_id": os.environ["FIREBASE_CLIENT_ID"],
            "client_x509_cert_url": os.environ["FIREBASE_CLIENT_X509_CERT_URL"],
            "private_key": private_key,
            "private_key_id": os.environ["FIREBASE_PRIVATE_KEY_ID"],
            "project_id": os.environ["FIREBASE_PROJECT_ID"],
            "token_uri": os.environ["FIREBASE_TOKEN_URI"],
            "type": os.environ["FIREBASE_TYPE"],
            "universe_domain": os.environ["FIREBASE_UNIVERSE_DOMAIN"],
        }
        firebase_admin.initialize_app(credentials.Certificate(cred_info))
        return

    raise RuntimeError("Firebase not configured: set FIREBASE_* env vars in backend/.env")


_init_firebase()


@asynccontextmanager
async def lifespan(app: FastAPI):
    await prisma.connect()
    set_db(prisma)
    init_qdrant()
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
app.include_router(prescriptions_router)
app.include_router(notifications_router)
app.include_router(storage_router)

@app.get("/storage/{key_path:path}")
async def download_storage_object(key_path: str):
    s3_key = key_path.lstrip("/")

    try:
        obj = s3_client.get_object(Bucket=AWS_BUCKET_NAME, Key=s3_key)
    except ClientError as e:
        code = str(e.response.get("Error", {}).get("Code", ""))
        status = e.response.get("ResponseMetadata", {}).get("HTTPStatusCode")
        if status == 404 or code in {"NoSuchKey", "404", "NotFound"}:
            raise HTTPException(status_code=404, detail="Not found")
        raise

    content_type = mimetypes.guess_type(s3_key)[0] or "application/octet-stream"
    return StreamingResponse(obj["Body"], media_type=content_type)


@app.get("/")
async def root():
    return {"message": "Hello from PresMAI API"}


@app.get("/health")
async def health():
    return {"status": "ok"}
