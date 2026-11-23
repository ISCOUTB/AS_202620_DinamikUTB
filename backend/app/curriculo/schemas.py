from pydantic import BaseModel, ConfigDict, Field


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
