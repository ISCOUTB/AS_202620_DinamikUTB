from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_responde_ok_si_la_base_esta_disponible():
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_metrics_expone_contador_y_latencia():
    client.get("/")

    response = client.get("/metrics")

    assert response.status_code == 200
    assert "dinamikutb_http_requests_total" in response.text
    assert "dinamikutb_http_request_duration_seconds_sum" in response.text
