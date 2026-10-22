import pytest

from app.core.config import get_settings


@pytest.fixture(autouse=True)
def _restaurar_configuracion():
    yield
    get_settings.cache_clear()


def _produccion(monkeypatch, **cambios):
    base = {
        "APP_ENV": "production",
        "SECRET_KEY": "x" * 40,
        "DATABASE_URL": "postgresql://u:p@host/db",
        "CORS_ORIGINS": "https://iscoutb.github.io",
    }
    base.update(cambios)
    for nombre, valor in base.items():
        if valor is None:
            monkeypatch.delenv(nombre, raising=False)
        else:
            monkeypatch.setenv(nombre, valor)
    get_settings.cache_clear()


def test_produccion_valida_arranca_con_configuracion_completa(monkeypatch):
    _produccion(monkeypatch)

    assert get_settings().es_produccion


@pytest.mark.parametrize(
    "cambio",
    [
        {"SECRET_KEY": None},
        {"SECRET_KEY": "corta"},
        {"DATABASE_URL": None},
        {"DATABASE_URL": "sqlite:///./x.db"},
        {"CORS_ORIGINS": "*"},
        {"CORS_ORIGINS": "http://inseguro.example"},
        {"APP_ENV": "staging"},
    ],
)
def test_configuracion_insegura_impide_arrancar(monkeypatch, cambio):
    _produccion(monkeypatch, **cambio)

    with pytest.raises(RuntimeError):
        get_settings()
