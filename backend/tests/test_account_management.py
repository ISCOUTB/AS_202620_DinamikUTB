from uuid import uuid4

from fastapi.testclient import TestClient

from app.estudiantes.models import Estudiante
from app.programas.models import Programa
from app.requisitos.models import Requisito, RequisitoPrograma
from app.usuarios.models import Usuario
from tests.conftest import TestingSessionLocal
from tests.helpers import PASSWORD, autenticar

client = TestClient(__import__("app.main", fromlist=["app"]).app)


def _programa(nombre="Ingeniería de Sistemas"):
    with TestingSessionLocal() as db:
        programa = Programa(
            codigo="IS-01",
            nombre=nombre,
            facultad="Facultad de Ingeniería",
            duracion_semestres=10,
            activo=True,
        )
        db.add(programa)
        db.commit()
        db.refresh(programa)
        return programa.id


def _crear_estudiante(
    email="estudiante@utb.edu.co",
    codigo="T1234567",
    programa="Ingeniería de Sistemas",
    rol="administrador",
):
    return client.post(
        "/estudiantes",
        headers=autenticar(rol, email=f"{rol}-{uuid4().hex}@test.dev"),
        json={
            "nombre": "Estudiante de Prueba",
            "email": email,
            "codigo_estudiantil": codigo,
            "programa": programa,
            "semestre": 4,
        },
    )


def _activar_cuenta(email):
    headers = autenticar(
        "administrador",
        email=f"administrador-{uuid4().hex}@test.dev",
    )
    accounts = client.get("/auth/administradores", headers=headers)
    assert accounts.status_code == 200
    account = next(item for item in accounts.json() if item["email"] == email)
    assert account["activo"] is False
    response = client.put(
        f"/auth/administradores/{account['id']}?activo=true&rol=estudiante",
        headers=headers,
    )
    assert response.status_code == 200
    return headers


def _establecer_password(email, headers, password=PASSWORD):
    accounts = client.get("/auth/administradores", headers=headers)
    account = next(item for item in accounts.json() if item["email"] == email)
    reset = client.post(
        f"/auth/administradores/{account['id']}/recuperacion",
        headers=headers,
    )
    assert reset.status_code == 200
    changed = client.post(
        "/auth/password/restablecer",
        json={"token": reset.json()["reset_token"], "new_password": password},
    )
    assert changed.status_code == 200


def test_solo_gestion_puede_crear_cuentas_estudiantiles():
    _programa()

    datos = {
        "nombre": "Estudiante de Prueba",
        "email": "estudiante@utb.edu.co",
        "codigo_estudiantil": "T1234567",
        "programa": "Ingeniería de Sistemas",
        "semestre": 4,
    }
    denied = client.post(
        "/estudiantes",
        headers=autenticar("estudiante", email="alumno-prueba@utb.edu.co"),
        json=datos,
    )
    assert denied.status_code == 403

    response = _crear_estudiante()

    assert response.status_code == 201
    assert response.json()["activo"] is False
    assert client.post(
        "/auth/login",
        json={"email": "estudiante@utb.edu.co", "password": PASSWORD},
    ).status_code == 401
    headers = _activar_cuenta("estudiante@utb.edu.co")
    _establecer_password("estudiante@utb.edu.co", headers)
    token = client.post(
        "/auth/login",
        json={"email": "estudiante@utb.edu.co", "password": PASSWORD},
    ).json()["access_token"]
    profile = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert profile.json()["nombre"] == "Estudiante de Prueba"
    assert profile.json()["programa"] == "Ingeniería de Sistemas"
    assert profile.json()["semestre"] == 4


def test_el_endpoint_publico_de_registro_esta_desactivado():
    assert client.post("/auth/registro", json={}).status_code == 404


def test_alta_administrativa_valida_correo_y_programa():
    _programa()

    assert _crear_estudiante(email="alguien@example.com").status_code == 422
    assert _crear_estudiante(
        email="otro@utb.edu.co", codigo="T9876543", programa="Programa inventado"
    ).status_code == 422


