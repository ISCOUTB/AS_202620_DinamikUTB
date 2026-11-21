from datetime import date

import pytest
from fastapi.testclient import TestClient

from app.curriculo import progreso
from app.curriculo.models import CursoEstudianteHistorial
from app.curriculo.service import poblar_malla_sistemas
from app.estudiantes.models import Estudiante
from app.main import app
from app.programas.models import Programa
from app.requisitos.models import Requisito, RequisitoHistorial, RequisitoPrograma
from tests.conftest import TestingSessionLocal
from tests.helpers import autenticar

client = TestClient(app)
CODIGO = "T000123456"
PROGRAMA = "Ingeniería de Sistemas y Computación"


@pytest.fixture
def estudiante():
    with TestingSessionLocal() as db:
        poblar_malla_sistemas(db)
        db.add(Estudiante(codigo_estudiantil=CODIGO, nombre="Ana", programa=PROGRAMA, semestre=2))
        db.commit()


def _put(headers, curso, **cuerpo):
    return client.put(f"/malla/progreso/{CODIGO}/{curso}", json=cuerpo, headers=headers)


def _aprobar(headers, curso, nota=4.0, periodo="2025-1"):
    return _put(headers, curso, estado="aprobado", fecha_aprobacion="2025-06-06", periodo=periodo, nota=nota)


def _curso(cuerpo, codigo):
    return next(c for c in cuerpo["cursos"] if c["codigo"] == codigo)


def test_periodos():
    assert progreso.sumar_periodos("2026-2", 1) == "2027-1"
    assert progreso.sumar_periodos("2026-1", 3) == "2027-2"
    assert progreso.periodo_de(date(2026, 6, 30)) == "2026-1"
    assert progreso.periodo_de(date(2026, 7, 1)) == "2026-2"


def test_progreso_inicial_sin_avance(estudiante):
    headers = autenticar("estudiante", CODIGO)

    r = client.get(f"/malla/progreso/{CODIGO}", headers=headers)

    assert r.status_code == 200
    cuerpo = r.json()
    assert cuerpo["resumen"]["creditos_totales"] == 162
    assert cuerpo["resumen"]["creditos_aprobados"] == 0
    assert cuerpo["resumen"]["promedio_acumulado"] is None
    assert len(cuerpo["niveles"]) == 10
    assert _curso(cuerpo, "CBAS-M01A")["desbloqueada"] is True
    fisica = _curso(cuerpo, "CBAS-F01A")
    assert fisica["desbloqueada"] is False
    assert sorted(fisica["prerequisitos_faltantes"]) == ["CBAS-M01A", "CBAS-M02A"]
    assert "CBAS-F01A" in _curso(cuerpo, "CBAS-M01A")["desbloquea"]


def test_aprobar_desbloquea_y_calcula_promedio(estudiante):
    gestor = autenticar("coordinador")
    assert _aprobar(gestor, "CBAS-M01A", nota=4.0).status_code == 200
    assert _aprobar(gestor, "CBAS-M02A", nota=3.0).status_code == 200

    cuerpo = client.get(f"/malla/progreso/{CODIGO}", headers=gestor).json()

    assert _curso(cuerpo, "CBAS-F01A")["desbloqueada"] is True
    assert cuerpo["resumen"]["creditos_aprobados"] == 6
    assert cuerpo["resumen"]["promedio_acumulado"] == 3.67  # (4*4 + 3*2) / 6
    assert cuerpo["niveles"][0]["creditos_aprobados"] == 6
    assert _curso(cuerpo, "CBAS-M01A")["fecha_aprobacion"] == "2025-06-06"


def test_put_es_idempotente_y_audita_una_sola_vez(estudiante):
    gestor = autenticar("coordinador")

    primera = _aprobar(gestor, "CBAS-M01A")
    segunda = _aprobar(gestor, "CBAS-M01A")

    assert primera.status_code == segunda.status_code == 200
    assert primera.json() == segunda.json()
    with TestingSessionLocal() as db:
        campos = {h.campo for h in progreso.obtener_historial(db, CODIGO)}
        assert db.query(CursoEstudianteHistorial).count() == 4
    assert campos == {"estado", "fecha_aprobacion", "periodo", "nota"}


