from typing import Annotated

from fastapi import APIRouter, HTTPException, Path, Query

from app.core.database import DbSession
from app.core.validation import CodigoEstudiantilPath
from app.curriculo import progreso, service
from app.curriculo.schemas import (
    CursoProgresoOut,
    MallaOut,
    ProgresoCursoIn,
    ProgresoMallaOut,
)
from app.usuarios.dependencies import CurrentUser, GestorUser, verificar_acceso_estudiante

router = APIRouter(prefix="/malla", tags=["currículo"])

CursoCodigoPath = Annotated[
    str, Path(pattern=r"^[A-Za-z0-9\-]{4,20}$", description="Código del curso, p. ej. CBAS-M01A")
]

_PROTEGIDAS = {
    401: {"description": "No autenticado"},
    403: {"description": "Sin permisos sobre este recurso"},
    404: {"description": "Estudiante, programa o curso no encontrado"},
}


@router.get(
    "",
    response_model=MallaOut,
    responses={404: {"description": "Estudiante, programa o curso no encontrado"}},
)
def consultar_malla(
    db: DbSession,
    programa: Annotated[str, Query(min_length=3, max_length=120)],
):
    try:
        return service.obtener_malla(db, programa)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.get(
    "/progreso/{codigo_estudiantil}",
    response_model=ProgresoMallaOut,
    responses=_PROTEGIDAS,
)
def consultar_progreso(codigo_estudiantil: CodigoEstudiantilPath, usuario: CurrentUser, db: DbSession):
    verificar_acceso_estudiante(usuario, codigo_estudiantil)
    try:
        return progreso.calcular_progreso(db, codigo_estudiantil)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.put(
    "/progreso/{codigo_estudiantil}/{curso_codigo}",
    response_model=CursoProgresoOut,
    responses={
        **_PROTEGIDAS,
        409: {"description": "Faltan prerrequisitos por aprobar"},
        422: {"description": "Estado, fecha, periodo o nota inconsistentes"},
    },
)
def actualizar_progreso_curso(
    codigo_estudiantil: CodigoEstudiantilPath,
    curso_codigo: CursoCodigoPath,
    payload: ProgresoCursoIn,
    gestor: GestorUser,
    db: DbSession,
):
    try:
        return progreso.actualizar_progreso(
            db,
            codigo_estudiantil,
            curso_codigo.upper(),
            payload.estado,
            payload.fecha_aprobacion,
            payload.periodo,
            payload.nota,
            actor_id=gestor.id,
        )
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except progreso.ProgresoInvalido as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except progreso.PrerrequisitosPendientes as exc:
        raise HTTPException(
            status_code=409,
            detail=f"Faltan prerrequisitos por aprobar: {', '.join(exc.faltantes)}",
        ) from exc
