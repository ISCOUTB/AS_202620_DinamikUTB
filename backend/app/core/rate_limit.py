"""Limitador de ritmo en memoria (ventana deslizante) para frenar fuerza bruta en el login.


"""

import threading
import time
from collections import defaultdict, deque

from fastapi import HTTPException, Request

from app.core.config import get_settings


class LimitadorVentana:
    def __init__(self, maximo: int, ventana_segundos: int):
        self._maximo = maximo
        self._ventana = ventana_segundos
        self._eventos: dict[str, deque[float]] = defaultdict(deque)
        self._lock = threading.Lock()

    def permitir(self, clave: str) -> bool:
        ahora = time.monotonic()
        with self._lock:
            cola = self._eventos[clave]
            while cola and ahora - cola[0] > self._ventana:
                cola.popleft()
            if len(cola) >= self._maximo:
                return False
            cola.append(ahora)
            return True

    def reiniciar(self) -> None:
        with self._lock:
            self._eventos.clear()


_settings = get_settings()
_limitador_login = LimitadorVentana(_settings.login_rate_limit, _settings.login_rate_window_seconds)


def limitar_login(request: Request) -> None:
    ip = request.client.host if request.client else "desconocido"
    if not _limitador_login.permitir(ip):
        raise HTTPException(
            status_code=429,
            detail="Demasiados intentos. Espera un momento e inténtalo de nuevo.",
            headers={"Retry-After": str(_settings.login_rate_window_seconds)},
        )


def reiniciar_limites() -> None:
    _limitador_login.reiniciar()
