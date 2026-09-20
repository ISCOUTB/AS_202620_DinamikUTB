import json
from pathlib import Path

from app.main import app

RUTA_CONTRATO = Path(__file__).resolve().parent.parent.parent / "docs" / "api" / "openapi.json"


def test_el_contrato_versionado_coincide_con_la_api_real():
    """
    Si este test falla, significa que el código cambió (una ruta, un esquema,
    un campo) pero nadie volvió a exportar el contrato con
    `python -m scripts.export_openapi`. El contrato versionado en
    docs/api/openapi.json dejó de ser fiel a lo que la API expone.
    """
    contrato_guardado = json.loads(RUTA_CONTRATO.read_text(encoding="utf-8"))
    contrato_actual = app.openapi()

    assert contrato_guardado == contrato_actual, (
        "El contrato en docs/api/openapi.json no coincide con la API actual. "
        "Corré 'python -m scripts.export_openapi' para regenerarlo."
    )


def test_el_contrato_declara_las_rutas_principales():
    contrato = json.loads(RUTA_CONTRATO.read_text(encoding="utf-8"))

    assert "/requisitos/{estudiante_id}" in contrato["paths"]
    assert "/requisitos/{requisito_id}/estado" in contrato["paths"]
    assert "/estudiantes/{codigo_estudiantil}" in contrato["paths"]


def test_el_contrato_declara_su_version():
    contrato = json.loads(RUTA_CONTRATO.read_text(encoding="utf-8"))

    assert contrato["info"]["version"] == "0.1.0"
