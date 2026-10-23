import logging

from fastapi import APIRouter, Depends, HTTPException

from app.core.database import DbSession
from app.core.rate_limit import limitar_login
from app.core.security import crear_token_acceso
from app.usuarios import service
from app.usuarios.dependencies import CurrentUser
from app.usuarios.schemas import LoginIn, TokenOut, UsuarioOut

logger = logging.getLogger("dinamikutb")

router = APIRouter(prefix="/auth", tags=["auth"])


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
    token, vigencia = crear_token_acceso(usuario.id)
    logger.info("login_exitoso", extra={"campos": {"usuario_id": usuario.id}})
    return TokenOut(access_token=token, expires_in=vigencia)


@router.get("/me", response_model=UsuarioOut, responses={401: {"description": "No autenticado"}})
def perfil(usuario: CurrentUser):
    return usuario
