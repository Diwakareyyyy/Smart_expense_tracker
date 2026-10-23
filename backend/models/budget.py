from sqlalchemy import Column, Integer, Float, ForeignKey
from database.models import Base


class Budget(Base):
    __tablename__ = "budgets"

    id = Column(Integer, primary_key=True, index=True)
    amount = Column(Float, nullable=False, default=0.0)
    user_id = Column(
        Integer,
        ForeignKey("et_users.ET_userid"),
        unique=True,
        nullable=False
    )
