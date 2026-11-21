"""Agrega columnas nuevas a tablas que ya existen.

`Base.metadata.create_all` crea las tablas que faltan, pero nunca altera una que
ya existe. Como el proyecto no usa Alembic, una columna nueva en un modelo
rompería la base del laboratorio (volumen `pgdata`) en el siguiente arranque.

Este módulo cubre ese hueco solo para el caso simple: columnas nullable (o con
server_default). Cualquier otro cambio sigue necesitando una migración real.
"""

import logging

from sqlalchemy import inspect, text

logger = logging.getLogger("dinamikutb")


def asegurar_columnas(engine, metadata) -> list[str]:
    """Devuelve la lista de `tabla.columna` que agregó (vacía si no había nada)."""
    inspector = inspect(engine)
    citar = engine.dialect.identifier_preparer.quote
    agregadas: list[str] = []
    with engine.begin() as conexion:
        for tabla in metadata.sorted_tables:
            if not inspector.has_table(tabla.name):
                continue
            existentes = {c["name"] for c in inspector.get_columns(tabla.name)}
            for columna in tabla.columns:
                if columna.name in existentes:
                    continue
                if not columna.nullable and columna.server_default is None:
                    logger.warning(
                        "columna_no_agregada",
                        extra={"campos": {"tabla": tabla.name, "columna": columna.name}},
                    )
                    continue
                tipo = columna.type.compile(dialect=engine.dialect)
                conexion.execute(
                    text(f"ALTER TABLE {citar(tabla.name)} ADD COLUMN {citar(columna.name)} {tipo}")
                )
                agregadas.append(f"{tabla.name}.{columna.name}")
    return agregadas
