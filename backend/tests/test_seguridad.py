import pytest
from fastapi.testclient import TestClient

from app.estudiantes.models import Estudiante
from app.main import app
from app.requisitos.models import Requisito
from tests.conftest import TestingSessionLocal
from tests.helpers import autenticar

client = TestClient(app)


def _requisito(codigo="T000123456", estado="pendiente"):
    with TestingSessionLocal() as db:
        r = Requisito(estudiante_id=codigo, nombre="Inglés B2", estado=estado)
        db.add(r)
        db.commit()
        db.refresh(r)
        return r.id


@pytest.mark.parametrize(
    "metodo,ruta",
    [
        ("get", "/requisitos/T000123456"),
        ("get", "/requisitos/T000123456/resumen"),
        ("get", "/estudiantes/T000123456"),
        ("put", "/requisitos/1/estado"),
    ],
)
def test_endpoints_protegidos_exigen_autenticacion(metodo, ruta):
    kwargs = {"json": {"estado": "cumplido"}} if metodo == "put" else {}

    response = getattr(client, metodo)(ruta, **kwargs)

    assert response.status_code == 401


def test_estudiante_no_puede_ver_los_requisitos_de_otro():
    headers = autenticar("estudiante", "T000123456")
    _requisito("T000999999")

    assert client.get("/requisitos/T000999999", headers=headers).status_code == 403
    assert client.get("/requisitos/T000999999/resumen", headers=headers).status_code == 403
    assert client.get("/estudiantes/T000999999", headers=headers).status_code == 403


def test_coordinador_puede_ver_los_requisitos_de_cualquier_estudiante():
    headers = autenticar("coordinador")
    _requisito("T000999999")

    response = client.get("/requisitos/T000999999", headers=headers)

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_estudiante_no_puede_modificar_estados():
    headers = autenticar("estudiante", "T000123456")
    requisito_id = _requisito("T000123456")

    response = client.put(
        f"/requisitos/{requisito_id}/estado", json={"estado": "cumplido"}, headers=headers
    )

    assert response.status_code == 403
    with TestingSessionLocal() as db:
        assert db.get(Requisito, requisito_id).estado == "pendiente"


def test_administrador_puede_modificar_estados():
    headers = autenticar("administrador")
    requisito_id = _requisito()

    response = client.put(
        f"/requisitos/{requisito_id}/estado", json={"estado": "en_proceso"}, headers=headers
    )

    assert response.status_code == 200


@pytest.mark.parametrize(
    "ruta",
    [
        "/requisitos/T1%27%20OR%20%271%27=%271",
        "/requisitos/T1;DROP%20TABLE%20requisitos",
        "/requisitos/%27%20UNION%20SELECT%20*%20FROM%20usuarios--",
        "/estudiantes/T1%27%20OR%20%271%27=%271",
        "/estudiantes/..%2F..%2Fetc%2Fpasswd",
    ],
)
def test_codigos_con_caracteres_de_inyeccion_son_rechazados(ruta):
    headers = autenticar("coordinador")

    response = client.get(ruta, headers=headers)

    assert response.status_code in (404, 422)
    assert response.status_code != 200


def test_la_tabla_sigue_intacta_tras_un_intento_de_inyeccion():
    headers = autenticar("coordinador")
    _requisito()
    client.get("/requisitos/T1;DROP%20TABLE%20requisitos", headers=headers)

    assert client.get("/requisitos/T000123456", headers=headers).status_code == 200


def test_respuestas_incluyen_cabeceras_de_seguridad():
    response = client.get("/")

    assert response.headers["X-Content-Type-Options"] == "nosniff"
    assert response.headers["X-Frame-Options"] == "DENY"
    assert response.headers["Cache-Control"] == "no-store"
    assert response.headers["Referrer-Policy"] == "no-referrer"


def test_el_error_de_validacion_no_devuelve_el_valor_enviado():
    headers = autenticar("coordinador")
    requisito_id = _requisito()

    response = client.put(
        f"/requisitos/{requisito_id}/estado", json={"estado": "secreto-enviado"}, headers=headers
    )

    assert response.status_code == 422
    assert "secreto-enviado" not in response.text


def test_cors_rechaza_origenes_no_permitidos():
    response = client.options(
        "/requisitos/T000123456",
        headers={
            "Origin": "https://sitio-malicioso.example",
            "Access-Control-Request-Method": "GET",
        },
    )

    assert "access-control-allow-origin" not in response.headers


def test_estudiantes_no_expone_campos_internos():
    headers = autenticar("coordinador")
    with TestingSessionLocal() as db:
        db.add(Estudiante(codigo_estudiantil="T000123456", nombre="Ana", programa="Sistemas"))
        db.commit()

    cuerpo = client.get("/estudiantes/T000123456", headers=headers).json()

    assert set(cuerpo) == {"id", "codigo_estudiantil", "nombre", "programa"}
