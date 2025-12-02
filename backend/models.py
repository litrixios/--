# backend/models.py
from pydantic import BaseModel

class AuditRequest(BaseModel):
    data_id: int
    is_valid: bool
    notes: str = ""