from typing import Annotated

from pydantic import BaseModel, ConfigDict, Field, StringConstraints


class ProgramaIn(BaseModel):
    model_config = ConfigDict(extra="forbid")

    codigo: Annotated[str, StringConstraints(strip_whitespace=True, min_length=2, max_length=20)]
    nombre: Annotated[str, StringConstraints(strip_whitespace=True, min_length=3, max_length=120)]
    facultad: Annotated[str, StringConstraints(strip_whitespace=True, min_length=2, max_length=120)]
    duracion_semestres: int = Field(ge=1, le=20)


class ProgramaOut(ProgramaIn):
    model_config = ConfigDict(from_attributes=True)

    id: int
    activo: bool
    estudiantes_asociados: int = 0


class ProgramaUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    codigo: Annotated[str, StringConstraints(strip_whitespace=True, min_length=2, max_length=20)]
    nombre: Annotated[str, StringConstraints(strip_whitespace=True, min_length=3, max_length=120)]
    facultad: Annotated[str, StringConstraints(strip_whitespace=True, min_length=2, max_length=120)]
    duracion_semestres: int = Field(ge=1, le=20)
    activo: bool
