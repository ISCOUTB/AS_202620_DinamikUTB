from typing import Literal

from pydantic import BaseModel, ConfigDict


class RequisitoOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    estado: str


class RequisitoEstadoUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    estado: Literal["cumplido", "pendiente", "en_proceso"]


class ResumenRequisitosOut(BaseModel):
    total: int
    cumplidos: int
    en_proceso: int
    pendientes: int
    porcentaje_avance: float
