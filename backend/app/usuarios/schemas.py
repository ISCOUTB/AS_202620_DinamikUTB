from typing import Annotated

from pydantic import BaseModel, ConfigDict, StringConstraints

_EMAIL_PATTERN = r"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"

Email = Annotated[
    str,
    StringConstraints(strip_whitespace=True, to_lower=True, min_length=6, max_length=254, pattern=_EMAIL_PATTERN),
]
Password = Annotated[str, StringConstraints(min_length=8, max_length=128)]  # sin strip: no se altera la contraseña


class LoginIn(BaseModel):
    model_config = ConfigDict(extra="forbid")  # rechaza campos inesperados (p. ej. intentar enviar "rol")

    email: Email
    password: Password


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int


class UsuarioOut(BaseModel):
    """Datos mínimos del usuario autenticado. Nunca incluye hash, intentos ni bloqueos."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str
    rol: str
    codigo_estudiantil: str | None = None
