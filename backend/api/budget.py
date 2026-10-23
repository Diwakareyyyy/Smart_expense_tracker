from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database.connection import get_db
from models.budget import Budget
from schemas.budget_schema import BudgetCreate, BudgetResponse
from core.dependencies import get_current_user
from models.user import User

router = APIRouter(prefix="/api/budget", tags=["Budget"])


@router.get("/", response_model=BudgetResponse)
def get_budget(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_budget = db.query(Budget).filter(Budget.user_id == current_user.ET_userid).first()
    if not db_budget:
        # Create a default budget of 0.0 if none exists yet
        db_budget = Budget(amount=0.0, user_id=current_user.ET_userid)
        db.add(db_budget)
        db.commit()
        db.refresh(db_budget)
    return db_budget


@router.post("/", response_model=BudgetResponse)
def set_budget(
    budget: BudgetCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_budget = db.query(Budget).filter(Budget.user_id == current_user.ET_userid).first()
    if db_budget:
        db_budget.amount = budget.amount
    else:
        db_budget = Budget(amount=budget.amount, user_id=current_user.ET_userid)
        db.add(db_budget)
    db.commit()
    db.refresh(db_budget)
    return db_budget
