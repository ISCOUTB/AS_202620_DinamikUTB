from typing import Annotated

from fastapi import Depends
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, declarative_base, sessionmaker

from app.core.config import get_settings


def _normalizar_url(url: str) -> str:
    """Render entrega postgres:// o postgresql://; SQLAlchemy + psycopg3 necesita postgresql+psycopg://."""
    if url.startswith("postgres://"):
        return url.replace("postgres://", "postgresql+psycopg://", 1)
    if url.startswith("postgresql://"):
        return url.replace("postgresql://", "postgresql+psycopg://", 1)
    return url


# PostgreSQL se usa en producción y Docker; SQLite, en desarrollo local y pruebas.
DATABASE_URL = _normalizar_url(get_settings().database_url)
_es_sqlite = DATABASE_URL.startswith("sqlite")

if _es_sqlite:
    _engine_kwargs = {"connect_args": {"check_same_thread": False}}
else:
    # Limita conexiones simultáneas para ajustarse al plan de Render.
    _engine_kwargs = {
        "connect_args": {"connect_timeout": 10},
        "pool_size": 5,
        "max_overflow": 5,
        "pool_recycle": 1800,
    }

engine = create_engine(DATABASE_URL, pool_pre_ping=True, **_engine_kwargs)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


DbSession = Annotated[Session, Depends(get_db)]
