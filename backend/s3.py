from __future__ import annotations

import os

import boto3
from botocore.config import Config
from dotenv import load_dotenv

load_dotenv()

AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
AWS_BUCKET_NAME = os.getenv("AWS_BUCKET_NAME")
AWS_ENDPOINT_URL = os.getenv("AWS_ENDPOINT_URL")
AWS_REGION = os.getenv("AWS_REGION")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")

missing = [
    name
    for name, value in {
        "AWS_ACCESS_KEY_ID": AWS_ACCESS_KEY_ID,
        "AWS_BUCKET_NAME": AWS_BUCKET_NAME,
        "AWS_ENDPOINT_URL": AWS_ENDPOINT_URL,
        "AWS_REGION": AWS_REGION,
        "AWS_SECRET_ACCESS_KEY": AWS_SECRET_ACCESS_KEY,
    }.items()
    if not value
]
if missing:
    raise SystemExit(f"Missing required env vars in backend/.env: {', '.join(missing)}")

_s3_client = None


def get_s3_client():
    global _s3_client
    if _s3_client is None:
        _s3_client = boto3.client(
            "s3",
            aws_access_key_id=AWS_ACCESS_KEY_ID,
            aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
            endpoint_url=AWS_ENDPOINT_URL,
            region_name=AWS_REGION,
            config=Config(
                signature_version="s3v4",
                s3={"addressing_style": "path"},
            ),
        )
    return _s3_client


s3_client = get_s3_client()