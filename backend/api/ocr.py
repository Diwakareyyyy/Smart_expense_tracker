from fastapi import APIRouter, UploadFile, File, Body
from services.ocr_service import extract_text_from_image, parse_receipt_text_ai

router = APIRouter(prefix="/api/ocr", tags=["ocr"])

@router.post("/scan-receipt")
async def scan_receipt(file: UploadFile = File(...)):
    content = await file.read()
    text = extract_text_from_image(content)
    return {"extracted_text": text}

@router.post("/parse-text")
def parse_text(data: dict = Body(...)):
    text = data.get("text", "")
    return parse_receipt_text_ai(text)

