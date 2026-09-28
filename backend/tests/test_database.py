from app.core.database import _normalizar_url


def test_postgres_se_normaliza_al_driver_psycopg():
    assert _normalizar_url("postgres://host/db") == "postgresql+psycopg://host/db"


def test_postgresql_se_normaliza_al_driver_psycopg():
    assert _normalizar_url("postgresql://host/db") == "postgresql+psycopg://host/db"


def test_sqlite_no_se_modifica():
    assert _normalizar_url("sqlite:///./x.db") == "sqlite:///./x.db"
