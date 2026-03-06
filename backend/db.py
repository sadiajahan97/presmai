from prisma import Prisma

_db: Prisma | None = None


def set_db(db: Prisma) -> None:
    global _db
    _db = db


def get_db() -> Prisma:
    if _db is None:
        raise RuntimeError("Prisma not connected")
    return _db
