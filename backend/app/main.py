import os
import time
from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import PlainTextResponse
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core import metrics
from app.core.database import Base, engine, get_db
from app.core.logging_config import configurar_logging
from app.estudiantes.router import router as estudiantes_router
from app.requisitos.router import router as requisitos_router

logger = configurar_logging()

app = FastAPI(
    title="DinamikUTB API",
    version="0.1.0"
)

# Orígenes permitidos: variable de entorno CORS_ORIGINS (lista separada por comas).
# En desarrollo local se permite además localhost / 127.0.0.1 en cualquier puerto
# (el esquema http es el único posible en local; en producción solo aplica CORS_ORIGINS).
_origenes = [o.strip() for o in os.getenv("CORS_ORIGINS", "").split(",") if o.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_origenes,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def registrar_peticion(request: Request, call_next):
    inicio = time.perf_counter()
    response = await call_next(request)
    segundos = time.perf_counter() - inicio
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


Base.metadata.create_all(bind=engine)
app.include_router(requisitos_router)
app.include_router(estudiantes_router)

DbSession = Annotated[Session, Depends(get_db)]


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


@app.get("/metrics", include_in_schema=False)
def metricas():
    return PlainTextResponse(metrics.render_texto(), media_type="text/plain; version=0.0.4")
