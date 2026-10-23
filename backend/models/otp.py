from sqlalchemy import Column, Integer, String, DateTime
from database.models import Base
import datetime


class OTP(Base):
    __tablename__ = "password_reset_otps"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(100), index=True, nullable=False)
    otp = Column(String(6), nullable=False)
    created_at = Column(
        DateTime,
        default=datetime.datetime.utcnow
    )
