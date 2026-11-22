from datetime import date
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field, StringConstraints


class CursoMallaOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    codigo: str
    nombre: str
    nivel: int = Field(ge=1, le=20)
    creditos: int = Field(ge=0)
    prerequisitos: list[str]


class MallaOut(BaseModel):
    programa: str
    plan: str
    creditos_totales: int
    cursos: list[CursoMallaOut]


EstadoCurso = Literal["aprobado", "en_curso", "pendiente"]


class ProgresoCursoIn(BaseModel):
    model_config = ConfigDict(extra="forbid")

    estado: EstadoCurso
    fecha_aprobacion: date | None = None
    periodo: Annotated[str, StringConstraints(pattern=r"^\d{4}-[12]$")] | None = None
    nota: float | None = Field(default=None, ge=0, le=5)


class CursoProgresoOut(BaseModel):
    codigo: str
    nombre: str
    nivel: int
    creditos: int
    prerequisitos: list[str]
    desbloquea: list[str]
    estado: EstadoCurso
    desbloqueada: bool
    prerequisitos_faltantes: list[str]
    fecha_aprobacion: date | None
    periodo: str | None
    nota: float | None


class NivelProgresoOut(BaseModel):
    nivel: int
    creditos_totales: int
    creditos_aprobados: int
    porcentaje: float


class ResumenProgresoOut(BaseModel):
    creditos_totales: int
    creditos_aprobados: int
    creditos_en_curso: int
    creditos_pendientes: int
    porcentaje_global: float
    promedio_acumulado: float | None
    cursos_aprobados: int
    cursos_total: int
    semestres_restantes: int
    periodo_grado_estimado: str | None


class ProgresoMallaOut(BaseModel):
    codigo_estudiantil: str
    programa: str
    plan: str
    periodo_actual: str
    resumen: ResumenProgresoOut
    niveles: list[NivelProgresoOut]
    cursos: list[CursoProgresoOut]
