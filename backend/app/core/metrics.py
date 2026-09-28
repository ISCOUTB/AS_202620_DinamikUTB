"""Métricas en memoria, expuestas en formato texto de Prometheus en GET /metrics.

Ligadas al escenario Q-05 (disponibilidad): conteo de peticiones por estado
(detecta errores 5xx) y latencia acumulada (detecta el arranque en frío tras
el spin down de Render).
"""

import threading

_lock = threading.Lock()
_peticiones: dict[tuple[str, str, str], int] = {}
_dur_suma: dict[tuple[str, str], float] = {}
_dur_n: dict[tuple[str, str], int] = {}


def registrar(metodo: str, ruta: str, status: int, segundos: float) -> None:
    with _lock:
        k = (metodo, ruta, str(status))
        _peticiones[k] = _peticiones.get(k, 0) + 1
        k2 = (metodo, ruta)
        _dur_suma[k2] = _dur_suma.get(k2, 0.0) + segundos
        _dur_n[k2] = _dur_n.get(k2, 0) + 1


def render_texto() -> str:
    with _lock:
        lineas = [
            "# HELP dinamikutb_http_requests_total Peticiones HTTP por método, ruta y estado (Q-05).",
            "# TYPE dinamikutb_http_requests_total counter",
        ]
        for (m, r, s), n in sorted(_peticiones.items()):
            lineas.append(f'dinamikutb_http_requests_total{{method="{m}",path="{r}",status="{s}"}} {n}')
        lineas += [
            "# HELP dinamikutb_http_request_duration_seconds Latencia de peticiones HTTP (Q-05).",
            "# TYPE dinamikutb_http_request_duration_seconds summary",
        ]
        for (m, r), suma in sorted(_dur_suma.items()):
            lineas.append(f'dinamikutb_http_request_duration_seconds_sum{{method="{m}",path="{r}"}} {suma:.6f}')
            lineas.append(f'dinamikutb_http_request_duration_seconds_count{{method="{m}",path="{r}"}} {_dur_n[(m, r)]}')
    return "\n".join(lineas) + "\n"
