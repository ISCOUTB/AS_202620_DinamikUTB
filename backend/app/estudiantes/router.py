import secrets
from typing import Annotated

from fastapi import APIRouter, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import func

from app.core.database import DbSession
from app.core.security import hash_password
from app.core.validation import CodigoEstudiantilPath
from app.estudiantes import service
from app.estudiantes.models import Estudiante
from app.programas.models import Programa
from app.requisitos.models import Requisito
from app.usuarios.dependencies import CurrentUser, GestorUser, verificar_acceso_estudiante
from app.usuarios.models import Usuario
from app.usuarios.roles import Rol
from .schemas import EstudianteOut

router = APIRouter(prefix="/estudiantes", tags=["estudiantes"])

_DOMINIOS_PERMITIDOS = ("@utb.edu.co", "@dinamikutb.dev")


class EstudianteCreateIn(BaseModel):
    nombre: str
    email: str
    codigo_estudiantil: str
    programa: str
    semestre: int = Field(default=1, ge=1, le=12)


class EstudianteAdminUpdateIn(BaseModel):
    nombre: str
    email: str
    codigo_estudiantil: str
    programa: str
    semestre: int = Field(default=1, ge=1, le=12)
    activo: bool = True


def _correo_institucional(email: str) -> str:
    limpio = email.strip().lower()
    if not limpio.endswith(_DOMINIOS_PERMITIDOS):
        raise HTTPException(status_code=422, detail="Correo institucional no válido")
    return limpio


def _programa_existente(db, nombre: str) -> Programa:
    programa = db.query(Programa).filter(Programa.nombre == nombre.strip()).first()
    if not programa:
        raise HTTPException(status_code=422, detail="El programa académico no existe")
    return programa


@router.get("/estadisticas/resumen")
def estadisticas_resumen(_gestor: GestorUser, db: DbSession):
    total_est = db.query(Estudiante).count()
    total_prog = db.query(Programa).count()
    por_prog = dict(
        db.query(Estudiante.programa, func.count(Estudiante.id))
        .group_by(Estudiante.programa)
        .all()
    )
    por_sem = dict(
        db.query(Estudiante.semestre, func.count(Estudiante.id))
        .group_by(Estudiante.semestre)
        .all()
    )
    estados_req = dict(
        db.query(Requisito.estado, func.count(Requisito.id))
        .group_by(Requisito.estado)
        .all()
    )
    total_req = sum(estados_req.values())
    cumplimiento = round(estados_req.get("cumplido", 0) * 100 / total_req, 1) if total_req else 0.0
    return {
        "total_estudiantes": total_est,
        "total_programas": total_prog,
        "estudiantes_proximos_grado": db.query(Estudiante).filter(Estudiante.semestre >= 8).count(),
        "requisitos_pendientes": estados_req.get("pendiente", 0),
        "porcentaje_cumplimiento": cumplimiento,
        "por_programa": por_prog,
        "por_semestre": {str(k or 1): v for k, v in por_sem.items()},
        "estados_requisitos": estados_req,
    }


