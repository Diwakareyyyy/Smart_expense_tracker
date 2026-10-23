from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
import random
import datetime
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from core.config import settings
from core.logger import logger
from database.connection import get_db
from models.user import User
from models.otp import OTP
from schemas.user_schema import (
    UserSignup,
    UserLogin,
    GoogleLogin,
    ForgotPasswordRequest,
    ResetPasswordRequest
)
from services.auth_service import (
    create_user,
    authenticate_user,
    hash_password
)
from utils.jwt_handler import create_access_token

router = APIRouter(
    prefix="/api/auth",
    tags=["Authentication"]
)


def send_otp_email(to_email: str, otp: str):
    if not settings.SMTP_USER or not settings.SMTP_PASSWORD:
        logger.info(f"SMTP credentials not configured. Generated OTP for {to_email}: {otp}")
        return False
    try:
        msg = MIMEMultipart()
        # Gmail rewrites the From address to the authenticated account, so the
        # sender always falls back to SMTP_USER.
        msg['From'] = settings.SMTP_FROM or settings.SMTP_USER
        msg['To'] = to_email
        msg['Subject'] = "Password Reset OTP - Expense Tracker"

        body = f"""Hello,

You have requested to reset your password. Use the following 6-digit One-Time Password (OTP) to complete the reset:

{otp}

This OTP is valid for 10 minutes. If you did not make this request, please ignore this email.

Best regards,
Smart Expense Tracker Team"""
        msg.attach(MIMEText(body, 'plain'))

        # Connect to SMTP server
        server = smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=30)
        server.starttls()
        server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
        server.send_message(msg)
        server.quit()
        logger.info(f"Successfully sent OTP email to {to_email}")
        return True
    except Exception as e:
        logger.error(f"Failed to send SMTP email to {to_email}: {str(e)}")
        # Print OTP to console as fallback
        logger.info(f"FALLBACK OTP for {to_email}: {otp}")
        return False


# ---------------- SIGNUP ---------------- #

@router.post("/signup")
def signup(
    user: UserSignup,
    db: Session = Depends(get_db)
):
    try:
        new_user = create_user(
            db=db,
            username=user.username,
            email=user.email,
            password=user.password
        )

        if new_user is None:
            return {
                "success": False,
                "message": "Email already exists."
            }

        return {
            "success": True,
            "message": "Account created successfully."
        }
    except Exception as e:
        logger.error(f"Signup failed: {str(e)}")
        return {
            "success": False,
            "message": "Signup failed. Please check the database connection and try again."
        }


# ---------------- LOGIN ---------------- #

@router.post("/login")
def login(
    user: UserLogin,
    db: Session = Depends(get_db)
):
    try:
        db_user = authenticate_user(
            db=db,
            email=user.email,
            password=user.password
        )

        if db_user is None:
            return {
                "success": False,
                "message": "Invalid email or password."
            }

        access_token = create_access_token(
            {
                "sub": str(db_user.ET_userid)
            }
        )

        return {
            "success": True,
            "message": "Login successful",
            "access_token": access_token,
            "token_type": "bearer",
            "user": {
                "id": db_user.ET_userid,
                "username": db_user.ET_username,
                "email": db_user.ET_useremail
            }
        }
    except Exception as e:
        logger.error(f"Login failed: {str(e)}")
        return {
            "success": False,
            "message": "Login failed. Please check the database connection and try again."
        }


# ---------------- GOOGLE SIGNIN ---------------- #

@router.post("/google")
def google_auth(
    user_data: GoogleLogin,
    db: Session = Depends(get_db)
):
    try:
        # Check if a user with this email or google_id already exists
        db_user = db.query(User).filter(
            (User.ET_useremail == user_data.email) | (User.ET_google_id == user_data.google_id)
        ).first()

        if db_user is None:
            # Create a new user
            db_user = User(
                ET_username=user_data.username,
                ET_useremail=user_data.email,
                ET_google_id=user_data.google_id,
                ET_created_by=user_data.username
            )
            db.add(db_user)
            db.commit()
            db.refresh(db_user)
        else:
            # Update google_id if it's not set
            if not db_user.ET_google_id:
                db_user.ET_google_id = user_data.google_id
                db.commit()
                db.refresh(db_user)

        access_token = create_access_token(
            {
                "sub": str(db_user.ET_userid)
            }
        )

        return {
            "success": True,
            "message": "Login successful",
            "access_token": access_token,
            "token_type": "bearer",
            "user": {
                "id": db_user.ET_userid,
                "username": db_user.ET_username,
                "email": db_user.ET_useremail
            }
        }
    except Exception as e:
        logger.error(f"Google sign-in failed: {str(e)}")
        return {
            "success": False,
            "message": "Google sign-in failed. Please check the database connection and try again."
        }


# ---------------- FORGOT PASSWORD ---------------- #

@router.post("/forgot-password")
def forgot_password(
    request: ForgotPasswordRequest,
    db: Session = Depends(get_db)
):
    try:
        # Check if user exists
        user = db.query(User).filter(User.ET_useremail == request.email).first()
        if not user:
            return {
                "success": False,
                "message": "User with this email does not exist."
            }
        
        # Generate 6-digit OTP
        otp_code = f"{random.randint(100000, 999999)}"
        
        # Save to database
        db.query(OTP).filter(OTP.email == request.email).delete()
        db_otp = OTP(email=request.email, otp=otp_code)
        db.add(db_otp)
        db.commit()
        
        # Send email
        email_sent = send_otp_email(request.email, otp_code)

        response = {
            "success": True,
            "message": "OTP has been sent to your email address."
        }
        # Dev fallback: when SMTP is not configured the OTP is only printed in
        # the server console, so expose it to the app for testing purposes.
        if not email_sent:
            response["dev_otp"] = otp_code

        return response
    except Exception as e:
        logger.error(f"Forgot password request failed: {str(e)}")
        return {
            "success": False,
            "message": "Failed to send OTP. Please check the database connection and try again."
        }


# ---------------- RESET PASSWORD ---------------- #

@router.post("/reset-password")
def reset_password(
    request: ResetPasswordRequest,
    db: Session = Depends(get_db)
):
    try:
        # Check OTP in database
        db_otp = db.query(OTP).filter(
            OTP.email == request.email,
            OTP.otp == request.otp
        ).first()
        
        if not db_otp:
            return {
                "success": False,
                "message": "Invalid OTP code."
            }
        
        # Verify expiration (10 minutes)
        now = datetime.datetime.utcnow()
        expiration_time = db_otp.created_at + datetime.timedelta(minutes=10)
        if now > expiration_time:
            db.delete(db_otp)
            db.commit()
            return {
                "success": False,
                "message": "OTP has expired. Please request a new one."
            }
        
        # Find user and update password
        user = db.query(User).filter(User.ET_useremail == request.email).first()
        if not user:
            return {
                "success": False,
                "message": "User not found."
            }
        
        # Update password
        user.ET_password = hash_password(request.password)
        # Delete the OTP from db so it cannot be reused
        db.delete(db_otp)
        db.commit()
        
        return {
            "success": True,
            "message": "Password reset successfully."
        }
    except Exception as e:
        logger.error(f"Password reset failed: {str(e)}")
        return {
            "success": False,
            "message": "Failed to reset password. Please check the database connection and try again."
        }