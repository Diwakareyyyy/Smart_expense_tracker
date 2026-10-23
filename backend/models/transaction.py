from sqlalchemy import Column, Integer, Float, String, DateTime, ForeignKey
from database.models import Base
import datetime


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)

    amount = Column(Float, nullable=False)

    description = Column(String(255))

    category = Column(String(100))

    date = Column(
        DateTime,
        default=datetime.datetime.utcnow
    )

    payment_method = Column(String(100))

    type = Column(String(20)) # "Income" or "Expense"

    user_id = Column(
        Integer,
        ForeignKey("et_users.ET_userid")
    )