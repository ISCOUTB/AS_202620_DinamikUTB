from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Path, Query, status

from app.ayuda import service
from app.ayuda.schemas import (
    CoordinadorOut,
    EstadoSolicitud,
    SolicitudEstadoIn,
    SolicitudIn,
    SolicitudOut,
)
from app.core.database import DbSession
from app.core.validation import ID_ENTERO_MAX
from app.estudiantes.service import obtener_estudiante
from app.usuarios.dependencies import CurrentUser, GestorUser, require_roles
from app.usuarios.models import Usuario
from app.usuarios.roles import Rol

router = APIRouter(prefix="/ayuda", tags=["ayuda"])

EstudianteUser = Annotated[Usuario, Depends(require_roles(Rol.ESTUDIANTE))]

_PROTEGIDAS = {
    401: {"description": "No autenticado"},
    403: {"description": "Sin permisos sobre este recurso"},
}


@router.get(
    "/coordinador",
    response_model=CoordinadorOut,
    responses={**_PROTEGIDAS, 404: {"description": "Sin coordinador registrado"}},
)
def consultar_coordinador(
    usuario: CurrentUser,
    db: DbSession,
    programa: Annotated[str | None, Query(max_length=120)] = None,
):
    try:
        nombre = service.programa_para_directorio(db, usuario, programa)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except service.SolicitudInvalida as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    coordinador = service.coordinador_de_programa(db, nombre)
    if coordinador is None:
        raise HTTPException(status_code=404, detail="Este programa aún no tiene coordinador registrado.")
    return coordinador


@router.post(
    "/solicitudes",
    response_model=SolicitudOut,
    status_code=status.HTTP_201_CREATED,
    responses={
        **_PROTEGIDAS,
        400: {"description": "La cuenta no tiene perfil de estudiante"},
        422: {"description": "Datos de la solicitud inválidos"},
    },
)
def crear_solicitud(payload: SolicitudIn, usuario: EstudianteUser, db: DbSession):
    estudiante = obtener_estudiante(db, usuario.codigo_estudiantil) if usuario.codigo_estudiantil else None
    if estudiante is None:
        raise HTTPException(status_code=400, detail="Tu cuenta no tiene un perfil de estudiante asociado.")
    return service.crear_solicitud(db, estudiante, payload.model_dump())


@router.get("/solicitudes", response_model=list[SolicitudOut], responses=_PROTEGIDAS)
def listar_solicitudes(
    usuario: CurrentUser,
    db: DbSession,
    estado: EstadoSolicitud | None = None,
    limite: Annotated[int, Query(ge=1, le=100)] = 50,
    desplazamiento: Annotated[int, Query(ge=0)] = 0,
):
    return service.listar_solicitudes(db, usuario, estado, limite, desplazamiento)


@router.put(
    "/solicitudes/{solicitud_id}/estado",
    response_model=SolicitudOut,
    responses={
        **_PROTEGIDAS,
        404: {"description": "Solicitud no encontrada"},
        422: {"description": "Falta la respuesta para resolver"},
    },
)
def actualizar_estado(
    solicitud_id: Annotated[int, Path(ge=1, le=ID_ENTERO_MAX)],
    payload: SolicitudEstadoIn,
    usuario: GestorUser,
    db: DbSession,
):
    try:
        return service.actualizar_estado(
            db, usuario, solicitud_id, payload.estado, payload.respuesta_coordinador
        )
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except service.SolicitudInvalida as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