def test_alta_administrativa_no_permite_reutilizar_email_o_codigo():
    _programa()
    assert _crear_estudiante().status_code == 201

    assert _crear_estudiante(codigo="T7654321").status_code == 409
    assert _crear_estudiante(email="otra@utb.edu.co").status_code == 409


def test_coordinador_puede_registrar_estudiante():
    _programa()

    response = _crear_estudiante(
        email="coordinado@utb.edu.co",
        codigo="T7654321",
        rol="coordinador",
    )

    assert response.status_code == 201
    assert response.json()["activo"] is False


def test_solo_administrador_puede_crear_cuentas_de_gestion():
    admin_headers = autenticar("administrador")
    created = client.post(
        "/auth/administradores?rol=coordinador",
        headers=admin_headers,
        json={"email": "nuevo.coordinador@utb.edu.co", "password": "AltaSegura#2026"},
    )
    assert created.status_code == 201
    assert created.json()["rol"] == "coordinador"
    assert created.json()["activo"] is True

    student_headers = autenticar("estudiante", email="alumno@utb.edu.co")
    denied = client.post(
        "/auth/administradores?rol=administrador",
        headers=student_headers,
        json={"email": "otro.admin@utb.edu.co", "password": "AltaSegura#2026"},
    )
    assert denied.status_code == 403


def test_renombrar_programa_actualiza_el_programa_de_estudiantes_asociados():
    program_id = _programa()
    with TestingSessionLocal() as db:
        db.add(
            Estudiante(
                codigo_estudiantil="T7654321",
                nombre="Estudiante de Programa",
                programa="Ingeniería de Sistemas",
                semestre=5,
            )
        )
        db.commit()

    response = client.put(
        f"/programas/{program_id}",
        headers=autenticar("administrador"),
        json={
            "codigo": "IS-01",
            "nombre": "Ingeniería de Software",
            "facultad": "Facultad de Ingeniería",
            "duracion_semestres": 10,
            "activo": True,
        },
    )
    assert response.status_code == 200
    with TestingSessionLocal() as db:
        student = db.query(Estudiante).filter(
            Estudiante.codigo_estudiantil == "T7654321"
        ).one()
        assert student.programa == "Ingeniería de Software"


def test_perfil_y_cambio_de_password_persisten_e_invalidan_sesiones():
    _programa()
    assert _crear_estudiante().status_code == 201
    admin_headers = _activar_cuenta("estudiante@utb.edu.co")
    _establecer_password("estudiante@utb.edu.co", admin_headers)
    token = client.post(
        "/auth/login",
        json={"email": "estudiante@utb.edu.co", "password": PASSWORD},
    ).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    updated = client.put(
        "/auth/mi-perfil",
        headers=headers,
        json={"nombre": "Nombre Actualizado", "programa": "Ingeniería de Sistemas", "semestre": 5},
    )
    assert updated.status_code == 200
    assert updated.json()["semestre"] == 5

    wrong = client.put(
        "/auth/password",
        headers=headers,
        json={"current_password": "incorrecta", "new_password": "OtraClaveSegura#456"},
    )
    assert wrong.status_code == 400
    changed = client.put(
        "/auth/password",
        headers=headers,
        json={"current_password": PASSWORD, "new_password": "OtraClaveSegura#456"},
    )
    assert changed.status_code == 200
    assert client.get("/auth/me", headers=headers).status_code == 401
    assert client.post(
        "/auth/login",
        json={"email": "estudiante@utb.edu.co", "password": "OtraClaveSegura#456"},
    ).status_code == 200


def test_recuperacion_email_falla_explicita_si_smtp_no_esta_configurado(monkeypatch):
    from app.core.config import get_settings

    for variable in ("SMTP_HOST", "SMTP_FROM", "SMTP_USER", "SMTP_PASSWORD", "PASSWORD_RESET_URL"):
        monkeypatch.delenv(variable, raising=False)
    get_settings.cache_clear()

    response = client.post(
        "/auth/password/recuperar",
        json={"email": "alguien@utb.edu.co"},
    )

    assert response.status_code == 503
    assert "no está configurada" in response.json()["detail"]
    get_settings.cache_clear()


