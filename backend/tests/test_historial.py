import pytest
from fastapi.testclient import TestClient
from sqlalchemy.exc import IntegrityError

from app.main import app
from app.requisitos import service
from app.requisitos.models import Requisito, RequisitoHistorial
from app.usuarios.models import Usuario
from tests.conftest import TestingSessionLocal
from tests.helpers import autenticar

client = TestClient(app)


def _crear_requisito(estado: str = "pendiente") -> int:
    with TestingSessionLocal() as db:
        requisito = Requisito(estudiante_id="T000123456", nombre="Inglés B2", estado=estado)
        db.add(requisito)
        db.commit()
        db.refresh(requisito)
        return requisito.id


def _historial(requisito_id: int):
    with TestingSessionLocal() as db:
        return service.obtener_historial(db, requisito_id)


def _put(requisito_id: int, estado: str, headers: dict):
    return client.put(
        f"/requisitos/{requisito_id}/estado", json={"estado": estado}, headers=headers
    )


def test_un_cambio_de_estado_registra_quien_cuando_y_valores():
    headers = autenticar("coordinador")
    requisito_id = _crear_requisito("pendiente")
    with TestingSessionLocal() as db:
        actor_id = db.query(Usuario).one().id

    assert _put(requisito_id, "cumplido", headers).status_code == 200

    filas = _historial(requisito_id)
    assert len(filas) == 1
    fila = filas[0]
    assert fila.campo == "estado"
    assert fila.valor_anterior == "pendiente"
    assert fila.valor_nuevo == "cumplido"
    assert fila.actor_id == actor_id
    assert fila.estudiante_id == "T000123456"
    assert fila.creado_en is not None


def test_put_repetido_no_duplica_el_historial():
    headers = autenticar("coordinador")
    requisito_id = _crear_requisito("pendiente")

    for _ in range(3):
        assert _put(requisito_id, "cumplido", headers).status_code == 200

    assert len(_historial(requisito_id)) == 1


def test_fijar_el_estado_que_ya_tiene_no_registra_nada():
    headers = autenticar("coordinador")
    requisito_id = _crear_requisito("pendiente")

    assert _put(requisito_id, "pendiente", headers).status_code == 200

    assert _historial(requisito_id) == []


def test_cambios_sucesivos_se_conservan_en_orden():
    headers = autenticar("coordinador")
    requisito_id = _crear_requisito("pendiente")

    _put(requisito_id, "en_proceso", headers)
    _put(requisito_id, "cumplido", headers)

    pares = [(f.valor_anterior, f.valor_nuevo) for f in _historial(requisito_id)]
    assert pares == [("pendiente", "en_proceso"), ("en_proceso", "cumplido")]


def test_si_falla_el_historial_el_cambio_no_queda_aplicado(monkeypatch):
    """Atomicidad: el cambio y su historial se confirman juntos o no se confirma ninguno."""
    requisito_id = _crear_requisito("pendiente")

    def historial_invalido(**datos):
        datos["valor_nuevo"] = None  # viola NOT NULL: falla al confirmar la transacción
        return RequisitoHistorial(**datos)

    monkeypatch.setattr(service, "RequisitoHistorial", historial_invalido)

    with TestingSessionLocal() as db:
        with pytest.raises(IntegrityError):
            service.actualizar_estado_requisito(db, requisito_id, "cumplido", actor_id=1)

    with TestingSessionLocal() as db:
        assert db.get(Requisito, requisito_id).estado == "pendiente"
    assert _historial(requisito_id) == []


def test_historial_de_un_requisito_inexistente_es_none():
    with TestingSessionLocal() as db:
        assert service.obtener_historial(db, 99999) is None
