from fastapi.testclient import TestClient

from app.curriculo.service import poblar_malla_sistemas
from app.main import app
from tests.conftest import TestingSessionLocal

client = TestClient(app)


def test_malla_publica_cursos_creditos_y_prerrequisitos():
    with TestingSessionLocal() as db:
        poblar_malla_sistemas(db)

    response = client.get(
        "/malla",
        params={"programa": "Ingeniería de Sistemas y Computación"},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["plan"] == "201910"
    assert data["creditos_totales"] == 162
    assert len(data["cursos"]) == 55
    assert sum(curso["creditos"] for curso in data["cursos"]) == 162

    fisica = next(curso for curso in data["cursos"] if curso["codigo"] == "CBAS-F01A")
    assert fisica["prerequisitos"] == ["CBAS-M01A", "CBAS-M02A"]


def test_carga_de_malla_es_idempotente():
    with TestingSessionLocal() as db:
        poblar_malla_sistemas(db)
        poblar_malla_sistemas(db)

    response = client.get(
        "/malla",
        params={"programa": "Ingeniería de Sistemas y Computación"},
    )

    assert response.status_code == 200
    assert len(response.json()["cursos"]) == 55


def test_malla_informa_si_el_programa_no_tiene_catalogo():
    response = client.get("/malla", params={"programa": "Programa desconocido"})

    assert response.status_code == 404