def test_administrador_puede_emitir_enlace_asistido_de_un_solo_uso():
    _programa()
    assert _crear_estudiante().status_code == 201
    admin_headers = _activar_cuenta("estudiante@utb.edu.co")

    with TestingSessionLocal() as db:
        student = db.query(Usuario).filter(Usuario.email == "estudiante@utb.edu.co").one()
        student_user_id = student.id
    assert client.get(
        "/auth/administradores",
        headers=autenticar("estudiante", email="alumno@utb.edu.co"),
    ).status_code == 403
    admin = client.get("/auth/administradores", headers=admin_headers)
    assert admin.status_code == 200

    issued = client.post(
        f"/auth/administradores/{student_user_id}/recuperacion",
        headers=admin_headers,
    )
    assert issued.status_code == 200
    token = issued.json()["reset_token"]
    reset = client.post(
        "/auth/password/restablecer",
        json={"token": token, "new_password": "Restablecer#2026"},
    )
    assert reset.status_code == 200
    assert client.post(
        "/auth/password/restablecer",
        json={"token": token, "new_password": "Restablecer#2026"},
    ).status_code == 400
    assert client.post(
        "/auth/login",
        json={"email": "estudiante@utb.edu.co", "password": "Restablecer#2026"},
    ).status_code == 200


def test_exportar_estudiantes_csv_requiere_gestor_y_protege_celdas():
    import csv
    from io import StringIO

    _programa()
    assert _crear_estudiante().status_code == 201
    admin_headers = _activar_cuenta("estudiante@utb.edu.co")
    _establecer_password("estudiante@utb.edu.co", admin_headers)
    with TestingSessionLocal() as db:
        student = db.query(Estudiante).filter(
            Estudiante.codigo_estudiantil == "T1234567"
        ).one()
        student.nombre = "=HYPERLINK(\"https://example.org\")"
        db.commit()

    assert client.get("/reportes/estudiantes.csv").status_code == 401
    token = client.post(
        "/auth/login",
        json={"email": "estudiante@utb.edu.co", "password": PASSWORD},
    ).json()["access_token"]
    assert client.get(
        "/reportes/estudiantes.csv",
        headers={"Authorization": f"Bearer {token}"},
    ).status_code == 403

    response = client.get(
        "/reportes/estudiantes.csv",
        headers=admin_headers,
    )
    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/csv")
    assert response.headers["content-disposition"] == (
        'attachment; filename="dinamikutb-estudiantes.csv"'
    )
    rows = list(csv.reader(StringIO(response.content.decode("utf-8-sig"))))
    assert rows[0][0] == "codigo_estudiantil"
    assert rows[1][1].startswith("'=")


def test_administra_catalogos_y_asigna_requisitos_a_estudiantes():
    program_id = _programa()
    with TestingSessionLocal() as db:
        db.add(Estudiante(codigo_estudiantil="T000123456", nombre="Ana Pérez", programa="Ingeniería de Sistemas", semestre=7))
        db.commit()
    admin_headers = autenticar("administrador")
    created = client.post(
        "/requisitos/catalogo",
        headers=admin_headers,
        json={
            "programa_id": program_id,
            "nombre": "Práctica profesional",
            "descripcion": "Completar la práctica.",
            "semestre_recomendado": 9,
            "obligatorio": True,
        },
    )
    assert created.status_code == 201
    with TestingSessionLocal() as db:
        assigned = db.query(Requisito).filter(
            Requisito.estudiante_id == "T000123456",
            Requisito.catalogo_id == created.json()["id"],
        ).one()
        assert assigned.estado == "pendiente"
        assert db.query(RequisitoPrograma).count() == 1
