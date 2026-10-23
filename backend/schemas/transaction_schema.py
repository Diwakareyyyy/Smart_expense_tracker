from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class TransactionBase(BaseModel):
    amount: float
    description: str
    category: Optional[str] = "Uncategorized"
    payment_method: Optional[str] = None
    type: str = "Expense"  # "Income" or "Expense"

class TransactionCreate(TransactionBase):
    pass

class TransactionResponse(TransactionBase):
    id: int
    user_id: int
    date: datetime

    class Config:
        from_attributes = True
