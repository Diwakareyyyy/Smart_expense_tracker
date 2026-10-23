import os
from groq import Groq
from fastapi import HTTPException, status
from core.config import get_settings
from core.logger import logger

settings = get_settings()

def get_category_system_prompt() -> str:
    return """You are a category classification engine for an expense tracker.
Your input will be text extracted from a receipt using OCR.
Your task is to classify the receipt into EXACTLY ONE of the following categories:
Food, Fuel, Shopping, Medical, Recharge, Bills, Entertainment, Travel, Education, Salary, Investment, Rent, Groceries, Insurance, Others.

Rules:
- If the receipt says Petrol, Diesel, Indian Oil, HP, Bharat Petroleum, return Fuel.
- If the receipt says Swiggy, Zomato, Restaurant, Cafe, Food, return Food.
- If the receipt says Apollo, Hospital, Clinic, Medicine, return Medical.
- DO NOT return any explanation.
- ONLY return the category name."""

def categorize_text(text: str) -> str:
    """Categorize text using the Groq API strictly into available categories."""
    if not text or not text.strip():
        return "Others"
        
    if not settings.GROQ_API_KEY or settings.GROQ_API_KEY == "":
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Groq API key not configured."
        )

    try:
        client = Groq(api_key=settings.GROQ_API_KEY)
        system_prompt = get_category_system_prompt()
        
        chat_completion = client.chat.completions.create(
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"Text:\n{text}"}
            ],
            model=settings.MODEL_NAME,
            temperature=0.1,  # Low temperature for strict classification
            max_tokens=10,    # We only need one word
        )
        
        response_text = chat_completion.choices[0].message.content.strip()

        usage = getattr(chat_completion, "usage", None)
        if usage:
            logger.info(
                "Category tokens - prompt=%s completion=%s total=%s",
                usage.prompt_tokens, usage.completion_tokens, usage.total_tokens,
            )

        # Clean up any potential markdown or punctuation
        response_text = response_text.replace(".", "").replace('"', "").replace("'", "")
        return response_text
    
    except Exception as e:
        logger.error(f"Groq API Error during categorization: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Failed to categorize text: {str(e)}"
        )
