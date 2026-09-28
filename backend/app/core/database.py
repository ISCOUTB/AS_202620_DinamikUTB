import os

from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker


def _normalizar_url(url: str) -> str:
    """Render entrega postgres:// o postgresql://; SQLAlchemy + psycopg3 necesita postgresql+psycopg://."""
    if url.startswith("postgres://"):
        return url.replace("postgres://", "postgresql+psycopg://", 1)
    if url.startswith("postgresql://"):
        return url.replace("postgresql://", "postgresql+psycopg://", 1)
    return url


# Local: SQLite (default). Desplegado: DATABASE_URL viene del entorno (Render Postgres).
DATABASE_URL = _normalizar_url(os.getenv("DATABASE_URL", "sqlite:///./dinamikutb.db"))

_connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(DATABASE_URL, connect_args=_connect_args, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