def test_volver_a_pendiente_limpia_los_datos(estudiante):
    gestor = autenticar("coordinador")
    _aprobar(gestor, "CBAS-M01A")

    r = _put(gestor, "CBAS-M01A", estado="pendiente", nota=4.5, periodo="2025-1")

    assert r.status_code == 200
    assert r.json()["estado"] == "pendiente"
    assert r.json()["nota"] is None and r.json()["periodo"] is None


def test_en_curso_exige_prerrequisitos_y_periodo(estudiante):
    gestor = autenticar("coordinador")

    sin_prereq = _put(gestor, "CBAS-F01A", estado="en_curso", periodo="2026-2")
    sin_periodo = _put(gestor, "CBAS-M01A", estado="en_curso")
    bien = _put(gestor, "CBAS-M01A", estado="en_curso", periodo="2026-2")

    assert sin_prereq.status_code == 409
    assert "CBAS-M01A" in sin_prereq.json()["detail"]
    assert sin_periodo.status_code == 422
    assert bien.status_code == 200
    cuerpo = client.get(f"/malla/progreso/{CODIGO}", headers=gestor).json()
    assert cuerpo["resumen"]["creditos_en_curso"] == 4
    assert cuerpo["periodo_actual"] == "2026-2"


@pytest.mark.parametrize(
    "cuerpo",
    [
        {"estado": "aprobado", "periodo": "2025-1"},
        {"estado": "aprobado", "fecha_aprobacion": "2025-06-06"},
        {"estado": "aprobado", "fecha_aprobacion": "2025-06-06", "periodo": "2025-1", "nota": 2.5},
        {"estado": "aprobado", "fecha_aprobacion": "2999-01-01", "periodo": "2025-1"},
        {"estado": "aprobado", "fecha_aprobacion": "2025-06-06", "periodo": "2025-3"},
        {"estado": "aprobado", "fecha_aprobacion": "2025-06-06", "periodo": "2025-1", "nota": 5.5},
        {"estado": "terminado"},
        {"estado": "pendiente", "extra": 1},
    ],
)
def test_datos_inconsistentes_se_rechazan(estudiante, cuerpo):
    gestor = autenticar("coordinador")

    assert _put(gestor, "CBAS-M01A", **cuerpo).status_code == 422


def test_permisos(estudiante):
    alumno = autenticar("estudiante", CODIGO)
    ajeno = autenticar("estudiante", "T000999999")

    assert client.get(f"/malla/progreso/{CODIGO}").status_code == 401
    assert client.get(f"/malla/progreso/{CODIGO}", headers=ajeno).status_code == 403
    assert _aprobar(alumno, "CBAS-M01A").status_code == 403
    assert _aprobar(ajeno, "CBAS-M01A").status_code == 403
    assert client.put(f"/malla/progreso/{CODIGO}/CBAS-M01A", json={"estado": "pendiente"}).status_code == 401


def test_no_encontrados(estudiante):
    gestor = autenticar("coordinador")

    assert client.get("/malla/progreso/T999999999", headers=gestor).status_code == 404
    assert _aprobar(gestor, "XXXX-0000").status_code == 404
    assert client.put("/malla/progreso/T999999999/CBAS-M01A", json={"estado": "pendiente"}, headers=gestor).status_code == 404


def test_estudiante_sin_plan_da_404(estudiante):
    gestor = autenticar("coordinador")
    with TestingSessionLocal() as db:
        db.add(Estudiante(codigo_estudiantil="T000777777", nombre="Sin plan", programa="Programa fantasma", semestre=1))
        db.commit()

    assert client.get("/malla/progreso/T000777777", headers=gestor).status_code == 404


def test_proyeccion_de_grado_y_completitud(estudiante):
    with TestingSessionLocal() as db:
        base = progreso.calcular_progreso(db, CODIGO, hoy=date(2026, 11, 20))["resumen"]
    # 162 créditos, 10 niveles: 162 / 16.2 = 10 semestres si no hay avance.
    assert base["semestres_restantes"] == 10
    assert base["periodo_grado_estimado"] == "2031-1"  # arranca en 2026-2 y cuenta 9 más


