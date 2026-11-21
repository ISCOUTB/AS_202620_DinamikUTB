from datetime import datetime
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, StringConstraints

TipoDiscrepancia = Literal[
    "materia_sin_marca",
    "error_fecha_o_nota",
    "homologacion",
    "ingles_saber_pro",
    "prerrequisito_bloqueado",
    "otro",
]
EstadoSolicitud = Literal["pendiente", "en_revision", "resuelta"]


class SolicitudIn(BaseModel):
    model_config = ConfigDict(extra="forbid")

    tipo_discrepancia: TipoDiscrepancia
    elemento_afectado: Annotated[str, StringConstraints(strip_whitespace=True, min_length=3, max_length=160)]
    descripcion: Annotated[str, StringConstraints(strip_whitespace=True, min_length=10, max_length=1500)]
    referencia_soporte: Annotated[str, StringConstraints(strip_whitespace=True, max_length=200)] = ""


class SolicitudEstadoIn(BaseModel):
    model_config = ConfigDict(extra="forbid")

    estado: EstadoSolicitud
    respuesta_coordinador: Annotated[str, StringConstraints(strip_whitespace=True, max_length=1500)] = ""


class SolicitudOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    radicado: str
    estudiante_id: str
    programa: str
    tipo_discrepancia: str
    elemento_afectado: str
    descripcion: str
    referencia_soporte: str
    estado: str
    respuesta_coordinador: str
    creado_en: datetime
    actualizado_en: datetime


class CoordinadorOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    programa: str
    nombre: str
    cargo: str
    correo: str
    oficina: str
    campus: str
    horario: str
