from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.estudiantes import service
from app.estudiantes.schemas import EstudianteOut

router = APIRouter(prefix="/estudiantes", tags=["estudiantes"])

DbSession = Annotated[Session, Depends(get_db)]


@router.get(
    "/{codigo_estudiantil}",
    response_model=EstudianteOut,
    responses={404: {"description": "Estudiante no encontrado"}},
)
def consultar_estudiante(codigo_estudiantil: str, db: DbSession):
    estudiante = service.obtener_estudiante(db, codigo_estudiantil)
    if estudiante is None:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")
    return estudiante
