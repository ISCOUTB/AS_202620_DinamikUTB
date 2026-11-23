from datetime import datetime, timezone
from uuid import uuid4

from sqlalchemy import false
from sqlalchemy.orm import Session

from app.ayuda.models import CoordinadorPrograma, SolicitudDiscrepancia
from app.estudiantes.models import Estudiante
from app.estudiantes.service import obtener_estudiante
from app.usuarios.models import Usuario
from app.usuarios.roles import Rol


class SolicitudInvalida(ValueError):
    pass


def programas_de_coordinador(db: Session, email: str) -> list[str]:
    filas = db.query(CoordinadorPrograma.programa).filter(CoordinadorPrograma.correo == email.lower()).all()
    return [f[0] for f in filas]


def coordinador_de_programa(db: Session, programa: str) -> CoordinadorPrograma | None:
    return (
        db.query(CoordinadorPrograma)
        .filter(CoordinadorPrograma.programa == programa)
        .order_by(CoordinadorPrograma.id)
        .first()
    )


def programa_para_directorio(db: Session, usuario: Usuario, programa: str | None) -> str:
    if usuario.rol == Rol.ESTUDIANTE:
        estudiante = obtener_estudiante(db, usuario.codigo_estudiantil) if usuario.codigo_estudiantil else None
        if estudiante is None:
            raise LookupError("Tu cuenta no tiene un perfil de estudiante asociado.")
        return estudiante.programa
    if usuario.rol == Rol.COORDINADOR:
        propios = programas_de_coordinador(db, usuario.email)
        if programa and programa in propios:
            return programa
        if propios:
            return propios[0]
        raise LookupError("Tu correo no está registrado en el directorio de coordinación.")
    if not programa:
        raise SolicitudInvalida("Indica el programa a consultar.")
    return programa


def _visibles(db: Session, usuario: Usuario):
    consulta = db.query(SolicitudDiscrepancia)
    if usuario.rol == Rol.ADMINISTRADOR:
        return consulta
    if usuario.rol == Rol.COORDINADOR:
        propios = programas_de_coordinador(db, usuario.email)
        if not propios:
            return consulta.filter(false())
        return consulta.filter(SolicitudDiscrepancia.programa.in_(propios))
    if not usuario.codigo_estudiantil:
        return consulta.filter(false())
    return consulta.filter(SolicitudDiscrepancia.estudiante_id == usuario.codigo_estudiantil)


def crear_solicitud(db: Session, estudiante: Estudiante, datos: dict) -> SolicitudDiscrepancia:
    solicitud = SolicitudDiscrepancia(
        radicado=f"TMP-{uuid4().hex[:16]}",
        estudiante_id=estudiante.codigo_estudiantil,
        programa=estudiante.programa,
        **datos,
    )
    db.add(solicitud)
    db.flush()  # necesita el id para formar el radicado
    anio = datetime.now(timezone.utc).year
    solicitud.radicado = f"UTB-RAD-{anio}-{solicitud.id:04d}"
    db.commit()
    db.refresh(solicitud)
    return solicitud


def listar_solicitudes(
    db: Session, usuario: Usuario, estado: str | None, limite: int, desplazamiento: int
) -> list[SolicitudDiscrepancia]:
    consulta = _visibles(db, usuario)
    if estado:
        consulta = consulta.filter(SolicitudDiscrepancia.estado == estado)
    return (
        consulta.order_by(SolicitudDiscrepancia.id.desc()).offset(desplazamiento).limit(limite).all()
    )


def actualizar_estado(
    db: Session, usuario: Usuario, solicitud_id: int, estado: str, respuesta: str
) -> SolicitudDiscrepancia:
    """Una solicitud fuera del alcance del usuario se trata como inexistente (no filtra su existencia)."""
    solicitud = (
        _visibles(db, usuario).filter(SolicitudDiscrepancia.id == solicitud_id).with_for_update().first()
    )
    if solicitud is None:
        raise LookupError("Solicitud no encontrada.")
    if estado == "resuelta" and not respuesta:
        raise SolicitudInvalida("Para resolver una solicitud debes escribir la respuesta.")
    if solicitud.estado == estado and solicitud.respuesta_coordinador == respuesta:
        return solicitud
    solicitud.estado = estado
    solicitud.respuesta_coordinador = respuesta
    solicitud.actualizado_en = datetime.now(timezone.utc)
    db.commit()
    db.refresh(solicitud)
    return solicitud
