import json
import re
from google import genai
from google.genai import types
from dotenv import load_dotenv

load_dotenv()

client = genai.Client()

grounding_tool = types.Tool(
    google_search=types.GoogleSearch()
)

import mimetypes
from pathlib import Path

config = types.GenerateContentConfig(
    tools=[grounding_tool],
    system_instruction="You are PresMAI, a specialized AI assistant designed to help users manage and understand their medical prescriptions. "
    "Your primary tasks include explaining medication uses, dosage instructions, potential side effects, and "
    "identifying possible drug interactions based on provided information or prescription images or pdf files. "
    "\n\nRESPONSE FORMAT:\n"
    "You MUST always respond with a valid JSON object and nothing else. No extra text, no markdown fences. The JSON must contain exactly two fields:\n"
    '1. "answer": Your text response to the user. If you use the Google Search grounding tool, include all citations and references WITHIN this text.\n'
    '2. "medications": An array of medication objects. Each object has: "name" (string), "strength" (string or null), '
    '"morning" (boolean), "afternoon" (boolean), "night" (boolean), "days" (integer).\n'
    "If no medications are being prescribed or discussed in a prescription context, return an empty array for medications.\n"
    "\nExample response:\n"
    '{"answer": "Napa 500mg is a paracetamol-based medication...", "medications": [{"name": "Napa", "strength": "500mg", "morning": true, "afternoon": false, "night": true, "days": 5}]}\n'
    "\nDOSAGE FORMAT UNDERSTANDING:\n"
    "Doctors commonly use the format '1-0-1' or '1+0+1' to indicate dosage schedules. "
    "The three positions represent: morning - afternoon - night. "
    "1 means take the medicine at that time, 0 means skip. For example:\n"
    "- '1-0-1' or '1+0+1' means: morning=true, afternoon=false, night=true\n"
    "- '1-1-1' or '1+1+1' means: morning=true, afternoon=true, night=true\n"
    "- '0-0-1' or '0+0+1' means: morning=false, afternoon=false, night=true\n"
    "- '1-1-0' means: morning=true, afternoon=true, night=false\n"
    "When extracting medication schedules, convert this format into the boolean fields accordingly.\n"
    "\nMEDICATION DATABASE CONTEXT:\n"
    "When medication context from the database is provided at the start of the conversation, PRIORITIZE that information "
    "when answering questions about those medications. Use the provided details (name, type, ingredient, strength, "
    "company, unit, price in BDT, indications, pharmacology, side effects) to give accurate, specific answers. "
    "You may supplement with general medical knowledge or web search, but the database is your primary source.\n"
    "\nCRITICAL SAFETY RULES:\n"
    "1. Always include a disclaimer: 'I am an AI, not a doctor. This information is for educational purposes only. Always consult a healthcare professional before making medical decisions.'\n"
    "2. If you cannot identify a medication or find conflicting information, clearly state it and advise seeing a pharmacist or doctor.\n"
    "3. Use a professional, supportive, and clear tone.",
)


def parse_llm_json(text: str) -> dict:
    text = text.strip()
    fence_match = re.search(r"```(?:json)?\s*([\s\S]*?)```", text)
    if fence_match:
        text = fence_match.group(1).strip()
    try:
        return json.loads(text)
    except (json.JSONDecodeError, TypeError):
        return {"answer": text, "medications": []}


async def generate_response(messages: list[dict], medication_context: str | None = None):
    contents = []

    if medication_context:
        contents.append(
            types.Content(
                role="user",
                parts=[types.Part(text=f"[MEDICATION DATABASE CONTEXT]\n{medication_context}\n[END CONTEXT]")],
            )
        )
        contents.append(
            types.Content(
                role="model",
                parts=[types.Part(text='{"answer": "Thank you. I have noted the medication information from the database. I will use it to answer your questions.", "medications": []}')],
            )
        )

    for m in messages:
        parts = []
        content_text = m.get("content")

        if content_text:
            if m["role"] != "user":
                content_text = json.dumps({"answer": content_text, "medications": []})
            parts.append(types.Part(text=content_text))

        if m.get("file_path"):
            file_path = Path(m["file_path"])
            if file_path.exists():
                mime_type, _ = mimetypes.guess_type(file_path)
                if not mime_type:
                    mime_type = (
                        "application/pdf"
                        if file_path.suffix.lower() == ".pdf"
                        else "image/jpeg"
                    )
                data = file_path.read_bytes()
                parts.append(
                    types.Part(inline_data=types.Blob(mime_type=mime_type, data=data))
                )

        if not parts:
            continue

        contents.append(
            types.Content(
                role="user" if m["role"] == "user" else "model",
                parts=parts,
            )
        )

    response = client.models.generate_content(
        model="gemini-2.5-flash", contents=contents, config=config
    )

    return parse_llm_json(response.text)
