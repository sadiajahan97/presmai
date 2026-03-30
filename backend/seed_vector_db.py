import ast
import os
import time
import uuid

from dotenv import load_dotenv
from qdrant_client.models import PointStruct
from tqdm import tqdm

load_dotenv()

from meds_data import MEDS_DATA
from vector_db import (
    COLLECTION_MEDICATIONS,
    encode_document_text,
    init_qdrant,
    reset_medications_collection,
)


def _upsert_batch(client, points_batch, max_attempts: int = 6) -> None:
    for attempt in range(max_attempts):
        try:
            client.upsert(
                collection_name=COLLECTION_MEDICATIONS,
                points=points_batch,
                wait=True,
            )
            return
        except Exception as e:
            msg = str(e).lower()
            if attempt < max_attempts - 1 and (
                "timeout" in msg or "timed out" in msg or "write" in msg
            ):
                time.sleep(min(2**attempt, 60))
                continue
            raise


def parse_major_points(points_str):
    if not points_str or not isinstance(points_str, str):
        return {}
    try:
        return ast.literal_eval(points_str)
    except (ValueError, SyntaxError):
        return {}


def prepare_document(med):
    name = med.get("Name", "")
    ingredient = med.get("Ingredient", "")
    m_type = med.get("Type", "")
    company = med.get("Company", "")
    strength = med.get("Strength", "") or ""
    unit = med.get("Unit", "")
    price = med.get("Price", "")

    major_points = parse_major_points(med.get("Major_Points", ""))
    indications = major_points.get("Indications", "")
    pharmacology = major_points.get("Pharmacology", "")
    side_effects = major_points.get("Side Effects", "")

    doc_parts = [
        f"Name: {name}",
        f"Type: {m_type}",
        f"Ingredient: {ingredient}",
        f"Strength: {strength}",
        f"Company: {company}",
        f"Unit: {unit}",
        f"Price: {price}",
        f"Indications: {indications}",
        f"Pharmacology: {pharmacology}",
        f"Side Effects: {side_effects}",
    ]

    return " \n".join([p for p in doc_parts if p.split(": ")[1].strip()])


def seed_db():
    print(f"Loading {len(MEDS_DATA)} medications...")
    client = init_qdrant()
    print(f"Clearing Qdrant collection {COLLECTION_MEDICATIONS!r}...")
    reset_medications_collection(client)

    try:
        batch_size = max(1, int(os.environ.get("SEED_BATCH_SIZE", "32")))
    except ValueError:
        batch_size = 32

    points_batch = []

    print("Preparing and upserting data in batches...")
    for med in tqdm(MEDS_DATA):
        doc = prepare_document(med)
        vector = encode_document_text(doc)
        if not vector:
            continue

        metadata = {
            "name": str(med.get("Name", "")),
            "type": str(med.get("Type", "")),
            "ingredient": str(med.get("Ingredient", "")),
            "strength": str(med.get("Strength", "") or ""),
            "company": str(med.get("Company", "")),
            "unit": str(med.get("Unit", "")),
            "price": float(med.get("Price", 0.0)),
            "link": str(med.get("Link", "")),
        }
        payload = {"text": doc, **metadata}

        points_batch.append(
            PointStruct(id=str(uuid.uuid4()), vector=vector, payload=payload)
        )

        if len(points_batch) >= batch_size:
            _upsert_batch(client, points_batch)
            points_batch = []

    if points_batch:
        _upsert_batch(client, points_batch)

    print(f"\nSuccessfully seeded medications into Qdrant collection {COLLECTION_MEDICATIONS!r}.")


if __name__ == "__main__":
    seed_db()
