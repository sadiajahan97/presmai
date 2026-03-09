import asyncio
import logging
from datetime import datetime, time, timedelta

from firebase_admin import messaging

from db import get_db

logger = logging.getLogger(__name__)


async def _send_push_notification(user_id: str, content: str) -> None:
    db = get_db()
    user = await db.user.find_unique(where={"id": user_id})
    if not user or not user.fcmToken:
        logger.info("Skipping push notification for user %s: no FCM token", user_id)
        return

    message = messaging.Message(
        notification=messaging.Notification(
            title="Medicine Reminder 💊",
            body=content,
        ),
        token=user.fcmToken,
    )

    try:
        response = messaging.send(message)
        logger.info("Push notification sent for user %s (response: %s)", user_id, response)
    except Exception:
        logger.exception("Failed to send push notification to user %s", user_id)

SCHEDULE = [
    time(0, 0),
    time(8, 0),
    time(16, 0),
    time(20, 0),
]


def _build_message(med_name: str, strength: str | None, slot: str) -> str:
    strength_part = f" ({strength})" if strength else ""
    return (
        f"💊 Time for your {slot} medicine! "
        f"Please take {med_name}{strength_part}. "
        f"Stay healthy! 🌟"
    )


def _times_per_day(med) -> int:
    return sum([med.morning, med.afternoon, med.night])


def _seconds_until(target: time) -> float:
    now = datetime.now()
    target_dt = now.replace(hour=target.hour, minute=target.minute, second=0, microsecond=0)
    if target_dt <= now:
        target_dt += timedelta(days=1)
    return (target_dt - now).total_seconds()


def _next_scheduled_time() -> time:
    now = datetime.now().time()
    for t in SCHEDULE:
        if t > now:
            return t
    return SCHEDULE[0]


async def _create_notification(user_id: str, content: str) -> None:
    db = get_db()
    await db.notification.create(
        data={
            "content": content,
            "userId": user_id,
        }
    )
    await _send_push_notification(user_id, content)


async def _process_morning() -> None:
    db = get_db()
    meds = await db.medication.find_many(
        where={"days": {"gt": 0}, "morning": True},
    )
    for med in meds:
        content = _build_message(med.name, med.strength, "morning")
        await _create_notification(med.userId, content)
        logger.info("Morning notification created for %s (med: %s)", med.userId, med.name)


async def _process_afternoon() -> None:
    db = get_db()
    meds = await db.medication.find_many(
        where={"days": {"gt": 0}, "afternoon": True},
    )
    for med in meds:
        content = _build_message(med.name, med.strength, "afternoon")
        await _create_notification(med.userId, content)
        logger.info("Afternoon notification created for %s (med: %s)", med.userId, med.name)


async def _process_night_8pm() -> None:
    db = get_db()
    meds = await db.medication.find_many(
        where={"days": {"gt": 0}, "night": True},
    )
    for med in meds:
        if _times_per_day(med) <= 2:
            content = _build_message(med.name, med.strength, "night")
            await _create_notification(med.userId, content)
            logger.info("Night (8 PM) notification created for %s (med: %s)", med.userId, med.name)

            await db.medication.update(
                where={"id": med.id},
                data={"days": {"decrement": 1}},
            )
            logger.info("Decremented days for medication %s (remaining: %d)", med.name, med.days - 1)


async def _process_night_12am() -> None:
    db = get_db()
    meds = await db.medication.find_many(
        where={"days": {"gt": 0}, "night": True},
    )
    for med in meds:
        if _times_per_day(med) >= 3:
            content = _build_message(med.name, med.strength, "night")
            await _create_notification(med.userId, content)
            logger.info("Night (12 AM) notification created for %s (med: %s)", med.userId, med.name)

            await db.medication.update(
                where={"id": med.id},
                data={"days": {"decrement": 1}},
            )
            logger.info("Decremented days for medication %s (remaining: %d)", med.name, med.days - 1)


_HANDLERS = {
    time(8, 0): _process_morning,
    time(16, 0): _process_afternoon,
    time(20, 0): _process_night_8pm,
    time(0, 0): _process_night_12am,
}


async def notification_loop() -> None:
    logger.info("Medicine notification background task started.")
    while True:
        target = _next_scheduled_time()
        wait = _seconds_until(target)
        logger.info("Next notification run at %s (in %.0f seconds)", target, wait)
        await asyncio.sleep(wait)

        handler = _HANDLERS[target]
        try:
            await handler()
        except Exception:
            logger.exception("Error processing medication notifications at %s", target)
