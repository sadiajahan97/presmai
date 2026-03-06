import os
import uuid
from datetime import datetime
from typing import List

from fastapi import APIRouter, Depends, HTTPException, Form, UploadFile
from pydantic import BaseModel
from prisma import Prisma

from auth import verify_access_token
from db import get_db
from llm import generate_response

router = APIRouter(prefix="/chats", tags=["chats"])


class ChatResponse(BaseModel):
    id: str
    name: str
    userId: str
    createdAt: datetime
    updatedAt: datetime

    class Config:
        from_attributes = True


class MessageResponse(BaseModel):
    id: str
    content: str | None
    image: str | None
    role: str
    chatId: str
    createdAt: datetime
    updatedAt: datetime

    class Config:
        from_attributes = True


class CreateChatRequest(BaseModel):
    name: str = "New Chat"


@router.post("/", response_model=ChatResponse)
async def create_chat(
    body: CreateChatRequest,
    user_id: str = Depends(verify_access_token),
    db: Prisma = Depends(get_db),
):
    chat = await db.chat.create(
        data={
            "name": body.name,
            "userId": user_id,
        }
    )
    return chat


@router.get("/{chat_id}", response_model=ChatResponse)
async def get_chat(
    chat_id: str, user_id: str = Depends(verify_access_token), db: Prisma = Depends(get_db)
):
    chat = await db.chat.find_unique(where={"id": chat_id})
    if not chat or chat.userId != user_id:
        raise HTTPException(status_code=404, detail="Chat not found")
    return chat


@router.delete("/{chat_id}")
async def delete_chat(
    chat_id: str, user_id: str = Depends(verify_access_token), db: Prisma = Depends(get_db)
):
    chat = await db.chat.find_unique(where={"id": chat_id})
    if not chat or chat.userId != user_id:
        raise HTTPException(status_code=404, detail="Chat not found")

    await db.chat.delete(where={"id": chat_id})
    return {"success": True, "message": "Chat deleted successfully"}


@router.get("/", response_model=List[ChatResponse])
async def list_chats(
    user_id: str = Depends(verify_access_token), db: Prisma = Depends(get_db)
):
    chats = await db.chat.find_many(
        where={"userId": user_id}, order={"createdAt": "desc"}
    )
    return chats


@router.get("/{chat_id}/messages", response_model=List[MessageResponse])
async def list_messages(
    chat_id: str,
    user_id: str = Depends(verify_access_token),
    db: Prisma = Depends(get_db),
):
    chat = await db.chat.find_unique(where={"id": chat_id})
    if not chat or chat.userId != user_id:
        raise HTTPException(status_code=404, detail="Chat not found")

    messages = await db.message.find_many(
        where={"chatId": chat_id}, order={"createdAt": "asc"}
    )
    return messages


@router.post("/{chat_id}/messages", response_model=MessageResponse)
async def send_message(
    chat_id: str,
    content: str | None = Form(None),
    file: UploadFile | None = None,
    user_id: str = Depends(verify_access_token),
    db: Prisma = Depends(get_db),
):
    chat = await db.chat.find_unique(where={"id": chat_id})
    if not chat or chat.userId != user_id:
        raise HTTPException(status_code=404, detail="Chat not found")

    file_path = None
    if file:
        storage_dir = os.path.join(os.getcwd(), "storage", user_id)
        os.makedirs(storage_dir, exist_ok=True)

        ext = os.path.splitext(file.filename)[1] if file.filename else ""
        filename = f"{uuid.uuid4()}{ext}"
        abs_path = os.path.join(storage_dir, filename)
        with open(abs_path, "wb") as f:
            f.write(await file.read())

        file_path = abs_path

    await db.message.create(
        data={
            "chatId": chat_id,
            "content": content,
            "image": file_path,
            "role": "user",
        }
    )

    history = await db.message.find_many(
        where={"chatId": chat_id}, order={"createdAt": "asc"}
    )

    llm_messages = [
        {"role": m.role, "content": m.content, "image": m.image} for m in history
    ]

    assistant_content = await generate_response(llm_messages)

    assistant_msg = await db.message.create(
        data={
            "chatId": chat_id,
            "content": assistant_content,
            "role": "assistant",
        }
    )

    return assistant_msg
