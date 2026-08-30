from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.requisitos import service
from app.requisitos.schemas import RequisitoOut

router = APIRouter(prefix="/requisitos", tags=["requisitos"])


@router.get("/{estudiante_id}", response_model=list[RequisitoOut])
def consultar_requisitos(estudiante_id: str, db: Session = Depends(get_db)):
    return service.obtener_requisitos_por_estudiante(db, estudiante_id)
