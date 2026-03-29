import os
import uuid
import shutil
from typing import List
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Query
from pydantic import BaseModel
from datetime import datetime

from auth import verify_access_token

router = APIRouter(prefix="/storage", tags=["storage"])

class FileInfo(BaseModel):
    name: str
    path: str
    size: int
    modified_at: datetime
    is_dir: bool

class CreateFolderRequest(BaseModel):
    name: str

@router.get("/", response_model=List[FileInfo])
async def list_files(folder: str = "", user_id: str = Depends(verify_access_token)):
    base_dir = os.path.join(os.getcwd(), "storage", user_id)
    target_dir = os.path.abspath(os.path.join(base_dir, folder))
    
    if not target_dir.startswith(os.path.abspath(base_dir)):
        raise HTTPException(status_code=403, detail="Access denied")
    
    if not os.path.exists(target_dir):
        os.makedirs(target_dir, exist_ok=True)
        return []

    files = []
    for item in os.listdir(target_dir):
        if item.startswith("."):
            continue
            
        item_path = os.path.join(target_dir, item)
        stats = os.stat(item_path)
        
        rel_to_user = os.path.relpath(item_path, base_dir)
        app_path = f"storage/{user_id}/{rel_to_user}"
        
        files.append(FileInfo(
            name=item,
            path=app_path,
            size=stats.st_size if os.path.isfile(item_path) else 0,
            modified_at=datetime.fromtimestamp(stats.st_mtime),
            is_dir=os.path.isdir(item_path)
        ))
    
    files.sort(key=lambda x: (not x.is_dir, x.modified_at), reverse=True)
    return files

@router.post("/folder")
async def create_folder(
    body: CreateFolderRequest,
    folder: str = "",
    user_id: str = Depends(verify_access_token)
):
    base_dir = os.path.join(os.getcwd(), "storage", user_id)
    target_parent = os.path.abspath(os.path.join(base_dir, folder))
    
    if not target_parent.startswith(os.path.abspath(base_dir)):
        raise HTTPException(status_code=403, detail="Access denied")
        
    folder_path = os.path.join(target_parent, body.name)
    
    if os.path.exists(folder_path):
        raise HTTPException(status_code=409, detail="Folder already exists")
        
    os.makedirs(folder_path, exist_ok=True)
    return {"message": "Folder created successfully"}

@router.post("/file")
async def upload_file(
    folder: str = "",
    file: UploadFile = File(...),
    user_id: str = Depends(verify_access_token)
):
    base_dir = os.path.join(os.getcwd(), "storage", user_id)
    target_dir = os.path.abspath(os.path.join(base_dir, folder))
    
    if not target_dir.startswith(os.path.abspath(base_dir)):
        raise HTTPException(status_code=403, detail="Access denied")
        
    os.makedirs(target_dir, exist_ok=True)
    
    unique_filename = f"{uuid.uuid4()}_{file.filename}"
    file_path = os.path.join(target_dir, unique_filename)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    return {"message": "File uploaded successfully", "filename": unique_filename}


@router.delete("/")
async def delete_storage_item(
    rel_path: str = Query(..., alias="path", min_length=1, description="Path relative to user storage root"),
    user_id: str = Depends(verify_access_token),
):
    base_dir = os.path.join(os.getcwd(), "storage", user_id)
    base_abs = os.path.abspath(base_dir)
    target = os.path.abspath(os.path.join(base_dir, rel_path))

    if not target.startswith(base_abs):
        raise HTTPException(status_code=403, detail="Access denied")

    if target == base_abs or target.rstrip(os.sep) == base_abs.rstrip(os.sep):
        raise HTTPException(status_code=400, detail="Cannot delete storage root")

    if not os.path.lexists(target):
        raise HTTPException(status_code=404, detail="Not found")

    if os.path.isdir(target):
        shutil.rmtree(target)
    else:
        os.remove(target)

    return {"message": "Deleted successfully"}
