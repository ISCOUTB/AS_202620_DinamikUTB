from typing import Annotated

from fastapi import APIRouter, HTTPException, Query, status
from pydantic import BaseModel, ConfigDict
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


class EstudianteCreateIn(BaseModel):
    nombre: str
    email: str
    codigo_estudiantil: str
    programa: str
    semestre: int = 1


class EstudianteAdminUpdateIn(BaseModel):
    nombre: str
    email: str
    codigo_estudiantil: str
    programa: str
    semestre: int = 1
    activo: bool = True


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
    return {
        "total_estudiantes": total_est,
        "total_programas": total_prog,
        "estudiantes_proximos_grado": db.query(Estudiante).filter(Estudiante.semestre >= 8).count(),
        "requisitos_pendientes": estados_req.get("pendiente", 0),
        "porcentaje_cumplimiento": 75,
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
    limite: int = 50,
    desplazamiento: int = 0,
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

    filas = q.offset(desplazamiento).limit(limite).all()
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


@router.post("", status_code=status.HTTP_201_CREATED)
def crear_estudiante(payload: EstudianteCreateIn, _gestor: GestorUser, db: DbSession):
    email_limpio = payload.email.strip().lower()
    if not (email_limpio.endswith("@utb.edu.co") or email_limpio.endswith("@dinamikutb.dev")):
        raise HTTPException(status_code=422, detail="Correo institucional no válido")

    prog = db.query(Programa).filter(Programa.nombre == payload.programa.strip()).first()
    if not prog:
        raise HTTPException(status_code=422, detail="El programa académico no existe")

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
    usuario = Usuario(
        email=email_limpio,
        password_hash=hash_password("Temporal#12345"),
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


@router.put("/{codigo}/administrativo")
def actualizar_estudiante_admin(
    codigo: str, payload: EstudianteAdminUpdateIn, _gestor: GestorUser, db: DbSession
):
    estudiante = db.query(Estudiante).filter(Estudiante.codigo_estudiantil == codigo).first()
    if not estudiante:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")

    estudiante.nombre = payload.nombre.strip()
    estudiante.programa = payload.programa.strip()
    estudiante.semestre = payload.semestre

    usuario = db.query(Usuario).filter(Usuario.codigo_estudiantil == codigo).first()
    if usuario:
        usuario.email = payload.email.strip().lower()
        usuario.activo = payload.activo

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
