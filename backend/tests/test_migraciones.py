from sqlalchemy import Column, Integer, MetaData, String, Table, create_engine, inspect, text

from app.core.migraciones import asegurar_columnas


def _engine_con_tabla_vieja():
    engine = create_engine("sqlite://")
    with engine.begin() as conexion:
        conexion.execute(text("CREATE TABLE demo (id INTEGER PRIMARY KEY)"))
    return engine


def test_agrega_la_columna_nullable_que_falta_y_es_idempotente():
    engine = _engine_con_tabla_vieja()
    meta = MetaData()
    Table("demo", meta, Column("id", Integer, primary_key=True), Column("extra", String(10), nullable=True))

    assert asegurar_columnas(engine, meta) == ["demo.extra"]
    assert "extra" in {c["name"] for c in inspect(engine).get_columns("demo")}
    assert asegurar_columnas(engine, meta) == []


def test_no_toca_columnas_not_null_sin_default():
    engine = _engine_con_tabla_vieja()
    meta = MetaData()
    Table("demo", meta, Column("id", Integer, primary_key=True), Column("obligatoria", String(10), nullable=False))

    assert asegurar_columnas(engine, meta) == []


def test_ignora_tablas_que_todavia_no_existen():
    engine = create_engine("sqlite://")
    meta = MetaData()
    Table("nueva", meta, Column("id", Integer, primary_key=True))

    assert asegurar_columnas(engine, meta) == []
