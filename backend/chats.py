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
from vector_db import query_medications

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
    file_path: str | None
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
    for m in messages:
        if m.file_path and not m.file_path.startswith("/"):
            m.file_path = f"/{m.file_path}"
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

        original_filename = file.filename if file.filename else "unknown"
        filename = f"{uuid.uuid4()}_{original_filename}"
        rel_path = f"storage/{user_id}/{filename}"
        abs_path = os.path.join(os.getcwd(), rel_path)
        with open(abs_path, "wb") as f:
            f.write(await file.read())

        file_path = rel_path

    await db.message.create(
        data={
            "chatId": chat_id,
            "content": content,
            "file_path": file_path,
            "role": "user",
        }
    )

    history = await db.message.find_many(
        where={"chatId": chat_id}, order={"createdAt": "asc"}
    )

    llm_messages = [
        {"role": m.role, "content": m.content, "file_path": m.file_path} for m in history
    ]

    medication_context = None
    if content:
        med_results = query_medications(content, n_results=10)
        if med_results:
            context_parts = []
            for i, (doc, meta) in enumerate(med_results, 1):
                context_parts.append(f"--- Medication {i} ---\n{doc}")
            medication_context = "\n\n".join(context_parts)
    print(medication_context)
    assistant_response = await generate_response(llm_messages, medication_context=medication_context)

    assistant_content = assistant_response.get("answer", "")
    medications = assistant_response.get("medications", [])

    for med in medications:
        await db.medication.create(
            data={
                "name": med.get("name", ""),
                "strength": med.get("strength"),
                "morning": med.get("morning", False),
                "afternoon": med.get("afternoon", False),
                "night": med.get("night", False),
                "days": med.get("days", 0),
                "userId": user_id,
            }
        )

    assistant_msg = await db.message.create(
        data={
            "chatId": chat_id,
            "content": assistant_content,
            "role": "assistant",
        }
    )

    return assistant_msg
