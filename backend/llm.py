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
    "identifying possible drug interactions based on provided information or prescription images. "
    "\n\nCRITICAL SAFETY RULES:\n"
    "1. Always include a disclaimer: 'I am an AI, not a doctor. This information is for educational purposes only. Always consult a healthcare professional before making medical decisions.'\n"
    "2. If you cannot identify a medication or find conflicting information, clearly state it and advise seeing a pharmacist or doctor.\n"
    "3. Use a professional, supportive, and clear tone.",
)


async def generate_response(messages: list[dict]):
    contents = []
    for m in messages:
        parts = []
        if m.get("content"):
            parts.append(types.Part(text=m["content"]))

        if m.get("image"):
            image_path = Path(m["image"])
            if image_path.exists():
                mime_type, _ = mimetypes.guess_type(image_path)
                if not mime_type:
                    mime_type = (
                        "application/pdf"
                        if image_path.suffix.lower() == ".pdf"
                        else "image/jpeg"
                    )
                data = image_path.read_bytes()
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
    return response.text