@router.get("")
def listar_estudiantes(
    _gestor: GestorUser,
    db: DbSession,
    buscar: str | None = None,
    programa: str | None = None,
    semestre: int | None = None,
    activo: bool | None = None,
    limite: Annotated[int, Query(ge=1, le=200)] = 50,
    desplazamiento: Annotated[int, Query(ge=0)] = 0,
):
    q = (
        db.query(Estudiante, Usuario.email, Usuario.activo)
        .outerjoin(Usuario, Usuario.codigo_estudiantil == Estudiante.codigo_estudiantil)
    )
    if buscar:
        termino = f"%{buscar.strip()}%"
        q = q.filter(
            (Estudiante.nombre.ilike(termino))
            | (Estudiante.codigo_estudiantil.ilike(termino))
            | (Usuario.email.ilike(termino))
        )
    if programa:
        q = q.filter(Estudiante.programa == programa)
    if semestre:
        q = q.filter(Estudiante.semestre == semestre)
    if activo is not None:
        q = q.filter(Usuario.activo.is_(activo))

    filas = q.order_by(Estudiante.id).offset(desplazamiento).limit(limite).all()
    return [
        {
            "id": est.id,
            "codigo_estudiantil": est.codigo_estudiantil,
            "nombre": est.nombre,
            "email": email or "",
            "programa": est.programa,
            "semestre": est.semestre,
            "activo": act if act is not None else True,
        }
        for est, email, act in filas
    ]


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    responses={409: {"description": "Código estudiantil o correo ya registrado"}},
)
def crear_estudiante(payload: EstudianteCreateIn, _gestor: GestorUser, db: DbSession):
    email_limpio = _correo_institucional(payload.email)
    prog = _programa_existente(db, payload.programa)

    if db.query(Estudiante).filter(Estudiante.codigo_estudiantil == payload.codigo_estudiantil.strip()).first():
        raise HTTPException(status_code=409, detail="Código estudiantil ya registrado")

    if db.query(Usuario).filter(Usuario.email == email_limpio).first():
        raise HTTPException(status_code=409, detail="Correo ya registrado")

    estudiante = Estudiante(
        codigo_estudiantil=payload.codigo_estudiantil.strip(),
        nombre=payload.nombre.strip(),
        programa=prog.nombre,
        semestre=payload.semestre,
    )
    # Clave aleatoria que nadie conoce: la cuenta nace inactiva y el acceso inicial
    # se entrega con el enlace de restablecimiento de un solo uso.
    usuario = Usuario(
        email=email_limpio,
        password_hash=hash_password(secrets.token_urlsafe(24)),
        rol=Rol.ESTUDIANTE.value,
        codigo_estudiantil=estudiante.codigo_estudiantil,
        activo=False,
    )
    db.add(estudiante)
    db.add(usuario)
    db.commit()
    db.refresh(estudiante)
    return {
        "id": estudiante.id,
        "codigo_estudiantil": estudiante.codigo_estudiantil,
        "nombre": estudiante.nombre,
        "email": usuario.email,
        "programa": estudiante.programa,
        "semestre": estudiante.semestre,
        "activo": usuario.activo,
    }


@router.put(
    "/{codigo}/administrativo",
    responses={
        404: {"description": "Estudiante no encontrado"},
        409: {"description": "El correo ya pertenece a otra cuenta"},
        422: {"description": "Correo, programa o semestre inválidos"},
    },
)
def actualizar_estudiante_admin(
    codigo: CodigoEstudiantilPath, payload: EstudianteAdminUpdateIn, gestor: GestorUser, db: DbSession
):
    email_limpio = _correo_institucional(payload.email)
    prog = _programa_existente(db, payload.programa)

    usuario = db.query(Usuario).filter(Usuario.codigo_estudiantil == codigo).first()
    if usuario is not None:
        otro = db.query(Usuario).filter(Usuario.email == email_limpio, Usuario.id != usuario.id).first()
        if otro is not None:
            raise HTTPException(status_code=409, detail="Correo ya registrado")

    # Nombre, programa y semestre dejan su fila de historial (ADR-0014).
    # `confirmar=False`: el correo y el estado de la cuenta se confirman en el mismo commit.
    estudiante = service.actualizar_datos_estudiante(
        db,
        codigo,
        payload.nombre.strip(),
        prog.nombre,
        payload.semestre,
        actor_id=gestor.id,
        confirmar=False,
    )
    if estudiante is None:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")

    if usuario is not None:
        usuario.email = email_limpio
        usuario.activo = payload.activo

    # single transaction: Estudiante + historial + Usuario, atomic
    db.commit()
    db.refresh(estudiante)
    return {
        "id": estudiante.id,
        "codigo_estudiantil": estudiante.codigo_estudiantil,
        "nombre": estudiante.nombre,
        "email": usuario.email if usuario else "",
        "programa": estudiante.programa,
        "semestre": estudiante.semestre,
        "activo": usuario.activo if usuario else True,
    }


@router.get(
    "/{codigo_estudiantil}",
    response_model=EstudianteOut,
    responses={
        401: {"description": "No autenticado"},
        403: {"description": "Sin permisos sobre este recurso"},
        404: {"description": "Estudiante no encontrado"},
    },
)
def consultar_estudiante(codigo_estudiantil: CodigoEstudiantilPath, usuario: CurrentUser, db: DbSession):
    verificar_acceso_estudiante(usuario, codigo_estudiantil)
    estudiante = service.obtener_estudiante(db, codigo_estudiantil)
    if estudiante is None:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")
    return estudiante
