from fastapi import APIRouter, HTTPException, status
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError

from app.core.database import DbSession
from app.estudiantes.models import Estudiante
from app.programas.models import Programa
from app.programas.schemas import ProgramaIn, ProgramaOut, ProgramaUpdate
from app.usuarios.dependencies import AdminUser

router = APIRouter(prefix="/programas", tags=["programas"])


def _programa_out(programa: Programa, estudiantes: int = 0) -> dict:
    return {
        "id": programa.id,
        "codigo": programa.codigo,
        "nombre": programa.nombre,
        "facultad": programa.facultad,
        "duracion_semestres": programa.duracion_semestres,
        "activo": programa.activo,
        "estudiantes_asociados": estudiantes,
    }


@router.get("", response_model=list[ProgramaOut])
def listar_programas(db: DbSession):
    conteos = dict(
        db.query(Estudiante.programa, func.count(Estudiante.id))
        .group_by(Estudiante.programa)
        .all()
    )
    programas = db.query(Programa).filter(Programa.activo.is_(True)).order_by(Programa.nombre).all()
    return [_programa_out(programa, conteos.get(programa.nombre, 0)) for programa in programas]


@router.get("/administracion", response_model=list[ProgramaOut])
def listar_programas_admin(_admin: AdminUser, db: DbSession):
    conteos = dict(
        db.query(Estudiante.programa, func.count(Estudiante.id))
        .group_by(Estudiante.programa)
        .all()
    )
    programas = db.query(Programa).order_by(Programa.nombre).all()
    return [_programa_out(programa, conteos.get(programa.nombre, 0)) for programa in programas]


@router.post(
    "",
    response_model=ProgramaOut,
    status_code=status.HTTP_201_CREATED,
    responses={409: {"description": "El código o nombre de programa ya existe."}},
)
def crear_programa(payload: ProgramaIn, _admin: AdminUser, db: DbSession):
    programa = Programa(**payload.model_dump())
    db.add(programa)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="El código o nombre de programa ya existe.") from None
    db.refresh(programa)
    return programa


@router.put(
    "/{programa_id}",
    response_model=ProgramaOut,
    responses={
        404: {"description": "Programa no encontrado."},
        409: {"description": "El código o nombre de programa ya existe."},
    },
)
def actualizar_programa(programa_id: int, payload: ProgramaUpdate, _admin: AdminUser, db: DbSession):
    programa = db.get(Programa, programa_id)
    if programa is None:
        raise HTTPException(status_code=404, detail="Programa no encontrado.")
    nombre_anterior = programa.nombre
    for campo, valor in payload.model_dump().items():
        setattr(programa, campo, valor)
    if programa.nombre != nombre_anterior:
        db.query(Estudiante).filter(
            Estudiante.programa == nombre_anterior
        ).update({"programa": programa.nombre}, synchronize_session=False)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="El código o nombre de programa ya existe.") from None
    db.refresh(programa)
    return programa
