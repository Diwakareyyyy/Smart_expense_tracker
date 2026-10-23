import easyocr
import io
from PIL import Image, ImageEnhance
import numpy as np

reader = easyocr.Reader(['en'])

def preprocess_image(image_bytes: bytes) -> np.ndarray:
    image = Image.open(io.BytesIO(image_bytes))
    # Enhance contrast to improve OCR accuracy
    enhancer = ImageEnhance.Contrast(image)
    image = enhancer.enhance(2.0)
    # Convert to grayscale
    image = image.convert('L')
    return np.array(image)

def extract_text_from_image(image_bytes: bytes) -> str:
    try:
        image_np = preprocess_image(image_bytes)
        result = reader.readtext(image_np, detail=0)
        return " ".join(result)
    except Exception as e:
        return f"Failed to extract text: {str(e)}"

import json
from groq import Groq
from core.config import settings
from core.logger import logger

def _trim_receipt_text(text: str, max_chars: int = 2500) -> str:
    """Keep the top (merchant/items) and bottom (total/payment) of a long receipt."""
    if not text or len(text) <= max_chars:
        return text
    head_chars = 600
    head = text[:head_chars]
    tail = text[-(max_chars - head_chars):]
    return head + "\n...[receipt truncated]...\n" + tail


def parse_receipt_text_ai(text: str) -> dict:
    """Uses Groq LLM to parse raw receipt text and categorize it."""
    api_key = settings.expense_tracker_api_key
    if not api_key:
        logger.error("Groq API key not configured for receipt parsing")
        return {
            "amount": None,
            "merchant": "Receipt Expense",
            "category": "Others",
            "payment_method": "Cash",
            "usage": None,
        }

    system_prompt = """You are an expert receipt parser. Extract from the OCR text a JSON object ONLY (no markdown, no explanations):
- "amount": the TOTAL paid, taken ONLY from lines like "TOTAL", "GRAND TOTAL", "NET AMOUNT", "AMOUNT PAID", "PAYMENT OF". Do NOT add up individual item prices. Strip ₹, Rs, commas. If not found, null.
- "merchant": the store name, or for UPI screenshots the name after "To:" / "Paid to" / "money to". Max 40 chars. If not found, "Receipt Expense".
- "category": EXACTLY ONE of: Food, Health, Medicine, Education, Shopping, Fuel, Recharge, Electricity, Transport, Entertainment, Gadgets, Juice, Bills, Rent, Groceries, Travel, Insurance, Gift, Business, Others.
- "payment_method": EXACTLY ONE of: Cash, UPI, Card, Bank, Wallet.

Categorization rules:
- Fuel: Petrol, Diesel, CNG, Indian Oil, HP, Bharat Petroleum, Shell.
- Food: Restaurants, cafes, Zomato/Swiggy food delivery, bakeries, fast food.
- Groceries: Supermarkets, Bigbasket, Blinkit, Zepto, DMart, Swiggy Instamart, vegetables, milk, eggs, daily essentials.
- Juice: Coffee shops, Starbucks, tea/chai stalls, soft drinks.
- Medicine: Pharmacies, chemists, Apollo Pharmacy, Medplus, online medicine orders.
- Health: Hospitals, doctor fees, clinics, lab reports.
- Recharge: Mobile/SIM recharge (Airtel, Jio, Vi).
- Electricity: Electric bills.
- Bills: Subscriptions (Netflix, Spotify), gas, internet/broadband, water.
- Transport: Cabs (Uber, Ola, Rapido), metro, bus, train (IRCTC), auto, tolls.
- Shopping: Clothes, shoes, Amazon, Flipkart, Myntra, electronics.
- Gadgets: Phone, laptop, accessories, computer parts.
- Travel: Flights, hotels, long trips.

Payment rules:
- UPI only if explicitly shown (GPay, PhonePe, Paytm, BHIM, "UPI", "Paid via/using").
- Card only if explicitly shown (Visa, Mastercard, Rupay, credit/debit card, swipe).
- Otherwise, or if not clearly mentioned, default to Cash.

Example: {"amount": 250.00, "merchant": "Starbucks Coffee", "category": "Juice", "payment_method": "Card"}"""

    try:
        client = Groq(api_key=api_key)
        chat_completion = client.chat.completions.create(
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"Receipt Text:\n{_trim_receipt_text(text)}"},
            ],
            model=settings.MODEL_NAME,
            temperature=0.1,
            max_tokens=250,
        )
        response_text = chat_completion.choices[0].message.content.strip()

        usage = getattr(chat_completion, "usage", None)
        usage_dict = None
        if usage:
            usage_dict = {
                "prompt_tokens": usage.prompt_tokens,
                "completion_tokens": usage.completion_tokens,
                "total_tokens": usage.total_tokens,
            }
            logger.info(
                "OCR parse tokens - prompt=%s completion=%s total=%s",
                usage.prompt_tokens, usage.completion_tokens, usage.total_tokens,
            )

        # Strip markdown code blocks if any
        if response_text.startswith("```"):
            lines = response_text.splitlines()
            if lines[0].startswith("```"):
                lines = lines[1:]
            if lines and lines[-1].startswith("```"):
                lines = lines[:-1]
            response_text = "\n".join(lines).strip()
            
        data = json.loads(response_text)
        
        # Validate elements to match options exactly
        valid_categories = {
            "Food", "Health", "Medicine", "Education", "Shopping", "Fuel", "Recharge", 
            "Electricity", "Transport", "Entertainment", "Gadgets", "Juice", "Bills", 
            "Rent", "Groceries", "Travel", "Insurance", "Gift", "Business", "Others"
        }
        valid_payments = {"Cash", "UPI", "Card", "Bank", "Wallet"}
        
        # Clean amount
        amount = data.get("amount")
        if amount is not None:
            try:
                amount = float(amount)
            except (ValueError, TypeError):
                amount = None
                
        # Clean category
        category = str(data.get("category", "Others")).strip().capitalize()
        # Handle capitalization variations
        for c in valid_categories:
            if c.lower() == category.lower():
                category = c
                break
        if category not in valid_categories:
            category = "Others"
            
        # Clean payment method
        payment_method = str(data.get("payment_method", "Cash")).strip()
        # Handle capitalization variations
        for p in valid_payments:
            if p.lower() == payment_method.lower():
                payment_method = p
                break
        if payment_method not in valid_payments:
            payment_method = "Cash"
            
        merchant = str(data.get("merchant", "Receipt Expense")).strip()
        if len(merchant) > 40:
            merchant = merchant[:40]
            
        return {
            "amount": amount,
            "merchant": merchant,
            "category": category,
            "payment_method": payment_method,
            "usage": usage_dict,
        }
        
    except Exception as e:
        logger.error(f"Error parsing receipt text with AI: {str(e)}")
        return {
            "amount": None,
            "merchant": "Receipt Expense",
            "category": "Others",
            "payment_method": "Cash",
            "usage": None,
        }

