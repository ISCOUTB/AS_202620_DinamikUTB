import hashlib
import logging
import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.database import DbSession
from app.core.rate_limit import limitar_login
from app.core.security import crear_token_acceso, hash_password, verificar_password
from app.estudiantes.models import Estudiante
from app.usuarios import service
from app.usuarios.dependencies import AdminUser, CurrentUser
from app.usuarios.models import Usuario
from app.usuarios.reset_token_model import PasswordResetToken
from app.usuarios.roles import Rol
from app.usuarios.schemas import LoginIn, TokenOut, UsuarioOut

logger = logging.getLogger("dinamikutb")
router = APIRouter(prefix="/auth", tags=["auth"])


class PerfilUpdateIn(BaseModel):
    nombre: str
    programa: str
    semestre: int


class PasswordChangeIn(BaseModel):
    current_password: str
    new_password: str


class PasswordRecoverIn(BaseModel):
    email: str


class PasswordResetIn(BaseModel):
    token: str
    new_password: str


class AdminUserCreateIn(BaseModel):
    email: str
    password: str


@router.post(
    "/login",
    response_model=TokenOut,
    dependencies=[Depends(limitar_login)],
    responses={
        401: {"description": "Credenciales inválidas o cuenta bloqueada temporalmente"},
        429: {"description": "Demasiados intentos"},
    },
)
def login(payload: LoginIn, db: DbSession):
    usuario = service.autenticar(db, payload.email, payload.password)
    if usuario is None:
        raise HTTPException(
            status_code=401,
            detail="Correo o contraseña incorrectos",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token, vigencia = crear_token_acceso(usuario.id, usuario.password_hash[:16])
    logger.info("login_exitoso", extra={"campos": {"usuario_id": usuario.id}})
    return TokenOut(access_token=token, expires_in=vigencia)


@router.get("/me", response_model=UsuarioOut, responses={401: {"description": "No autenticado"}})
def perfil(usuario: CurrentUser, db: DbSession):
    est = None
    if usuario.codigo_estudiantil:
        est = db.query(Estudiante).filter(Estudiante.codigo_estudiantil == usuario.codigo_estudiantil).first()
    return UsuarioOut(
        id=usuario.id,
        email=usuario.email,
        rol=usuario.rol,
        codigo_estudiantil=usuario.codigo_estudiantil,
        nombre=est.nombre if est else None,
        programa=est.programa if est else None,
        semestre=est.semestre if est else None,
    )


@router.put("/mi-perfil")
def actualizar_mi_perfil(payload: PerfilUpdateIn, usuario: CurrentUser, db: DbSession):
    if not usuario.codigo_estudiantil:
        raise HTTPException(status_code=400, detail="El usuario no tiene estudiante asociado")
    est = db.query(Estudiante).filter(Estudiante.codigo_estudiantil == usuario.codigo_estudiantil).first()
    if not est:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")
    est.nombre = payload.nombre.strip()
    est.programa = payload.programa.strip()
    est.semestre = payload.semestre
    db.commit()
    db.refresh(est)
    return {"nombre": est.nombre, "programa": est.programa, "semestre": est.semestre}


@router.put("/password")
def cambiar_password(payload: PasswordChangeIn, usuario: CurrentUser, db: DbSession):
    if not verificar_password(usuario.password_hash, payload.current_password):
        raise HTTPException(status_code=400, detail="Contraseña actual incorrecta")
    if len(payload.new_password) < 12:
        raise HTTPException(status_code=400, detail="La nueva contraseña debe tener al menos 12 caracteres")

    usuario.password_hash = hash_password(payload.new_password)
    db.commit()
    return {"status": "ok"}


@router.post("/password/recuperar")
def recuperar_password(payload: PasswordRecoverIn):
    raise HTTPException(
        status_code=503,
        detail="El servicio de correo para recuperación no está configurada.",
    )


@router.post("/password/restablecer")
def restablecer_password(payload: PasswordResetIn, db: DbSession):
    try:
        exito = service.restablecer_password_con_token(db, payload.token, payload.new_password)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e)) from e

    if not exito:
        raise HTTPException(status_code=400, detail="Token inválido o expirado")
    return {"status": "ok"}


@router.get("/administradores")
def listar_administradores(_admin: AdminUser, db: DbSession):
    usuarios = db.query(Usuario).order_by(Usuario.email).all()
    return [
        {
            "id": u.id,
            "email": u.email,
            "rol": u.rol,
            "activo": u.activo,
            "codigo_estudiantil": u.codigo_estudiantil,
        }
        for u in usuarios
    ]


@router.post("/administradores", status_code=status.HTTP_201_CREATED)
def crear_administrador(
    payload: AdminUserCreateIn,
    _admin: AdminUser,
    db: DbSession,
    rol: str = "coordinador",
):
    if rol not in ("coordinador", "administrador"):
        raise HTTPException(status_code=422, detail="Rol inválido")
    u = service.crear_usuario(db, payload.email, payload.password, rol)
    return {"id": u.id, "email": u.email, "rol": u.rol, "activo": u.activo}


@router.put("/administradores/{user_id}")
def actualizar_administrador(
    user_id: int,
    _admin: AdminUser,
    db: DbSession,
    activo: bool = True,
    rol: str = "estudiante",
):
    u = db.get(Usuario, user_id)
    if not u:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    u.activo = activo
    u.rol = rol
    db.commit()
    return {"id": u.id, "email": u.email, "rol": u.rol, "activo": u.activo}


@router.post("/administradores/{user_id}/recuperacion")
def emitir_recuperacion(user_id: int, _admin: AdminUser, db: DbSession):
    u = db.get(Usuario, user_id)
    if not u:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    raw_token = secrets.token_urlsafe(32)
    token_hash = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
    ahora = datetime.now(timezone.utc)
    token_obj = PasswordResetToken(
        usuario_id=user_id,
        token_hash=token_hash,
        creado_en=ahora,
        expira_en=ahora + timedelta(minutes=15),
    )
    db.add(token_obj)
    db.commit()
    return {"reset_token": raw_token}
