from datetime import datetime, timedelta, timezone

import jwt
from fastapi.testclient import TestClient

from app.core.config import get_settings
from app.main import app
from app.usuarios.models import Usuario
from app.usuarios.service import crear_usuario
from tests.conftest import TestingSessionLocal
from tests.helpers import PASSWORD

client = TestClient(app)
EMAIL = "ana@test.dev"


def _crear(email=EMAIL, rol="estudiante", codigo="T000123456"):
    with TestingSessionLocal() as db:
        return crear_usuario(db, email, PASSWORD, rol, codigo).id


def _login(email=EMAIL, password=PASSWORD):
    return client.post("/auth/login", json={"email": email, "password": password})


def _token_manual(usuario_id="1", clave=None, algoritmo="HS256", delta=timedelta(minutes=5)):
    clave = clave if clave is not None else get_settings().secret_key
    payload = {"sub": usuario_id, "exp": datetime.now(timezone.utc) + delta}
    return jwt.encode(payload, clave, algorithm=algoritmo)


def test_login_exitoso_devuelve_token():
    _crear()

    response = _login()

    assert response.status_code == 200
    cuerpo = response.json()
    assert cuerpo["token_type"] == "bearer"
    assert cuerpo["access_token"]
    assert cuerpo["expires_in"] > 0


def test_login_normaliza_el_correo():
    _crear()

    assert _login("  ANA@Test.DEV ").status_code == 200


def test_login_no_distingue_usuario_inexistente_de_password_erronea():
    _crear()

    mala = _login(password="otra-clave-incorrecta")
    inexistente = _login(email="nadie@test.dev")

    assert mala.status_code == inexistente.status_code == 401
    assert mala.json() == inexistente.json()


def test_login_bloquea_la_cuenta_tras_demasiados_intentos():
    _crear()
    for _ in range(get_settings().login_max_attempts):
        assert _login(password="incorrecta-123").status_code == 401

    # El bloqueo temporal impide el acceso incluso con la contraseña correcta.
    assert _login().status_code == 401


def test_login_limita_el_ritmo_por_ip():
    limite = get_settings().login_rate_limit
    for _ in range(limite):
        assert _login(email="nadie@test.dev").status_code == 401

    response = _login(email="nadie@test.dev")

    assert response.status_code == 429
    assert "Retry-After" in response.headers


def test_validacion_no_refleja_la_contrasena_enviada():
    response = client.post("/auth/login", json={"email": "a@b.co", "password": "corta"})

    assert response.status_code == 422
    assert "corta" not in response.text
    assert "input" not in response.text


def test_login_rechaza_campos_inesperados():
    _crear()

    response = client.post(
        "/auth/login",
        json={"email": EMAIL, "password": PASSWORD, "rol": "administrador"},
    )

    assert response.status_code == 422


def test_login_con_intento_de_inyeccion_sql_es_rechazado():
    response = _login(email="' OR '1'='1' --@x.co")

    assert response.status_code == 422


def test_me_devuelve_solo_datos_publicos_del_usuario():
    _crear()
    token = _login().json()["access_token"]

    response = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 200
    assert response.json() == {
        "id": 1,
        "email": EMAIL,
        "rol": "estudiante",
        "codigo_estudiantil": "T000123456",
    }


def test_me_sin_token_devuelve_401():
    response = client.get("/auth/me")

    assert response.status_code == 401
    assert response.headers["WWW-Authenticate"] == "Bearer"


def test_token_manipulado_es_rechazado():
    _crear()
    token = _login().json()["access_token"]
    cabecera, cuerpo, firma = token.split(".")
    manipulado = f"{cabecera}.{cuerpo}.{firma[:-2]}xx"

    response = client.get("/auth/me", headers={"Authorization": f"Bearer {manipulado}"})

    assert response.status_code == 401


def test_token_expirado_es_rechazado():
    _crear()
    token = _token_manual(delta=timedelta(minutes=-1))

    response = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 401


def test_token_firmado_con_otra_clave_es_rechazado():
    _crear()
    token = _token_manual(clave="otra-clave-distinta-de-al-menos-32-caracteres")

    response = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 401


def test_token_sin_firma_alg_none_es_rechazado():
    _crear()
    token = jwt.encode(
        {"sub": "1", "exp": datetime.now(timezone.utc) + timedelta(minutes=5)}, None, algorithm="none"
    )

    response = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 401


def test_usuario_desactivado_pierde_el_acceso_de_inmediato():
    usuario_id = _crear()
    token = _login().json()["access_token"]
    with TestingSessionLocal() as db:
        db.get(Usuario, usuario_id).activo = False
        db.commit()

    response = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 401
