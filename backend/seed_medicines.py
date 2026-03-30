import asyncio
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dotenv import load_dotenv

load_dotenv()

from prisma import Prisma


def row_to_medicine(record: dict) -> dict:
    raw_price = record.get("Price")
    return {
        "name": record.get("Name"),
        "type": record.get("Type"),
        "ingredient": record.get("Ingredient"),
        "company": record.get("Company"),
        "unit": record.get("Unit"),
        "price": float(raw_price) if raw_price is not None else None,
        "majorPoints": record.get("Major_Points"),
        "link": record.get("Link"),
        "strength": record.get("Strength"),
    }


async def main() -> None:
    from meds_data import MEDS_DATA

    prisma = Prisma()
    await prisma.connect()

    try:
        batch_size = 500
        total = len(MEDS_DATA)
        created = 0

        for i in range(0, total, batch_size):
            chunk = MEDS_DATA[i : i + batch_size]
            data = [row_to_medicine(r) for r in chunk]
            await prisma.medicine.create_many(data=data, skip_duplicates=True)
            created += len(data)
            print(f"Inserted {created}/{total} medicines ...")

        print(f"Done. Inserted {created} medicines.")
    finally:
        await prisma.disconnect()


if __name__ == "__main__":
    asyncio.run(main())
