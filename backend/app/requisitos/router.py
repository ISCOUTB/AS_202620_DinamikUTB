from typing import Annotated

from fastapi import APIRouter, HTTPException, Path, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import DbSession
from app.core.validation import ID_ENTERO_MAX, CodigoEstudiantilPath
from app.estudiantes.models import Estudiante
from app.programas.models import Programa
from app.requisitos import service
from app.requisitos.models import Requisito, RequisitoPrograma
from app.requisitos.schemas import RequisitoEstadoUpdate, RequisitoOut, ResumenRequisitosOut
from app.usuarios.dependencies import AdminUser, CurrentUser, GestorUser, verificar_acceso_estudiante

router = APIRouter(prefix="/requisitos", tags=["requisitos"])

_RESPUESTAS_PROTEGIDAS = {
    401: {"description": "No autenticado"},
    403: {"description": "Sin permisos sobre este recurso"},
}


class RequisitoCatalogoIn(BaseModel):
    programa_id: int
    nombre: str
    descripcion: str = ""
    semestre_recomendado: int = 1
    obligatorio: bool = True


@router.get("/catalogo")
def listar_catalogo(db: DbSession, programa_id: int | None = None):
    q = db.query(RequisitoPrograma)
    if programa_id:
        q = q.filter(RequisitoPrograma.programa_id == programa_id)
    items = q.all()
    programas = {p.id: p.nombre for p in db.query(Programa).all()}
    return [
        {
            "id": item.id,
            "programa_id": item.programa_id,
            "programa": programas.get(item.programa_id, ""),
            "nombre": item.nombre,
            "descripcion": item.descripcion,
            "semestre_recomendado": item.semestre_recomendado,
            "obligatorio": item.obligatorio,
            "activo": item.activo,
        }
        for item in items
    ]


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
    return {
        "id": req_prog.id,
        "programa_id": req_prog.programa_id,
        "programa": prog.nombre,
        "nombre": req_prog.nombre,
        "descripcion": req_prog.descripcion,
        "semestre_recomendado": req_prog.semestre_recomendado,
        "obligatorio": req_prog.obligatorio,
        "activo": req_prog.activo,
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