def _catalogo(pct):
    with TestingSessionLocal() as db:
        programa = db.query(Programa).filter(Programa.nombre == PROGRAMA).one()
        rp = RequisitoPrograma(
            programa_id=programa.id,
            nombre="Examen Saber Pro (ICFES)",
            porcentaje_creditos_requerido=pct,
            codigo_interno="REQ-SABERPRO",
            categoria="Evaluacion",
            guia_resumen="Resumen",
            pasos_guia=[{"titulo": "Paso 1", "detalle": "d", "oficina": "o"}],
        )
        db.add(rp)
        db.flush()
        db.add(Requisito(estudiante_id=CODIGO, nombre=rp.nombre, estado="pendiente", catalogo_id=rp.id))
        db.add(Requisito(estudiante_id=CODIGO, nombre="Suelto", estado="pendiente"))
        db.commit()


def test_elegibilidad_por_umbral_de_creditos(estudiante):
    _catalogo(75)
    gestor = autenticar("coordinador")

    resumen = client.get(f"/requisitos/{CODIGO}/resumen", headers=gestor).json()

    assert resumen["total"] == 2
    [e] = resumen["elegibilidad"]
    assert e["porcentaje_requerido"] == 75
    assert e["creditos_requeridos"] == 122  # techo de 162 * 0.75 = 121.5
    assert e["creditos_faltantes"] == 122
    assert e["habilitado"] is False


def test_elegibilidad_cambia_al_aprobar_cursos(estudiante):
    _catalogo(75)
    gestor = autenticar("coordinador")
    _aprobar(gestor, "CBAS-M01A")

    [e] = client.get(f"/requisitos/{CODIGO}/resumen", headers=gestor).json()["elegibilidad"]

    assert e["creditos_aprobados"] == 4
    assert e["creditos_faltantes"] == 118


def test_ruta_trae_guia_y_requisitos_sin_catalogo(estudiante):
    _catalogo(75)
    alumno = autenticar("estudiante", CODIGO)

    ruta = client.get(f"/requisitos/{CODIGO}/ruta", headers=alumno).json()

    saber = next(r for r in ruta if r["codigo_interno"] == "REQ-SABERPRO")
    assert saber["pasos_guia"][0]["titulo"] == "Paso 1"
    assert saber["creditos_faltantes"] == 122
    suelto = next(r for r in ruta if r["nombre"] == "Suelto")
    assert suelto["pasos_guia"] == [] and suelto["habilitado"] is None
    assert client.get(f"/requisitos/{CODIGO}/ruta").status_code == 401
    ajeno = autenticar("estudiante", "T000999999")
    assert client.get(f"/requisitos/{CODIGO}/ruta", headers=ajeno).status_code == 403


def test_detalle_de_requisito_audita_por_campo_y_es_idempotente(estudiante):
    _catalogo(75)
    gestor = autenticar("coordinador")
    with TestingSessionLocal() as db:
        rid = db.query(Requisito).filter(Requisito.nombre == "Suelto").one().id
    cuerpo = {"fecha_cumplimiento": "2024-06-06", "periodo": "2024-1", "evidencia": "Constancia"}

    primera = client.put(f"/requisitos/{rid}/detalle", json=cuerpo, headers=gestor)
    segunda = client.put(f"/requisitos/{rid}/detalle", json=cuerpo, headers=gestor)

    assert primera.status_code == segunda.status_code == 200
    assert primera.json()["fecha_cumplimiento"] == "2024-06-06"
    with TestingSessionLocal() as db:
        assert db.query(RequisitoHistorial).filter(RequisitoHistorial.requisito_id == rid).count() == 3


def test_detalle_rechaza_fecha_futura_inexistente_y_estudiante(estudiante):
    _catalogo(75)
    gestor = autenticar("coordinador")
    alumno = autenticar("estudiante", CODIGO)

    assert client.put("/requisitos/1/detalle", json={"fecha_cumplimiento": "2999-01-01"}, headers=gestor).status_code == 422
    assert client.put("/requisitos/99999/detalle", json={}, headers=gestor).status_code == 404
    assert client.put("/requisitos/1/detalle", json={}, headers=alumno).status_code == 403
