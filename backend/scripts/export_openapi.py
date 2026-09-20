"""
Aqui se exporta el contrato OpenAPI generado por FastAPI a un archivo versionado.

Uso: desde backend/, con el entorno virtual activado:
    python -m scripts.export_openapi
"""

import json
from pathlib import Path

from app.main import app

RUTA_SALIDA = Path(__file__).resolve().parent.parent.parent / "docs" / "api" / "openapi.json"


def exportar():
    contrato = app.openapi()
    RUTA_SALIDA.parent.mkdir(parents=True, exist_ok=True)
    RUTA_SALIDA.write_text(
        json.dumps(contrato, indent=2, ensure_ascii=False, sort_keys=True),
        encoding="utf-8",
    )
    print(f"Contrato exportado a {RUTA_SALIDA}")


if __name__ == "__main__":
    exportar()
