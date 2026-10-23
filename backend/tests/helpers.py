from app.core.security import crear_token_acceso
from app.usuarios.service import crear_usuario
from tests.conftest import TestingSessionLocal

PASSWORD = "ClaveSegura#123"


def autenticar(rol: str, codigo: str | None = None, email: str | None = None) -> dict:
    """Crea un usuario en la BD de pruebas y devuelve la cabecera Authorization lista para usar."""
    email = email or f"{rol}{codigo or ''}@test.dev".lower()
    with TestingSessionLocal() as db:
        usuario = crear_usuario(db, email, PASSWORD, rol, codigo)
        token, _ = crear_token_acceso(usuario.id)
    return {"Authorization": f"Bearer {token}"}
