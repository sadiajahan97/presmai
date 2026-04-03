import uuid
from datetime import datetime
from typing import List

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
from pydantic import BaseModel

from auth import verify_access_token
from s3 import AWS_BUCKET_NAME, s3_client

router = APIRouter(prefix="/storage", tags=["storage"])


class FileInfo(BaseModel):
    name: str
    path: str
    size: int
    modified_at: datetime
    is_dir: bool


class CreateFolderRequest(BaseModel):
    name: str


def _normalize_rel_path(rel_path: str) -> str:
    rel_path = (rel_path or "").strip()
    rel_path = rel_path.strip("/")
    if rel_path in {"", "."}:
        return ""
    parts = [p for p in rel_path.split("/") if p]
    if any(p in {".", ".."} for p in parts):
        raise HTTPException(status_code=403, detail="Access denied")
    return "/".join(parts)


def _user_prefix(user_id: str, folder: str) -> str:
    folder_rel = _normalize_rel_path(folder)
    if folder_rel:
        return f"{user_id}/{folder_rel}/"
    return f"{user_id}/"


def _user_rel_path(user_id: str, folder: str, child_name: str) -> str:
    folder_rel = _normalize_rel_path(folder)
    if folder_rel:
        return f"{folder_rel}/{child_name}"
    return child_name


def _to_naive_datetime(dt: datetime) -> datetime:
    return datetime.fromtimestamp(dt.timestamp())


@router.get("/", response_model=List[FileInfo])
async def list_files(folder: str = "", user_id: str = Depends(verify_access_token)):
    prefix = _user_prefix(user_id=user_id, folder=folder)

    paginator = s3_client.get_paginator("list_objects_v2")
    files: list[FileInfo] = []

    for page in paginator.paginate(Bucket=AWS_BUCKET_NAME, Prefix=prefix):
        for obj in page.get("Contents", []) or []:
            key = obj["Key"]
            if not key.startswith(prefix):
                continue

            rel_key = key[len(prefix) :]
            if not rel_key:
                continue

            is_dir = rel_key.endswith("/") and "/" not in rel_key[:-1]
            if is_dir:
                child_name = rel_key[:-1]
                rel_to_user = _user_rel_path(user_id=user_id, folder=folder, child_name=child_name)
                app_path = f"{user_id}/{rel_to_user}"
                files.append(
                    FileInfo(
                        name=child_name,
                        path=app_path,
                        size=0,
                        modified_at=_to_naive_datetime(obj["LastModified"]),
                        is_dir=True,
                    )
                )
                continue

            if "/" in rel_key:
                continue

            child_name = rel_key
            rel_to_user = _user_rel_path(user_id=user_id, folder=folder, child_name=child_name)
            app_path = f"{user_id}/{rel_to_user}"
            files.append(
                FileInfo(
                    name=child_name,
                    path=app_path,
                    size=int(obj.get("Size", 0)),
                    modified_at=_to_naive_datetime(obj["LastModified"]),
                    is_dir=False,
                )
            )

    files.sort(key=lambda x: (not x.is_dir, x.modified_at), reverse=True)
    return files


@router.post("/folder")
async def create_folder(
    body: CreateFolderRequest,
    folder: str = "",
    user_id: str = Depends(verify_access_token),
):
    name = (body.name or "").strip().strip("/")
    if not name or "/" in name:
        raise HTTPException(status_code=400, detail="Invalid folder name")
    if name in {".", ".."}:
        raise HTTPException(status_code=403, detail="Access denied")

    parent_prefix = _user_prefix(user_id=user_id, folder=folder)
    dir_key = f"{parent_prefix}{name}/"

    resp = s3_client.list_objects_v2(Bucket=AWS_BUCKET_NAME, Prefix=dir_key, MaxKeys=1)
    if (resp.get("KeyCount") or 0) > 0:
        raise HTTPException(status_code=409, detail="Folder already exists")

    s3_client.put_object(Bucket=AWS_BUCKET_NAME, Key=dir_key, Body=b"")
    return {"message": "Folder created successfully"}


@router.post("/file")
async def upload_file(
    folder: str = "",
    file: UploadFile = File(...),
    user_id: str = Depends(verify_access_token),
):
    folder_rel = _normalize_rel_path(folder)

    unique_filename = f"{uuid.uuid4()}_{file.filename}"
    if folder_rel:
        key = f"{user_id}/{folder_rel}/{unique_filename}"
    else:
        key = f"{user_id}/{unique_filename}"

    file.file.seek(0)
    s3_client.upload_fileobj(file.file, Bucket=AWS_BUCKET_NAME, Key=key)

    return {"message": "File uploaded successfully", "filename": unique_filename}


def _delete_objects_by_prefix(prefix: str) -> None:
    paginator = s3_client.get_paginator("list_objects_v2")
    to_delete: list[dict] = []

    for page in paginator.paginate(Bucket=AWS_BUCKET_NAME, Prefix=prefix):
        for obj in page.get("Contents", []) or []:
            to_delete.append({"Key": obj["Key"]})
            if len(to_delete) >= 1000:
                s3_client.delete_objects(Bucket=AWS_BUCKET_NAME, Delete={"Objects": to_delete})
                to_delete = []

    if to_delete:
        s3_client.delete_objects(Bucket=AWS_BUCKET_NAME, Delete={"Objects": to_delete})


@router.delete("/")
async def delete_storage_item(
    rel_path: str = Query(
        ...,
        alias="path",
        min_length=1,
        description="Path relative to user storage root",
    ),
    user_id: str = Depends(verify_access_token),
):
    rel_path_norm = _normalize_rel_path(rel_path)
    if not rel_path_norm:
        raise HTTPException(status_code=400, detail="Cannot delete storage root")

    if rel_path_norm.startswith(f"{user_id}/"):
        rel_path_norm = rel_path_norm[len(user_id) + 1 :]
    elif rel_path_norm == user_id:
        raise HTTPException(status_code=400, detail="Cannot delete storage root")

    base_prefix = f"{user_id}/"
    file_key = f"{base_prefix}{rel_path_norm}"
    dir_prefix = f"{file_key}/"

    from botocore.exceptions import ClientError

    resp = s3_client.list_objects_v2(Bucket=AWS_BUCKET_NAME, Prefix=dir_prefix, MaxKeys=1)
    if (resp.get("KeyCount") or 0) > 0:
        _delete_objects_by_prefix(dir_prefix)
        return {"message": "Deleted successfully"}

    try:
        s3_client.head_object(Bucket=AWS_BUCKET_NAME, Key=file_key)
    except ClientError as e:
        code = str(e.response.get("Error", {}).get("Code", ""))
        status = e.response.get("ResponseMetadata", {}).get("HTTPStatusCode")
        if status == 404 or code in {"404", "NoSuchKey", "NotFound"}:
            raise HTTPException(status_code=404, detail="Not found")
        raise

    s3_client.delete_object(Bucket=AWS_BUCKET_NAME, Key=file_key)
    return {"message": "Deleted successfully"}
