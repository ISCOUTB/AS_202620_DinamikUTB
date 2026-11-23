import re

import pytest
from fastapi.testclient import TestClient

from app.ayuda.models import CoordinadorPrograma
from app.estudiantes.models import Estudiante
from app.main import app
from tests.conftest import TestingSessionLocal
from tests.helpers import autenticar

client = TestClient(app)

SISTEMAS = "Ingeniería de Sistemas y Computación"
INDUSTRIAL = "Ingeniería Industrial"
CUERPO = {
    "tipo_discrepancia": "materia_sin_marca",
    "elemento_afectado": "CBAS-M01A Cálculo Diferencial",
    "descripcion": "Aprobé la materia en 2025-1 y no aparece con la marca.",
    "referencia_soporte": "Sábana Banner 2025-1",
}
COORD_SIS = "coord.sistemas@test.dev"
COORD_IND = "coord.industrial@test.dev"


@pytest.fixture
def escenario():
    _cache.clear()
    with TestingSessionLocal() as db:
        db.add_all(
            [
                Estudiante(codigo_estudiantil="T000111111", nombre="Ana", programa=SISTEMAS, semestre=7),
                Estudiante(codigo_estudiantil="T000222222", nombre="Luis", programa=INDUSTRIAL, semestre=5),
                CoordinadorPrograma(
                    programa=SISTEMAS, nombre="Coord Sistemas", cargo="Coordinación",
                    correo=COORD_SIS, oficina="Of 1", campus="Ternera", horario="L-V",
                ),
                CoordinadorPrograma(
                    programa=INDUSTRIAL, nombre="Coord Industrial", cargo="Coordinación",
                    correo=COORD_IND, oficina="Of 2", campus="Casa Lemaitre", horario="L-V",
                ),
            ]
        )
        db.commit()


_cache: dict = {}


def _h(rol, codigo=None, email=None):
    """autenticar crea un usuario con correo único: una sola vez por prueba."""
    clave = (rol, codigo, email)
    if clave not in _cache:
        _cache[clave] = autenticar(rol, codigo, email)
    return _cache[clave]


def _alumno(codigo="T000111111"):
    return _h("estudiante", codigo)


def _coord(correo=COORD_SIS):
    return _h("coordinador", email=correo)


def _crear(headers, **cambios):
    return client.post("/ayuda/solicitudes", json={**CUERPO, **cambios}, headers=headers)


def test_estudiante_radica_y_obtiene_numero(escenario):
    r = _crear(_alumno())

    assert r.status_code == 201
    cuerpo = r.json()
    assert re.fullmatch(r"UTB-RAD-\d{4}-\d{4,}", cuerpo["radicado"])
    assert cuerpo["estado"] == "pendiente"
    assert cuerpo["programa"] == SISTEMAS
    assert cuerpo["estudiante_id"] == "T000111111"


def test_radicados_distintos(escenario):
    a = _crear(_alumno()).json()["radicado"]
    b = _crear(_alumno()).json()["radicado"]

    assert a != b


def test_solo_el_estudiante_crea(escenario):
    assert client.post("/ayuda/solicitudes", json=CUERPO).status_code == 401
    assert _crear(_coord()).status_code == 403
    assert _crear(_h("administrador")).status_code == 403


def test_estudiante_sin_perfil_no_puede_radicar(escenario):
    assert _crear(_h("estudiante", "T000555555")).status_code == 400


@pytest.mark.parametrize(
    "cambios",
    [
        {"tipo_discrepancia": "inventado"},
        {"elemento_afectado": "x"},
        {"descripcion": "corta"},
        {"descripcion": "x" * 1501},
        {"extra": "no permitido"},
    ],
)
def test_validacion_de_la_solicitud(escenario, cambios):
    assert _crear(_alumno(), **cambios).status_code == 422


def test_el_estudiante_solo_ve_las_suyas(escenario):
    _crear(_alumno())
    _crear(_alumno("T000222222"))

    mias = client.get("/ayuda/solicitudes", headers=_alumno()).json()

    assert len(mias) == 1
    assert mias[0]["estudiante_id"] == "T000111111"
    assert client.get("/ayuda/solicitudes").status_code == 401


def test_aislamiento_por_programa_con_15_solicitudes(escenario):
    for _ in range(8):
        assert _crear(_alumno()).status_code == 201
    for _ in range(7):
        assert _crear(_alumno("T000222222")).status_code == 201

    sis = client.get("/ayuda/solicitudes", headers=_coord(COORD_SIS)).json()
    ind = client.get("/ayuda/solicitudes", headers=_coord(COORD_IND)).json()
    admin = client.get("/ayuda/solicitudes?limite=100", headers=_h("administrador")).json()

    assert len(sis) == 8 and {s["programa"] for s in sis} == {SISTEMAS}
    assert len(ind) == 7 and {s["programa"] for s in ind} == {INDUSTRIAL}
    assert len(admin) == 15


def test_coordinador_ajeno_no_puede_ver_ni_resolver(escenario):
    sid = _crear(_alumno()).json()["id"]
    otro = _coord(COORD_IND)

    r = client.put(
        f"/ayuda/solicitudes/{sid}/estado", json={"estado": "en_revision"}, headers=otro
    )

    assert r.status_code == 404
    assert client.get("/ayuda/solicitudes", headers=otro).json() == []


def test_coordinador_sin_directorio_no_ve_nada(escenario):
    _crear(_alumno())

    assert client.get("/ayuda/solicitudes", headers=_coord("nadie@test.dev")).json() == []


def test_el_coordinador_atiende_y_el_estudiante_ve_la_respuesta(escenario):
    sid = _crear(_alumno()).json()["id"]
    coord = _coord()

    revision = client.put(f"/ayuda/solicitudes/{sid}/estado", json={"estado": "en_revision"}, headers=coord)
    resuelta = client.put(
        f"/ayuda/solicitudes/{sid}/estado",
        json={"estado": "resuelta", "respuesta_coordinador": "Ya está corregido en Banner."},
        headers=coord,
    )
    repetida = client.put(
        f"/ayuda/solicitudes/{sid}/estado",
        json={"estado": "resuelta", "respuesta_coordinador": "Ya está corregido en Banner."},
        headers=coord,
    )

    assert revision.status_code == 200 and revision.json()["estado"] == "en_revision"
    assert resuelta.json()["estado"] == "resuelta"
    assert repetida.json()["actualizado_en"] == resuelta.json()["actualizado_en"]
    vista = client.get("/ayuda/solicitudes?estado=resuelta", headers=_alumno()).json()
    assert vista[0]["respuesta_coordinador"] == "Ya está corregido en Banner."


def test_resolver_exige_respuesta(escenario):
    sid = _crear(_alumno()).json()["id"]

    r = client.put(f"/ayuda/solicitudes/{sid}/estado", json={"estado": "resuelta"}, headers=_coord())

    assert r.status_code == 422


def test_el_estudiante_no_cambia_estados(escenario):
    sid = _crear(_alumno()).json()["id"]

    r = client.put(f"/ayuda/solicitudes/{sid}/estado", json={"estado": "resuelta", "respuesta_coordinador": "yo"}, headers=_alumno())

    assert r.status_code == 403


def test_directorio_del_coordinador(escenario):
    est = client.get("/ayuda/coordinador", headers=_alumno())
    coord = client.get("/ayuda/coordinador", headers=_coord(COORD_IND))
    admin_sin = client.get("/ayuda/coordinador", headers=_h("administrador"))
    admin_con = client.get(f"/ayuda/coordinador?programa={INDUSTRIAL}", headers=_h("administrador"))

    assert est.status_code == 200 and est.json()["campus"] == "Ternera"
    assert coord.json()["programa"] == INDUSTRIAL
    assert admin_sin.status_code == 422
    assert admin_con.json()["campus"] == "Casa Lemaitre"
    assert client.get("/ayuda/coordinador", headers=_coord("nadie@test.dev")).status_code == 404
    assert client.get("/ayuda/coordinador", headers=_h("estudiante", "T000555555")).status_code == 404
