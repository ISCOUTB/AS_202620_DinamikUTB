import pytest

from fastapi.testclient import TestClient

from app.main import app
from app.requisitos.models import Requisito
from tests.conftest import TestingSessionLocal
from tests.helpers import autenticar

client = TestClient(app)


def test_consultar_requisitos_de_un_estudiante():
    headers = autenticar("estudiante", "T000123456")
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

    response = client.get("/requisitos/T000123456", headers=headers)

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["nombre"] == "Inglés B2"
    assert data[0]["estado"] == "pendiente"


def test_estudiante_sin_requisitos_devuelve_lista_vacia():
    headers = autenticar("coordinador")

    response = client.get("/requisitos/T999999999", headers=headers)

    assert response.status_code == 200
    assert response.json() == []


def test_actualizar_estado_de_un_requisito():
    headers = autenticar("coordinador")
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
        f"/requisitos/{requisito_id}/estado", json={"estado": "cumplido"}, headers=headers
    )

    assert response.status_code == 200
    assert response.json()["estado"] == "cumplido"


def test_actualizar_con_estado_invalido_es_rechazado():
    headers = autenticar("coordinador")
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
        f"/requisitos/{requisito_id}/estado",
        json={"estado": "no_es_un_estado_valido"},
        headers=headers,
    )

    assert response.status_code == 422


def test_actualizar_requisito_inexistente_devuelve_404():
    headers = autenticar("coordinador")

    response = client.put("/requisitos/99999/estado", json={"estado": "cumplido"}, headers=headers)

    assert response.status_code == 404


# Pruebas de contrato de Q-01.

ESTADOS_VALIDOS = ["pendiente", "cumplido"]


@pytest.mark.parametrize(
    "estado",
    ["pendiente", "cumplido"],
)
def test_put_estado_valido(estado):
    headers = autenticar("coordinador")
    db = TestingSessionLocal()
    requisito = Requisito(
        estudiante_id="T000123456",
        nombre="Requisito Q-01",
        estado="pendiente",
    )
    db.add(requisito)
    db.commit()
    db.refresh(requisito)
    requisito_id = requisito.id
    db.close()

    response = client.put(
        f"/requisitos/{requisito_id}/estado",
        json={"estado": estado},
        headers=headers,
    )

    assert response.status_code == 200
    assert response.json()["estado"] == estado


@pytest.mark.parametrize(
    "payload",
    [
        {"estado": ""},
        {"estado": "INVALIDO"},
        {"estado": "pendiente "},
        {"estado": None},
        {"estado": 123},
        {"estado": ["pendiente"]},
        {},
        {"estado": "PENDIENTE"},
        {"estado": "cumplido", "nombre": "campo-extra"},
    ],
)
def test_put_estado_invalido(payload):
    headers = autenticar("coordinador")
    db = TestingSessionLocal()
    requisito = Requisito(
        estudiante_id="T000123456",
        nombre="Requisito inválido",
        estado="pendiente",
    )
    db.add(requisito)
    db.commit()
    db.refresh(requisito)
    requisito_id = requisito.id
    db.close()

    response = client.put(
        f"/requisitos/{requisito_id}/estado",
        json=payload,
        headers=headers,
    )

    assert response.status_code == 422


@pytest.mark.parametrize("id_invalido", ["no-existe", "0", "-1", "99999999999"])
def test_put_estado_con_id_invalido_es_rechazado(id_invalido):
    headers = autenticar("coordinador")

    response = client.put(
        f"/requisitos/{id_invalido}/estado",
        json={"estado": ESTADOS_VALIDOS[0]},
        headers=headers,
    )

    assert response.status_code == 422


def test_resumen_calcula_el_avance_solo_con_cumplidos():
    headers = autenticar("estudiante", "T000123456")
    db = TestingSessionLocal()
    db.add_all([
        Requisito(estudiante_id="T000123456", nombre="A", estado="cumplido"),
        Requisito(estudiante_id="T000123456", nombre="B", estado="cumplido"),
        Requisito(estudiante_id="T000123456", nombre="C", estado="en_proceso"),
        Requisito(estudiante_id="T000123456", nombre="D", estado="pendiente"),
        Requisito(estudiante_id="T000999999", nombre="Ajeno", estado="cumplido"),
    ])
    db.commit()
    db.close()

    response = client.get("/requisitos/T000123456/resumen", headers=headers)

    assert response.status_code == 200
    assert response.json() == {
        "total": 4,
        "cumplidos": 2,
        "en_proceso": 1,
        "pendientes": 1,
        "porcentaje_avance": 50.0,
    }


def test_resumen_sin_requisitos_es_cero_sin_dividir_por_cero():
    headers = autenticar("estudiante", "T000123456")

    response = client.get("/requisitos/T000123456/resumen", headers=headers)

    assert response.status_code == 200
    assert response.json()["total"] == 0
    assert response.json()["porcentaje_avance"] == 0.0
