from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.requisitos import service
from app.requisitos.schemas import RequisitoEstadoUpdate, RequisitoOut

router = APIRouter(prefix="/requisitos", tags=["requisitos"])

DbSession = Annotated[Session, Depends(get_db)]


@router.get("/{estudiante_id}", response_model=list[RequisitoOut])
def consultar_requisitos(estudiante_id: str, db: DbSession):
    return service.obtener_requisitos_por_estudiante(db, estudiante_id)


@router.put(
    "/{requisito_id}/estado",
    response_model=RequisitoOut,
    responses={404: {"description": "Requisito no encontrado"}},
)
def actualizar_estado(
    requisito_id: int, payload: RequisitoEstadoUpdate, db: DbSession
):
    requisito = service.actualizar_estado_requisito(db, requisito_id, payload.estado)
    if requisito is None:
        raise HTTPException(status_code=404, detail="Requisito no encontrado")
    return requisito
