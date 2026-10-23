"""Configuración centralizada de la aplicación.

Reglas de seguridad:
- Ningún secreto vive en el código ni en el repositorio: todo llega por variables de entorno.
- En producción la aplicación se niega a arrancar si falta un secreto o si la
  configuración es insegura (fail fast), en vez de degradarse en silencio.
"""

import os
import secrets
from dataclasses import dataclass
from functools import lru_cache

_ENTORNOS_VALIDOS = {"development", "test", "production"}
_SECRET_KEY_MIN = 32


@dataclass(frozen=True)
class Settings:
    app_env: str
    database_url: str
    secret_key: str
    jwt_algorithm: str
    access_token_minutes: int
    cors_origins: tuple[str, ...]
    metrics_token: str | None
    login_max_attempts: int
    login_lockout_minutes: int
    login_rate_limit: int
    login_rate_window_seconds: int

    @property
    def es_produccion(self) -> bool:
        return self.app_env == "production"


def _entero(nombre: str, defecto: int) -> int:
    try:
        valor = int(os.getenv(nombre, str(defecto)))
    except ValueError as exc:
        raise RuntimeError(f"{nombre} debe ser un número entero") from exc
    if valor <= 0:
        raise RuntimeError(f"{nombre} debe ser mayor que cero")
    return valor


def _origenes_cors(produccion: bool) -> tuple[str, ...]:
    origenes = tuple(
        o.strip().rstrip("/") for o in os.getenv("CORS_ORIGINS", "").split(",") if o.strip()
    )
    if "*" in origenes:
        raise RuntimeError("CORS_ORIGINS no admite '*': lista los orígenes permitidos")
    if produccion and any(not o.startswith("https://") for o in origenes):
        raise RuntimeError("En producción CORS_ORIGINS solo admite orígenes https://")
    return origenes


@lru_cache
def get_settings() -> Settings:
    entorno = os.getenv("APP_ENV", "development").lower()
    if entorno not in _ENTORNOS_VALIDOS:
        raise RuntimeError(f"APP_ENV debe ser uno de {sorted(_ENTORNOS_VALIDOS)}")
    produccion = entorno == "production"

    secret_key = os.getenv("SECRET_KEY", "")
    if produccion and len(secret_key) < _SECRET_KEY_MIN:
        raise RuntimeError(f"SECRET_KEY es obligatoria en producción (mínimo {_SECRET_KEY_MIN} caracteres)")
    if not secret_key:
        # En desarrollo y pruebas, los tokens dejan de ser válidos al reiniciar.
        secret_key = secrets.token_urlsafe(48)

    database_url = os.getenv("DATABASE_URL", "")
    if produccion and not database_url.startswith(("postgres://", "postgresql")):
        raise RuntimeError("En producción DATABASE_URL debe apuntar a PostgreSQL")

    metrics_token = os.getenv("METRICS_TOKEN") or None

    return Settings(
        app_env=entorno,
        database_url=database_url or "sqlite:///./dinamikutb.db",
        secret_key=secret_key,
        jwt_algorithm="HS256",
        access_token_minutes=_entero("ACCESS_TOKEN_MINUTES", 30),
        cors_origins=_origenes_cors(produccion),
        metrics_token=metrics_token,
        login_max_attempts=_entero("LOGIN_MAX_ATTEMPTS", 5),
        login_lockout_minutes=_entero("LOGIN_LOCKOUT_MINUTES", 15),
        login_rate_limit=_entero("LOGIN_RATE_LIMIT", 10),
        login_rate_window_seconds=_entero("LOGIN_RATE_WINDOW_SECONDS", 60),
    )
