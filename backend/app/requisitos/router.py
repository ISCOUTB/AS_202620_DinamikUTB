from typing import Annotated

from fastapi import APIRouter, HTTPException, Path

from app.core.database import DbSession
from app.core.validation import ID_ENTERO_MAX, CodigoEstudiantilPath
from app.requisitos import service
from app.requisitos.schemas import RequisitoEstadoUpdate, RequisitoOut, ResumenRequisitosOut
from app.usuarios.dependencies import CurrentUser, GestorUser, verificar_acceso_estudiante

router = APIRouter(prefix="/requisitos", tags=["requisitos"])

_RESPUESTAS_PROTEGIDAS = {
    401: {"description": "No autenticado"},
    403: {"description": "Sin permisos sobre este recurso"},
}


@router.get(
    "/{estudiante_id}",
    response_model=list[RequisitoOut],
    responses=_RESPUESTAS_PROTEGIDAS,
)
def consultar_requisitos(estudiante_id: CodigoEstudiantilPath, usuario: CurrentUser, db: DbSession):
    verificar_acceso_estudiante(usuario, estudiante_id)
    return service.obtener_requisitos_por_estudiante(db, estudiante_id)


@router.get(
    "/{estudiante_id}/resumen",
    response_model=ResumenRequisitosOut,
    responses=_RESPUESTAS_PROTEGIDAS,
)
def consultar_resumen(estudiante_id: CodigoEstudiantilPath, usuario: CurrentUser, db: DbSession):
    verificar_acceso_estudiante(usuario, estudiante_id)
    return service.calcular_resumen(db, estudiante_id)


@router.put(
    "/{requisito_id}/estado",
    response_model=RequisitoOut,
    responses={**_RESPUESTAS_PROTEGIDAS, 404: {"description": "Requisito no encontrado"}},
)
def actualizar_estado(
    requisito_id: Annotated[int, Path(ge=1, le=ID_ENTERO_MAX)],
    payload: RequisitoEstadoUpdate,
    usuario: GestorUser,
    db: DbSession,
):
    requisito = service.actualizar_estado_requisito(db, requisito_id, payload.estado, actor_id=usuario.id)
    if requisito is None:
        raise HTTPException(status_code=404, detail="Requisito no encontrado")
    return requisito
