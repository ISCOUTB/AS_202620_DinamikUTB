from pydantic import BaseModel, ConfigDict


class EstudianteOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    codigo_estudiantil: str
    nombre: str
    programa: str
