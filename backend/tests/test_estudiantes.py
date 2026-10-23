from fastapi.testclient import TestClient

from app.estudiantes.models import Estudiante
from app.main import app
from tests.conftest import TestingSessionLocal
from tests.helpers import autenticar

client = TestClient(app)


def test_consultar_estudiante_existente():
    headers = autenticar("estudiante", "T000123456")
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

    response = client.get("/estudiantes/T000123456", headers=headers)

    assert response.status_code == 200
    data = response.json()
    assert data["nombre"] == "Ana Pérez"
    assert data["programa"] == "Ingeniería de Sistemas"


def test_consultar_estudiante_inexistente_devuelve_404():
    headers = autenticar("coordinador")

    response = client.get("/estudiantes/T999999999", headers=headers)

    assert response.status_code == 404
