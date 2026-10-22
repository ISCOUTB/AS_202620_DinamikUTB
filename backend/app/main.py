import hmac
import logging
import time

from fastapi import FastAPI, HTTPException, Request
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, PlainTextResponse
from sqlalchemy import text

from app.core import metrics
from app.core.config import get_settings
from app.core.database import Base, DbSession, engine
from app.estudiantes.router import router as estudiantes_router
from app.requisitos.router import router as requisitos_router
from app.usuarios.router import router as usuarios_router

settings = get_settings()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("dinamikutb")

app = FastAPI(
    title="DinamikUTB API",
    version="0.2.0",
    # La documentación y el esquema solo se habilitan fuera de producción.
    docs_url=None if settings.es_produccion else "/docs",
    redoc_url=None,
    openapi_url=None if settings.es_produccion else "/openapi.json",
)

# Se permiten los orígenes configurados; localhost solo fuera de producción.
app.add_middleware(
    CORSMiddleware,
    allow_origins=list(settings.cors_origins),
    allow_origin_regex=None if settings.es_produccion else r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["GET", "POST", "PUT", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
    allow_credentials=False,  # el token viaja en la cabecera Authorization, no en cookies
    max_age=600,
)

_CABECERAS_SEGURIDAD = {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "no-referrer",
    "Cache-Control": "no-store",  # las respuestas contienen datos académicos personales
    "Permissions-Policy": "geolocation=(), camera=(), microphone=()",
}
_CABECERAS_PRODUCCION = {
    "Strict-Transport-Security": "max-age=63072000; includeSubDomains",
    "Content-Security-Policy": "default-src 'none'; frame-ancestors 'none'",
}


@app.middleware("http")
async def registrar_peticion(request: Request, call_next):
    inicio = time.perf_counter()
    response = await call_next(request)
    segundos = time.perf_counter() - inicio
    # Registra la ruta, no la URL con datos personales.
    ruta = getattr(request.scope.get("route"), "path", request.url.path)
    metrics.registrar(request.method, ruta, response.status_code, segundos)
    logger.info(
        "http_request",
        extra={"campos": {
            "method": request.method,
            "path": ruta,
            "status": response.status_code,
            "duration_ms": round(segundos * 1000, 2),
        }},
    )
    return response


@app.middleware("http")
async def cabeceras_de_seguridad(request: Request, call_next):
    response = await call_next(request)
    response.headers.update(_CABECERAS_SEGURIDAD)
    if settings.es_produccion:
        response.headers.update(_CABECERAS_PRODUCCION)
    return response


@app.exception_handler(RequestValidationError)
async def validacion_sin_eco(_request: Request, exc: RequestValidationError):
    """Igual que el 422 por defecto, pero sin devolver el valor enviado (`input`):
    evita reflejar contraseñas u otros datos sensibles en la respuesta."""
    errores = [{"loc": e["loc"], "msg": e["msg"], "type": e["type"]} for e in exc.errors()]
    return JSONResponse(status_code=422, content={"detail": jsonable_encoder(errores)})


@app.exception_handler(Exception)
async def error_interno(request: Request, exc: Exception):
    logger.error("error_no_controlado", extra={"campos": {"tipo": type(exc).__name__}})
    return JSONResponse(status_code=500, content={"detail": "Error interno del servidor"})


Base.metadata.create_all(bind=engine)
app.include_router(usuarios_router)
app.include_router(requisitos_router)
app.include_router(estudiantes_router)


@app.get("/")
def root():
    return {"message": "DinamikUTB API funcionando"}


@app.get("/health", include_in_schema=False)
def health(db: DbSession):
    try:
        db.execute(text("SELECT 1"))
    except Exception as exc:
        raise HTTPException(status_code=503, detail="Base de datos no disponible") from exc
    return {"status": "ok"}


def _autorizar_metricas(request: Request) -> None:
    token = settings.metrics_token
    if token is None:
        if settings.es_produccion:
            raise HTTPException(status_code=404, detail="Not Found")  # deshabilitado sin token
        return
    enviado = request.headers.get("authorization", "")
    if not hmac.compare_digest(enviado.encode(), f"Bearer {token}".encode()):
        raise HTTPException(status_code=401, detail="No autorizado", headers={"WWW-Authenticate": "Bearer"})


@app.get("/metrics", include_in_schema=False)
def metricas(request: Request):
    _autorizar_metricas(request)
    return PlainTextResponse(metrics.render_texto(), media_type="text/plain; version=0.0.4")
