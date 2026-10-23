from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import model_validator


class Settings(BaseSettings):

    PROJECT_NAME: str = "AI Expense Tracker"

    SECRET_KEY: str = "supersecretkey"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    GROQ_API_KEY: str = ""
    expense_tracker_api_key: str = ""
    SMART_EXPENSE_API_KEY: str = ""

    MODEL_NAME: str = "llama-3.3-70b-versatile"
    TEMPERATURE: float = 0.5
    MAX_TOKENS: int = 500
    CHAT_HISTORY_LIMIT: int = 10

    UPLOAD_FOLDER: str = "uploads/receipts/"

    MYSQL_HOST: str = "localhost"
    MYSQL_PORT: int = 3306
    MYSQL_DATABASE: str = "expense_tracker"
    MYSQL_USER: str = "root"
    MYSQL_PASSWORD: str = ""

    # SMTP Configuration
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    SMTP_FROM: str = "noreply@expense-tracker.com"

    # Google OAuth (created in Google Cloud Console)
    GOOGLE_WEB_CLIENT_ID: str = ""
    GOOGLE_ANDROID_CLIENT_ID: str = ""

    @model_validator(mode="after")
    def sync_groq_key(self) -> "Settings":
        if not self.GROQ_API_KEY and self.expense_tracker_api_key:
            self.GROQ_API_KEY = self.expense_tracker_api_key
        elif not self.expense_tracker_api_key and self.GROQ_API_KEY:
            self.expense_tracker_api_key = self.GROQ_API_KEY
        return self

    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore"
    )


@lru_cache()
def get_settings():
    return Settings()


settings = get_settings()