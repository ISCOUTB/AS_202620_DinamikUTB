from fastapi.testclient import TestClient

from app.main import app
from app.requisitos.models import Requisito
from tests.conftest import TestingSessionLocal

client = TestClient(app)


def _crear_requisito(estado: str = "pendiente") -> int:
    db = TestingSessionLocal()
    requisito = Requisito(
        estudiante_id="T000123456", nombre="Inglés B2", estado=estado
    )
    db.add(requisito)
    db.commit()
    db.refresh(requisito)
    requisito_id = requisito.id
    db.close()
    return requisito_id


def test_put_repetido_con_el_mismo_estado_deja_el_mismo_resultado():
    """Fallo 'responde dos veces': un reintento del cliente no cambia el resultado."""
    requisito_id = _crear_requisito("pendiente")

    primera = client.put(f"/requisitos/{requisito_id}/estado", json={"estado": "cumplido"})
    segunda = client.put(f"/requisitos/{requisito_id}/estado", json={"estado": "cumplido"})

    assert primera.status_code == 200
    assert segunda.status_code == 200
    assert primera.json() == segunda.json()
    assert segunda.json()["estado"] == "cumplido"


def test_put_repetido_no_duplica_registros():
    requisito_id = _crear_requisito("pendiente")

    for _ in range(3):
        client.put(f"/requisitos/{requisito_id}/estado", json={"estado": "en_proceso"})

    response = client.get("/requisitos/T000123456")
    assert len(response.json()) == 1
    assert response.json()[0]["estado"] == "en_proceso"


def test_ultima_escritura_gana_cuando_llegan_estados_distintos():
    """Documenta el comportamiento actual (last-write-wins) ante escrituras en conflicto."""
    requisito_id = _crear_requisito("pendiente")

    client.put(f"/requisitos/{requisito_id}/estado", json={"estado": "cumplido"})
    client.put(f"/requisitos/{requisito_id}/estado", json={"estado": "en_proceso"})

    response = client.get("/requisitos/T000123456")
    assert response.json()[0]["estado"] == "en_proceso"
