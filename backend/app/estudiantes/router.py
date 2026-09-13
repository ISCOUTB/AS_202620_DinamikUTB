from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.estudiantes import service
from app.estudiantes.schemas import EstudianteOut

router = APIRouter(prefix="/estudiantes", tags=["estudiantes"])


@router.get("/{codigo_estudiantil}", response_model=EstudianteOut)
def consultar_estudiante(codigo_estudiantil: str, db: Session = Depends(get_db)):
    estudiante = service.obtener_estudiante(db, codigo_estudiantil)
    if estudiante is None:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")
    return estudiante
