from pydantic import BaseModel


class BudgetBase(BaseModel):
    amount: float


class BudgetCreate(BudgetBase):
    pass


class BudgetResponse(BudgetBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True
