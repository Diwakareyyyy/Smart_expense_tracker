"""Test SMTP email sending with the credentials from .env.

Usage:
    python test_smtp.py you@gmail.com

Sends a test OTP email to the address given and prints the result.
"""
import smtplib
import sys
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from core.config import settings

to_email = sys.argv[1] if len(sys.argv) > 1 else settings.SMTP_USER

if not settings.SMTP_USER or not settings.SMTP_PASSWORD:
    print("SMTP is NOT configured. Add SMTP_USER and SMTP_PASSWORD to backend/.env")
    sys.exit(1)

msg = MIMEMultipart()
msg['From'] = settings.SMTP_FROM or settings.SMTP_USER
msg['To'] = to_email
msg['Subject'] = "SMTP Test - Expense Tracker"
msg.attach(MIMEText(
    "Hello!\n\n"
    "This is a test email to confirm SMTP is working for password reset OTPs.\n\n"
    "Best regards,\nSmart Expense Tracker Team",
    'plain'
))

try:
    server = smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=30)
    server.starttls()
    server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
    server.send_message(msg)
    server.quit()
    print(f"Email sent successfully to {to_email}!")
except Exception as e:
    print(f"FAILED: {e}")
    sys.exit(1)
