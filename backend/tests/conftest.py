import os

# Define el entorno de pruebas antes de importar la aplicación.
os.environ["APP_ENV"] = "test"
os.environ["SECRET_KEY"] = "clave-solo-para-pruebas-0123456789abcdef"
os.environ["DATABASE_URL"] = "sqlite:///./test_dinamikutb.db"
os.environ.pop("METRICS_TOKEN", None)
os.environ.pop("CORS_ORIGINS", None)

import pytest  # noqa: E402
from sqlalchemy import create_engine  # noqa: E402
from sqlalchemy.orm import sessionmaker  # noqa: E402

from app.core.database import Base, get_db  # noqa: E402
from app.core.rate_limit import reiniciar_limites  # noqa: E402
from app.main import app  # noqa: E402

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
    reiniciar_limites()
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)
