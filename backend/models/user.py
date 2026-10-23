from sqlalchemy import Column, Integer, String, DateTime
from database.models import Base
import datetime


class User(Base):
    __tablename__ = "et_users"

    ET_userid = Column(Integer, primary_key=True, index=True)

    ET_username = Column(String(100), nullable=False)

    ET_useremail = Column(String(100), unique=True, nullable=False)

    ET_password = Column(String(255))

    ET_google_id = Column(String(255))

    ET_created_by = Column(String(100))

    ET_created_on = Column(
        DateTime,
        default=datetime.datetime.utcnow
    )

    ET_modified_by = Column(String(100))

    ET_modified_on = Column(
        DateTime,
        default=datetime.datetime.utcnow,
        onupdate=datetime.datetime.utcnow
    )