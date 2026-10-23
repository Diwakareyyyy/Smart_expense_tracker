from sqlalchemy import Column, Integer, String, ForeignKey
from database.models import Base


class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)

    name = Column(String(100))

    user_id = Column(
        Integer,
        ForeignKey("et_users.ET_userid")
    )