from pydantic import BaseModel, ConfigDict


class RequisitoOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    estado: str

from typing import Literal


class RequisitoEstadoUpdate(BaseModel):
    estado: Literal["cumplido", "pendiente", "en_proceso"]
