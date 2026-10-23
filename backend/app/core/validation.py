"""Reglas de validación compartidas entre módulos (entrada tratada siempre como no confiable)."""

from typing import Annotated

from fastapi import Path

# Los códigos estudiantiles solo admiten caracteres alfanuméricos.
CODIGO_ESTUDIANTIL_PATTERN = r"^[A-Za-z0-9]{4,20}$"

CodigoEstudiantilPath = Annotated[
    str,
    Path(pattern=CODIGO_ESTUDIANTIL_PATTERN, description="Código estudiantil (alfanumérico, 4 a 20 caracteres)"),
]

ID_ENTERO_MAX = 2_147_483_647  # límite de INTEGER en PostgreSQL: evita errores 500 por desbordamiento
