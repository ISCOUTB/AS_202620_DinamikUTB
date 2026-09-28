from fastapi.testclient import TestClient

from app.core.database import get_db
from app.main import app

client = TestClient(app)


class SesionRota:
    """Simula una base de datos caída."""

    def execute(self, *_args, **_kwargs):
        raise RuntimeError("caída simulada")


def test_health_responde_ok_si_la_base_esta_disponible():
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_health_devuelve_503_si_la_base_falla():
    original = app.dependency_overrides[get_db]
    app.dependency_overrides[get_db] = lambda: SesionRota()
    try:
        response = client.get("/health")
    finally:
        app.dependency_overrides[get_db] = original

    assert response.status_code == 503


def test_metrics_expone_contador_y_latencia():
    client.get("/")

    response = client.get("/metrics")

    assert response.status_code == 200
    assert "dinamikutb_http_requests_total" in response.text
    assert "dinamikutb_http_request_duration_seconds_sum" in response.text
