from pydantic import BaseModel, ConfigDict
from typing import Literal

class RequisitoOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    estado: str
    creditos: int = 0

class RequisitoEstadoUpdate(BaseModel):
    estado: Literal["cumplido", "pendiente", "en_proceso"]
