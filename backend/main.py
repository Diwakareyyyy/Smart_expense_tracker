import sys

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
import uvicorn

from core.logger import logger

# Database
from database.connection import engine, SessionLocal
from database.models import Base

# Import models so SQLAlchemy registers them
import models.user
import models.transaction
import models.category
import models.budget
import models.otp

# Import API routers
from api import auth, transactions, chatbot, ocr, category, budget


# Create database tables
try:
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables are ready.")
except Exception as e:
    logger.error(f"Could not connect to the database: {str(e)}")
    logger.error(
        "Check MYSQL_* settings in backend/.env (MYSQL_PASSWORD must be your "
        "real MySQL password, not a placeholder). The server will still start, "
        "but auth endpoints will return errors until the DB is reachable."
    )


# Create FastAPI app
app = FastAPI(
    title="AI Expense Tracker Backend",
    description="Backend API for AI Expense Tracker",
    version="1.0.0",
)


# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # Later replace "*" with your Flutter app URL/IP
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Register Routers
app.include_router(auth.router)
app.include_router(transactions.router)
app.include_router(category.router)
app.include_router(chatbot.router)
app.include_router(ocr.router)
app.include_router(budget.router)


# Startup Event
@app.on_event("startup")
async def startup_event():
    logger.info("Application starting up...")


# Root Endpoint
@app.get("/")
def read_root():
    return {
        "message": "Welcome to AI Expense Tracker API",
        "status": "Running"
    }


@app.get("/api/health")
def health_check():
    db_ok = True
    db_error = None
    try:
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
    except Exception as e:
        db_ok = False
        db_error = str(e)
    return {
        "status": "Running",
        "database": "connected" if db_ok else "error",
        "database_error": db_error,
    }


# Run Server
if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )