from fastapi.testclient import TestClient

from app.estudiantes.models import Estudiante, EstudianteHistorial
from app.main import app
from app.programas.models import Programa
from app.requisitos.models import Requisito
from app.usuarios.models import Usuario
from tests.conftest import TestingSessionLocal
from tests.helpers import PASSWORD, autenticar

client = TestClient(app)
PROGRAMA = "Ingeniería de Sistemas"


def _programa(nombre=PROGRAMA, codigo="IS-01") -> int:
    with TestingSessionLocal() as db:
        p = Programa(
            codigo=codigo, nombre=nombre, facultad="Ingeniería", duracion_semestres=10, activo=True
        )
        db.add(p)
        db.commit()
        db.refresh(p)
        return p.id


def _estudiante(codigo="T000123456", semestre=3):
    with TestingSessionLocal() as db:
        db.add(Estudiante(codigo_estudiantil=codigo, nombre="Ana", programa=PROGRAMA, semestre=semestre))
        db.commit()


def _historial(codigo="T000123456"):
    with TestingSessionLocal() as db:
        return [
            (h.campo, h.valor_anterior, h.valor_nuevo, h.actor_id)
            for h in db.query(EstudianteHistorial)
            .filter(EstudianteHistorial.estudiante_id == codigo)
            .order_by(EstudianteHistorial.id)
        ]


# ---------- catálogo de requisitos ----------


def test_editar_requisito_renombra_a_los_asignados_y_conserva_la_guia():
    pid = _programa()
    _estudiante()
    admin = autenticar("administrador")
    creado = client.post(
        "/requisitos/catalogo",
        headers=admin,
        json={"programa_id": pid, "nombre": "Práctica", "guia_resumen": "Guía original"},
    )
    assert creado.status_code == 201
    cid = creado.json()["id"]

    r = client.put(
        f"/requisitos/catalogo/{cid}",
        headers=admin,
        json={
            "programa_id": pid,
            "nombre": "Práctica profesional",
            "descripcion": "Completar la práctica",
            "semestre_recomendado": 9,
            "obligatorio": False,
            "activo": False,
        },
    )

    assert r.status_code == 200
    cuerpo = r.json()
    assert cuerpo["nombre"] == "Práctica profesional"
    assert cuerpo["semestre_recomendado"] == 9
    assert cuerpo["obligatorio"] is False and cuerpo["activo"] is False
    assert cuerpo["guia_resumen"] == "Guía original"  # no se borró
    with TestingSessionLocal() as db:
        asignado = db.query(Requisito).filter(Requisito.catalogo_id == cid).one()
        assert asignado.nombre == "Práctica profesional"


def test_editar_requisito_rechaza_mover_de_programa_y_ids_inexistentes():
    pid = _programa()
    otro = _programa("Ingeniería Industrial", "II-01")
    admin = autenticar("administrador")
    cid = client.post(
        "/requisitos/catalogo", headers=admin, json={"programa_id": pid, "nombre": "Inglés B2"}
    ).json()["id"]

    mover = client.put(
        f"/requisitos/catalogo/{cid}", headers=admin, json={"programa_id": otro, "nombre": "Inglés B2"}
    )
    inexistente = client.put(
        "/requisitos/catalogo/99999", headers=admin, json={"programa_id": pid, "nombre": "X"}
    )

    assert mover.status_code == 422
    assert inexistente.status_code == 404


def test_catalogo_exige_autenticacion_y_solo_admin_edita():
    pid = _programa()
    admin = autenticar("administrador")
    cid = client.post(
        "/requisitos/catalogo", headers=admin, json={"programa_id": pid, "nombre": "Saber Pro"}
    ).json()["id"]
    coordinador = autenticar("coordinador")
    cuerpo = {"programa_id": pid, "nombre": "Saber Pro 2"}

    assert client.get("/requisitos/catalogo").status_code == 401
    assert client.get("/requisitos/catalogo", headers=coordinador).status_code == 200
    assert client.put(f"/requisitos/catalogo/{cid}", json=cuerpo).status_code == 401
    assert client.put(f"/requisitos/catalogo/{cid}", json=cuerpo, headers=coordinador).status_code == 403


# ---------- historial de datos del estudiante (ADR-0014) ----------


def _cuerpo_admin(**cambios):
    base = {
        "nombre": "Ana María",
        "email": "ana@utb.edu.co",
        "codigo_estudiantil": "T000123456",
        "programa": PROGRAMA,
        "semestre": 4,
        "activo": True,
    }
    return {**base, **cambios}


def test_edicion_administrativa_registra_historial_y_es_idempotente():
    _programa()
    _estudiante(semestre=3)
    admin = autenticar("administrador")
    with TestingSessionLocal() as db:
        actor_id = db.query(Usuario).one().id

    primera = client.put("/estudiantes/T000123456/administrativo", json=_cuerpo_admin(), headers=admin)
    segunda = client.put("/estudiantes/T000123456/administrativo", json=_cuerpo_admin(), headers=admin)

    assert primera.status_code == segunda.status_code == 200
    assert primera.json()["semestre"] == 4
    assert _historial() == [
        ("nombre", "Ana", "Ana María", actor_id),
        ("semestre", "3", "4", actor_id),
    ]


def test_edicion_administrativa_valida_entradas():
    _programa()
    _estudiante()
    admin = autenticar("administrador")
    url = "/estudiantes/T000123456/administrativo"

    assert client.put(url, json=_cuerpo_admin(email="a@gmail.com"), headers=admin).status_code == 422
    assert client.put(url, json=_cuerpo_admin(programa="Inventado"), headers=admin).status_code == 422
    assert client.put(url, json=_cuerpo_admin(semestre=13), headers=admin).status_code == 422
    assert (
        client.put("/estudiantes/T999999999/administrativo", json=_cuerpo_admin(), headers=admin).status_code
        == 404
    )
    assert _historial() == []


def test_mi_perfil_registra_historial_con_el_actor():
    _programa()
    _estudiante(semestre=3)
    alumno = autenticar("estudiante", "T000123456")
    with TestingSessionLocal() as db:
        actor_id = db.query(Usuario).one().id

    r = client.put(
        "/auth/mi-perfil",
        headers=alumno,
        json={"nombre": "Ana", "programa": PROGRAMA, "semestre": 5},
    )

    assert r.status_code == 200
    assert _historial() == [("semestre", "3", "5", actor_id)]


def test_mi_perfil_rechaza_programa_inexistente_y_semestre_fuera_de_rango():
    _programa()
    _estudiante()
    alumno = autenticar("estudiante", "T000123456")

    mala_carrera = client.put(
        "/auth/mi-perfil", headers=alumno, json={"nombre": "Ana", "programa": "Inventado", "semestre": 3}
    )
    mal_semestre = client.put(
        "/auth/mi-perfil", headers=alumno, json={"nombre": "Ana", "programa": PROGRAMA, "semestre": 40}
    )

    assert mala_carrera.status_code == 422
    assert mal_semestre.status_code == 422
    assert _historial() == []


# ---------- cuentas ----------


def test_la_cuenta_creada_no_acepta_una_clave_conocida():
    _programa()
    admin = autenticar("administrador")
    creada = client.post(
        "/estudiantes",
        headers=admin,
        json={
            "nombre": "Luis",
            "email": "luis@utb.edu.co",
            "codigo_estudiantil": "T000555555",
            "programa": PROGRAMA,
            "semestre": 2,
        },
    )
    assert creada.status_code == 201
    cuentas = client.get("/auth/administradores", headers=admin).json()
    cuenta = next(c for c in cuentas if c["email"] == "luis@utb.edu.co")
    assert client.put(
        f"/auth/administradores/{cuenta['id']}?activo=true&rol=estudiante", headers=admin
    ).status_code == 200

    for clave in ("Temporal#12345", PASSWORD):
        r = client.post("/auth/login", json={"email": "luis@utb.edu.co", "password": clave})
        assert r.status_code == 401


def test_rol_invalido_y_autobloqueo_del_administrador():
    admin = autenticar("administrador")
    with TestingSessionLocal() as db:
        admin_id = db.query(Usuario).one().id

    rol_raro = client.put(f"/auth/administradores/{admin_id}?activo=true&rol=superadmin", headers=admin)
    desactivarse = client.put(f"/auth/administradores/{admin_id}?activo=false&rol=administrador", headers=admin)
    degradarse = client.put(f"/auth/administradores/{admin_id}?activo=true&rol=coordinador", headers=admin)

    assert rol_raro.status_code == 422
    assert desactivarse.status_code == 400
    assert degradarse.status_code == 400
