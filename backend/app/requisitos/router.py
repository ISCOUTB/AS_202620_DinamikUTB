from typing import Annotated

from fastapi import APIRouter, HTTPException, Path, status

from app.core.database import DbSession
from app.core.validation import ID_ENTERO_MAX, CodigoEstudiantilPath
from app.estudiantes.models import Estudiante
from app.programas.models import Programa
from app.requisitos import service
from app.requisitos.models import Requisito, RequisitoPrograma
from app.requisitos.schemas import (
    RequisitoCatalogoIn,
    RequisitoCatalogoUpdate,
    RequisitoDetalleOut,
    RequisitoDetalleUpdate,
    RequisitoEstadoUpdate,
    RequisitoOut,
    RequisitoRutaOut,
    ResumenRequisitosOut,
)
from app.usuarios.dependencies import AdminUser, CurrentUser, GestorUser, verificar_acceso_estudiante

router = APIRouter(prefix="/requisitos", tags=["requisitos"])

_RESPUESTAS_PROTEGIDAS = {
    401: {"description": "No autenticado"},
    403: {"description": "Sin permisos sobre este recurso"},
}

RequisitoIdPath = Annotated[int, Path(ge=1, le=ID_ENTERO_MAX)]


def _catalogo_dict(item: RequisitoPrograma, programa: str) -> dict:
    return {
        "id": item.id,
        "programa_id": item.programa_id,
        "programa": programa,
        "nombre": item.nombre,
        "descripcion": item.descripcion,
        "semestre_recomendado": item.semestre_recomendado,
        "obligatorio": item.obligatorio,
        "activo": item.activo,
        "codigo_interno": item.codigo_interno,
        "categoria": item.categoria,
        "porcentaje_creditos_requerido": item.porcentaje_creditos_requerido,
        "portal_oficial": item.portal_oficial,
        "tiempo_estimado": item.tiempo_estimado,
        "guia_resumen": item.guia_resumen,
        "pasos_guia": item.pasos_guia or [],
    }


@router.get("/catalogo", responses={401: {"description": "No autenticado"}})
def listar_catalogo(_usuario: CurrentUser, db: DbSession, programa_id: int | None = None):
    q = db.query(RequisitoPrograma)
    if programa_id:
        q = q.filter(RequisitoPrograma.programa_id == programa_id)
    programas = {p.id: p.nombre for p in db.query(Programa).all()}
    return [_catalogo_dict(item, programas.get(item.programa_id, "")) for item in q.all()]


@router.post("/catalogo", status_code=status.HTTP_201_CREATED)
def crear_requisito_catalogo(payload: RequisitoCatalogoIn, _admin: AdminUser, db: DbSession):
    prog = db.get(Programa, payload.programa_id)
    if not prog:
        raise HTTPException(status_code=404, detail="Programa no encontrado")

    req_prog = RequisitoPrograma(**payload.model_dump())
    db.add(req_prog)
    db.flush()

    # Asigna el nuevo requisito a todos los estudiantes de ese programa
    estudiantes = db.query(Estudiante).filter(Estudiante.programa == prog.nombre).all()
    for est in estudiantes:
        db.add(
            Requisito(
                estudiante_id=est.codigo_estudiantil,
                nombre=req_prog.nombre,
                estado="pendiente",
                catalogo_id=req_prog.id,
            )
        )

    # single transaction: RequisitoPrograma + Requisitos asignados, atomic
    db.commit()
    db.refresh(req_prog)
    return _catalogo_dict(req_prog, prog.nombre)


@router.put(
    "/catalogo/{catalogo_id}",
    responses={
        **_RESPUESTAS_PROTEGIDAS,
        404: {"description": "Requisito o programa no encontrado"},
        422: {"description": "No se puede mover un requisito a otro programa"},
    },
)
def actualizar_requisito_catalogo(
    catalogo_id: RequisitoIdPath,
    payload: RequisitoCatalogoUpdate,
    _admin: AdminUser,
    db: DbSession,
):
    item = db.get(RequisitoPrograma, catalogo_id, with_for_update=True)
    if item is None:
        raise HTTPException(status_code=404, detail="Requisito no encontrado")
    prog = db.get(Programa, item.programa_id)
    if prog is None:
        raise HTTPException(status_code=404, detail="Programa no encontrado")
    if payload.programa_id != item.programa_id:
        # Los estudiantes ya tienen este requisito asignado por programa: moverlo
        # dejaría filas huérfanas. Se crea uno nuevo en el otro programa.
        raise HTTPException(
            status_code=422,
            detail="No se puede cambiar el programa de un requisito existente.",
        )

    cambios = payload.model_dump(exclude_unset=True)
    cambios.pop("programa_id", None)
    nombre_anterior = item.nombre
    for campo, valor in cambios.items():
        setattr(item, campo, valor)

    if item.nombre != nombre_anterior:
        # El nombre vive en el catálogo y se copia a cada estudiante: se mantiene alineado.
        db.query(Requisito).filter(Requisito.catalogo_id == item.id).update(
            {"nombre": item.nombre}, synchronize_session=False
        )

    # single transaction: RequisitoPrograma + nombre en Requisitos asignados, atomic
    db.commit()
    db.refresh(item)
    return _catalogo_dict(item, prog.nombre)


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


@router.get(
    "/{estudiante_id}/ruta",
    response_model=list[RequisitoRutaOut],
    responses=_RESPUESTAS_PROTEGIDAS,
)
def consultar_ruta(estudiante_id: CodigoEstudiantilPath, usuario: CurrentUser, db: DbSession):
    verificar_acceso_estudiante(usuario, estudiante_id)
    return service.obtener_ruta(db, estudiante_id)


@router.put(
    "/{requisito_id}/estado",
    response_model=RequisitoOut,
    responses={**_RESPUESTAS_PROTEGIDAS, 404: {"description": "Requisito no encontrado"}},
)
def actualizar_estado(
    requisito_id: RequisitoIdPath,
    payload: RequisitoEstadoUpdate,
    usuario: GestorUser,
    db: DbSession,
):
    requisito = service.actualizar_estado_requisito(db, requisito_id, payload.estado, actor_id=usuario.id)
    if requisito is None:
        raise HTTPException(status_code=404, detail="Requisito no encontrado")
    return requisito


@router.put(
    "/{requisito_id}/detalle",
    response_model=RequisitoDetalleOut,
    responses={
        **_RESPUESTAS_PROTEGIDAS,
        404: {"description": "Requisito no encontrado"},
        422: {"description": "Fecha futura o formato inválido"},
    },
)
def actualizar_detalle(
    requisito_id: RequisitoIdPath,
    payload: RequisitoDetalleUpdate,
    usuario: GestorUser,
    db: DbSession,
):
    try:
        requisito = service.actualizar_detalle_requisito(
            db,
            requisito_id,
            payload.fecha_cumplimiento,
            payload.periodo,
            payload.evidencia,
            actor_id=usuario.id,
        )
    except service.DetalleInvalido as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    if requisito is None:
        raise HTTPException(status_code=404, detail="Requisito no encontrado")
    return requisito
