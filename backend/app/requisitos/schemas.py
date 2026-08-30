from pydantic import BaseModel


class RequisitoOut(BaseModel):
    id: int
    nombre: str
    estado: str

    class Config:
        from_attributes = True
