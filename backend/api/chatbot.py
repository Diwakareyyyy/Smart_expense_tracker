from fastapi import APIRouter
from pydantic import BaseModel
from services.chatbot_service import get_expense_advice

router = APIRouter(prefix="/api/chatbot", tags=["chatbot"])

class ChatRequest(BaseModel):
    message: str
    transactions: str = ""

@router.post("/ask")
def ask_chatbot(request: ChatRequest):
    response, usage = get_expense_advice(request.message, request.transactions)
    result = {"reply": response}
    if usage:
        result["usage"] = usage
    return result
