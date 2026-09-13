from fastapi.testclient import TestClient

from app.estudiantes.models import Estudiante
from app.main import app
from tests.conftest import TestingSessionLocal

client = TestClient(app)


def test_consultar_estudiante_existente():
    db = TestingSessionLocal()
    db.add(
        Estudiante(
            codigo_estudiantil="T000123456",
            nombre="Ana Pérez",
            programa="Ingeniería de Sistemas",
        )
    )
    db.commit()
    db.close()

    response = client.get("/estudiantes/T000123456")

    assert response.status_code == 200
    data = response.json()
    assert data["nombre"] == "Ana Pérez"
    assert data["programa"] == "Ingeniería de Sistemas"


def test_consultar_estudiante_inexistente_devuelve_404():
    response = client.get("/estudiantes/T999999999")

    assert response.status_code == 404
