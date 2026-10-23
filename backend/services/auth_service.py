from sqlalchemy.orm import Session
from models.user import User
import bcrypt


def _prepare(password: str) -> bytes:
    # bcrypt only considers the first 72 bytes of a password
    return password.encode("utf-8")[:72]


def hash_password(password: str) -> str:
    hashed = bcrypt.hashpw(_prepare(password), bcrypt.gensalt())
    return hashed.decode("utf-8")


def verify_password(password: str, hashed_password: str) -> bool:
    if not hashed_password:
        return False
    try:
        return bcrypt.checkpw(
            _prepare(password),
            hashed_password.encode("utf-8")
        )
    except ValueError:
        return False


def create_user(
    db: Session,
    username: str,
    email: str,
    password: str
):
    # Check whether email already exists
    existing_user = (
        db.query(User)
        .filter(User.ET_useremail == email)
        .first()
    )

    if existing_user:
        return None

    hashed_password = hash_password(password)

    new_user = User(
        ET_username=username,
        ET_useremail=email,
        ET_password=hashed_password,
        ET_created_by=username
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return new_user


def authenticate_user(
    db: Session,
    email: str,
    password: str
):
    user = (
        db.query(User)
        .filter(User.ET_useremail == email)
        .first()
    )

    if not user:
        return None

    if not verify_password(password, user.ET_password):
        return None

    return user
