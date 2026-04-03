import os
import tempfile
import uuid
from datetime import datetime
from typing import List

from fastapi import APIRouter, Depends, HTTPException, UploadFile
from pydantic import BaseModel
from prisma import Prisma

from auth import verify_access_token
from db import get_db
from llm import generate_medication_routine
from s3 import AWS_BUCKET_NAME, s3_client

router = APIRouter(prefix="/prescriptions", tags=["prescriptions"])


class MedicationRoutineResponse(BaseModel):
    id: str
    name: str
    strength: str | None
    morning: bool
    afternoon: bool
    night: bool
    days: int
    userId: str
    createdAt: datetime
    updatedAt: datetime

    class Config:
        from_attributes = True


class ScanPrescriptionResponse(BaseModel):
    medications: List[MedicationRoutineResponse]
    created_count: int


class UpdateMedicationRequest(BaseModel):
    name: str
    strength: str | None
    morning: bool
    afternoon: bool
    night: bool
    days: int


@router.post("/scan", response_model=ScanPrescriptionResponse)
async def scan_prescription(
    file: UploadFile | None = None,
    user_id: str = Depends(verify_access_token),
    db: Prisma = Depends(get_db),
):
    if not file:
        raise HTTPException(status_code=400, detail="File is required")

    original_filename = file.filename if file.filename else "unknown"
    filename = f"{uuid.uuid4()}_{original_filename}"
    bytes_data = await file.read()

    routine = await generate_medication_routine(bytes_data, original_filename)

    s3_key = f"{user_id}/{filename}"
    s3_client.put_object(Bucket=AWS_BUCKET_NAME, Key=s3_key, Body=bytes_data)
    medications = routine.get("medications", [])
    if not isinstance(medications, list):
        medications = []

    created_meds = []
    for med in medications:
        if not isinstance(med, dict):
            continue

        name = med.get("name")
        if not isinstance(name, str) or not name.strip():
            continue

        days_raw = med.get("days")
        if days_raw is None:
            days = 0
        elif isinstance(days_raw, int):
            days = days_raw
        elif isinstance(days_raw, float):
            days = int(days_raw)
        elif isinstance(days_raw, str):
            try:
                days = int(days_raw.strip())
            except ValueError:
                days = 0
        else:
            days = 0

        created = await db.medication.create(
            data={
                "name": name.strip(),
                "strength": med.get("strength"),
                "morning": bool(med.get("morning", False)),
                "afternoon": bool(med.get("afternoon", False)),
                "night": bool(med.get("night", False)),
                "days": days,
                "userId": user_id,
            }
        )
        created_meds.append(created)

    return ScanPrescriptionResponse(
        medications=created_meds,
        created_count=len(created_meds),
    )


@router.put("/medications/{medication_id}", response_model=MedicationRoutineResponse)
async def update_medication(
    medication_id: str,
    body: UpdateMedicationRequest,
    user_id: str = Depends(verify_access_token),
    db: Prisma = Depends(get_db),
):
    medication = await db.medication.find_unique(where={"id": medication_id})
    if not medication or medication.userId != user_id:
        raise HTTPException(status_code=404, detail="Medication not found")

    name = body.name.strip()
    if not name:
        raise HTTPException(status_code=400, detail="Medication name is required")

    strength = body.strength.strip() if body.strength else None
    if strength == "":
        strength = None

    if body.days < 0:
        raise HTTPException(status_code=400, detail="Days must be greater than or equal to 0")

    updated = await db.medication.update(
        where={"id": medication_id},
        data={
            "name": name,
            "strength": strength,
            "morning": bool(body.morning),
            "afternoon": bool(body.afternoon),
            "night": bool(body.night),
            "days": int(body.days),
            "userId": user_id,
        },
    )

    return updated


@router.get("/medications", response_model=List[MedicationRoutineResponse])
async def get_medications(
    user_id: str = Depends(verify_access_token),
    db: Prisma = Depends(get_db),
):
    medications = await db.medication.find_many(
        where={"userId": user_id},
        order={"createdAt": "desc"},
    )
    return medications


@router.delete("/medications/{medication_id}")
async def delete_medication(
    medication_id: str,
    user_id: str = Depends(verify_access_token),
    db: Prisma = Depends(get_db),
):
    medication = await db.medication.find_unique(where={"id": medication_id})
    if not medication or medication.userId != user_id:
        raise HTTPException(status_code=404, detail="Medication not found")

    await db.medication.delete(where={"id": medication_id})
    return {"success": True}
