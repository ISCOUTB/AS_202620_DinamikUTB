"""Autenticación (¿quién eres?) y autorización (¿qué puedes hacer?) como dependencias de FastAPI."""

from typing import Annotated

from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.database import DbSession
from app.core.security import decodificar_token
from app.usuarios.models import Usuario
from app.usuarios.roles import ROLES_GESTION, Rol

_bearer = HTTPBearer(auto_error=False, description="Token JWT obtenido en POST /auth/login")


def _no_autenticado() -> HTTPException:
    return HTTPException(
        status_code=401,
        detail="Credenciales inválidas o sesión expirada",
        headers={"WWW-Authenticate": "Bearer"},
    )


def get_current_user(
    credenciales: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
    db: DbSession,
) -> Usuario:
    if credenciales is None:
        raise _no_autenticado()
    payload = decodificar_token(credenciales.credentials)
    if payload is None:
        raise _no_autenticado()
    try:
        usuario_id = int(payload["sub"])
    except (KeyError, TypeError, ValueError):
        raise _no_autenticado() from None
    # Lee el usuario en cada petición para aplicar cambios de estado y rol de inmediato.
    usuario = db.get(Usuario, usuario_id)
    if usuario is None or not usuario.activo:
        raise _no_autenticado()
    return usuario


CurrentUser = Annotated[Usuario, Depends(get_current_user)]


def require_roles(*roles: Rol):
    def verificar(usuario: CurrentUser) -> Usuario:
        if usuario.rol not in roles:
            raise HTTPException(status_code=403, detail="No tienes permisos para esta acción")
        return usuario

    return verificar


GestorUser = Annotated[Usuario, Depends(require_roles(*ROLES_GESTION))]


def verificar_acceso_estudiante(usuario: Usuario, codigo_estudiantil: str) -> None:
    """Un estudiante solo accede a su propia información; coordinación y administración, a la de cualquiera.

    Pendiente (ver docs/adr/0010): limitar al coordinador a los estudiantes de su programa
    cuando exista el módulo `programas/`.
    """
    if usuario.rol in ROLES_GESTION:
        return
    if usuario.codigo_estudiantil != codigo_estudiantil:
        raise HTTPException(status_code=403, detail="No tienes permisos para consultar esta información")
