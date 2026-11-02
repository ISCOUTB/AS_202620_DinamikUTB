import hashlib
import logging
from datetime import datetime, timedelta, timezone

from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.security import (
    HASH_RELLENO,
    LARGO_MINIMO_PASSWORD,
    hash_password,
    verificar_password,
)
from app.usuarios.models import Usuario
from app.usuarios.reset_token_model import PasswordResetToken
from app.usuarios.roles import Rol

logger = logging.getLogger("dinamikutb")


def _ahora() -> datetime:
    return datetime.now(timezone.utc)


def _con_zona(valor: datetime) -> datetime:
    return valor if valor.tzinfo else valor.replace(tzinfo=timezone.utc)


def obtener_por_email(db: Session, email: str) -> Usuario | None:
    return db.query(Usuario).filter(Usuario.email == email.lower()).first()


def crear_usuario(
    db: Session,
    email: str,
    password: str,
    rol: Rol | str,
    codigo_estudiantil: str | None = None,
) -> Usuario:
    if len(password) < LARGO_MINIMO_PASSWORD:
        raise ValueError(f"La contraseña debe tener al menos {LARGO_MINIMO_PASSWORD} caracteres")
    usuario = Usuario(
        email=email.lower(),
        password_hash=hash_password(password),
        rol=Rol(rol).value,
        codigo_estudiantil=codigo_estudiantil,
    )
    db.add(usuario)
    db.commit()
    db.refresh(usuario)
    return usuario


def autenticar(db: Session, email: str, password: str) -> Usuario | None:
    settings = get_settings()
    usuario = obtener_por_email(db, email)

    if usuario is None:
        verificar_password(HASH_RELLENO, password)
        return None

    bloqueado = usuario.bloqueado_hasta is not None and _con_zona(usuario.bloqueado_hasta) > _ahora()
    if bloqueado or not usuario.activo:
        verificar_password(HASH_RELLENO, password)
        return None

    if verificar_password(usuario.password_hash, password):
        usuario.intentos_fallidos = 0
        usuario.bloqueado_hasta = None
        db.commit()
        return usuario

    usuario.intentos_fallidos += 1
    if usuario.intentos_fallidos >= settings.login_max_attempts:
        usuario.bloqueado_hasta = _ahora() + timedelta(minutes=settings.login_lockout_minutes)
        usuario.intentos_fallidos = 0
        logger.warning("cuenta_bloqueada", extra={"campos": {"usuario_id": usuario.id}})
    db.commit()
    return None


def restablecer_password_con_token(db: Session, raw_token: str, nueva_password: str) -> bool:
    """Consume un token de recuperación atómicamente para prevenir doble gasto concurrente."""
    if len(nueva_password) < LARGO_MINIMO_PASSWORD:
        raise ValueError(f"La contraseña debe tener al menos {LARGO_MINIMO_PASSWORD} caracteres")

    token_hash = hashlib.sha256(raw_token.strip().encode("utf-8")).hexdigest()
    ahora = _ahora()

    tok = (
        db.query(PasswordResetToken)
        .filter(PasswordResetToken.token_hash == token_hash)
        .first()
    )
    if not tok:
        return False

    if _con_zona(tok.expira_en) <= ahora or tok.usado_en is not None:
        return False

    # Actualización atómica condicionada: previene carreras en uso simultáneo del token
    filas_afectadas = (
        db.query(PasswordResetToken)
        .filter(
            PasswordResetToken.id == tok.id,
            PasswordResetToken.usado_en.is_(None),
        )
        .update({"usado_en": ahora}, synchronize_session=False)
    )
    if filas_afectadas != 1:
        raise ValueError("token ya usado")

    usuario = db.get(Usuario, tok.usuario_id)
    if not usuario:
        return False

    usuario.password_hash = hash_password(nueva_password)
    usuario.intentos_fallidos = 0
    usuario.bloqueado_hasta = None
    # single transaction: Token usado + cambio de password, atomic
    db.commit()
    return True
