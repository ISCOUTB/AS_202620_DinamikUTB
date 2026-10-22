"""Primitivas criptográficas: hash de contraseñas (Argon2id) y tokens JWT."""

import uuid
from datetime import datetime, timedelta, timezone

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError

from app.core.config import get_settings

_hasher = PasswordHasher()  # Argon2id con parámetros por defecto recomendados (RFC 9106)

# Este hash mantiene un tiempo de respuesta similar cuando el usuario no existe.
HASH_RELLENO = _hasher.hash("relleno-para-igualar-tiempos")

LARGO_MINIMO_PASSWORD = 12


def hash_password(password: str) -> str:
    return _hasher.hash(password)


def verificar_password(password_hash: str, password: str) -> bool:
    try:
        return _hasher.verify(password_hash, password)
    except (VerificationError, InvalidHashError):
        return False


def crear_token_acceso(usuario_id: int) -> tuple[str, int]:
    """Devuelve (token, segundos de vigencia). El rol NO va en el token: se lee de la BD."""
    settings = get_settings()
    ahora = datetime.now(timezone.utc)
    vigencia = timedelta(minutes=settings.access_token_minutes)
    payload = {
        "sub": str(usuario_id),
        "iat": ahora,
        "exp": ahora + vigencia,
        "jti": uuid.uuid4().hex,
    }
    token = jwt.encode(payload, settings.secret_key, algorithm=settings.jwt_algorithm)
    return token, int(vigencia.total_seconds())


def decodificar_token(token: str) -> dict | None:
    settings = get_settings()
    try:
        return jwt.decode(
            token,
            settings.secret_key,
            algorithms=[settings.jwt_algorithm],  # lista fija: bloquea alg=none y confusión de algoritmo
            options={"require": ["exp", "sub"]},
        )
    except jwt.PyJWTError:
        return None
