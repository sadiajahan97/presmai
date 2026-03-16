import re

from prisma import Prisma


ALTERNATIVES_PATTERNS = [
    re.compile(
        r"alternatives?\s+(?:\w+\s+)*?(?:to|for)\s+(.+?)(?:\?|$)",
        re.IGNORECASE,
    ),
    re.compile(
        r"(?:what(?:'s| is| are)|any)\s+alternative(s?)\s+(?:\w+\s+)*?(?:to|for)\s+(.+?)(?:\?|$)",
        re.IGNORECASE,
    ),
    re.compile(
        r"substitute(s?)\s+(?:\w+\s+)*?for\s+(.+?)(?:\?|$)",
        re.IGNORECASE,
    ),
    re.compile(
        r"replace(ment)?\s+(?:\w+\s+)*?(?:for\s+)?(.+?)(?:\?|$)",
        re.IGNORECASE,
    ),
    re.compile(
        r"same\s+(?:as|ingredient\s+as)\s+(.+?)(?:\?|$)",
        re.IGNORECASE,
    ),
]


def extract_alternatives_brand(text: str | None) -> str | None:
    if not text or not text.strip():
        return None
    t = text.strip()
    for pat in ALTERNATIVES_PATTERNS:
        m = pat.search(t)
        if m:
            brand = m.group(m.lastindex).strip()
            if brand and len(brand) >= 2:
                return brand
    return None


async def get_alternatives_by_brand(
    db: Prisma, brand_name: str, max_results: int = 10
) -> dict | None:
    brand_clean = brand_name.strip()
    if not brand_clean:
        return None

    candidates = await db.medicine.find_many(
        where={"name": {"equals": brand_clean, "mode": "insensitive"}}, take=1
    )
    match = candidates[0] if candidates else None

    if not match or not match.ingredient:
        return None

    ingredient = match.ingredient.strip()
    if not ingredient:
        return None

    others = await db.medicine.find_many(
        where={
            "ingredient": {"equals": ingredient},
            "name": {"not": match.name},
        },
        take=max_results,
    )

    alternatives = [
        {
            "name": m.name,
            "ingredient": m.ingredient,
            "type": m.type,
            "strength": m.strength,
            "company": m.company,
            "unit": m.unit,
            "price": m.price,
            "majorPoints": m.majorPoints,
        }
        for m in others
    ]
    return {"ingredient": ingredient, "alternatives": alternatives}


def format_alternatives_context(brand_name: str, alternatives: list[dict], original_ingredient: str) -> str:
    if not alternatives:
        return (
            f"The user asked for alternatives to '{brand_name}'. "
            f"That brand uses the ingredient: {original_ingredient}. "
            "No other brands with the same ingredient were found in the database."
        )
    lines = [
        f"The user asked for alternatives to '{brand_name}' (ingredient: {original_ingredient}).",
        "The following medicines in the database have the same ingredient and can be considered alternatives:",
        "",
    ]
    for i, alt in enumerate(alternatives, 1):
        block = [f"--- Alternative {i}: {alt.get('name') or 'Unknown'} ---"]
        if alt.get("ingredient"):
            block.append(f"Ingredient: {alt['ingredient']}")
        if alt.get("type"):
            block.append(f"Type: {alt['type']}")
        if alt.get("strength"):
            block.append(f"Strength: {alt['strength']}")
        if alt.get("company"):
            block.append(f"Company: {alt['company']}")
        if alt.get("price") is not None:
            block.append(f"Price (BDT): {alt['price']}")
        if alt.get("majorPoints"):
            mp = alt["majorPoints"]
            block.append(f"Details: {mp[:500]}..." if len(mp) > 500 else f"Details: {mp}")
        lines.append("\n".join(block))
        lines.append("")
    return "\n".join(lines).strip()
