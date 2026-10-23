import os
from fastapi import HTTPException, status
from typing import List

ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png"}

def validate_image_extension(filename: str) -> None:
    """Validate if the uploaded file has a supported image extension."""
    if not filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Empty filename"
        )
    
    ext = filename.split(".")[-1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid image extension. Supported: {', '.join(ALLOWED_EXTENSIONS)}"
        )
