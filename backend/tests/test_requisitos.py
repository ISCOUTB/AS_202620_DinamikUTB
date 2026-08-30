import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.database import Base, get_db
from app.main import app
from app.requisitos.models import Requisito

SQLALCHEMY_TEST_DATABASE_URL = "sqlite:///./test_dinamikutb.db"

engine = create_engine(
    SQLALCHEMY_TEST_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(autouse=True)
def preparar_base_de_datos():
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


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

    client = TestClient(app)
    response = client.get("/requisitos/T000123456")

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["nombre"] == "Inglés B2"
    assert data[0]["estado"] == "pendiente"


def test_estudiante_sin_requisitos_devuelve_lista_vacia():
    client = TestClient(app)
    response = client.get("/requisitos/T999999999")

    assert response.status_code == 200
    assert response.json() == []
