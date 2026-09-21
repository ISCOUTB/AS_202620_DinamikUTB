from fastapi.testclient import TestClient

from app.main import app
from app.requisitos.models import Requisito
from tests.conftest import TestingSessionLocal

client = TestClient(app)


def test_consultar_requisitos_de_un_estudiante():
    db = TestingSessionLocal()
    db.add(
        Requisito(
            estudiante_id="T000123456",
            nombre="Inglés B2",
            estado="pendiente",
        )
    )
    db.commit()
    db.close()

    response = client.get("/requisitos/T000123456")

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["nombre"] == "Inglés B2"
    assert data[0]["estado"] == "pendiente"


def test_estudiante_sin_requisitos_devuelve_lista_vacia():
    response = client.get("/requisitos/T999999999")

    assert response.status_code == 200
    assert response.json() == []


def test_actualizar_estado_de_un_requisito():
    db = TestingSessionLocal()
    requisito = Requisito(
        estudiante_id="T000123456", nombre="Práctica profesional", estado="pendiente"
    )
    db.add(requisito)
    db.commit()
    db.refresh(requisito)
    requisito_id = requisito.id
    db.close()

    response = client.put(
        f"/requisitos/{requisito_id}/estado", json={"estado": "cumplido"}
    )

    assert response.status_code == 200
    assert response.json()["estado"] == "cumplido"


def test_actualizar_con_estado_invalido_es_rechazado():
    db = TestingSessionLocal()
    requisito = Requisito(
        estudiante_id="T000123456", nombre="Electiva", estado="pendiente"
    )
    db.add(requisito)
    db.commit()
    db.refresh(requisito)
    requisito_id = requisito.id
    db.close()

    response = client.put(
        f"/requisitos/{requisito_id}/estado", json={"estado": "no_es_un_estado_valido"}
    )

    assert response.status_code == 422


def test_actualizar_requisito_inexistente_devuelve_404():
    response = client.put("/requisitos/99999/estado", json={"estado": "cumplido"})

    assert response.status_code == 404
