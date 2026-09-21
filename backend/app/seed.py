"""
Script de datos de ejemplo para desarrollo local.

Inserta requisitos de prueba para poder ver la pantalla de Flutter con
contenido real, sin depender de que alguien los cargue a mano.

Uso: desde la carpeta backend/, con el entorno virtual activado:
    python -m app.seed
"""

from app.core.database import Base, SessionLocal, engine
from app.requisitos.models import Requisito

REQUISITOS_DE_EJEMPLO = [
    Requisito(estudiante_id="T000123456", nombre="Inglés B2", estado="pendiente"),
    Requisito(
        estudiante_id="T000123456",
        nombre="Práctica profesional",
        estado="cumplido",
    ),
    Requisito(
        estudiante_id="T000123456",
        nombre="Electiva de profundización",
        estado="en_proceso",
    ),
]


def poblar():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        ya_existen = db.query(Requisito).count() > 0
        if ya_existen:
            print("Ya hay datos en la base. No se insertó nada para evitar duplicados.")
            return

        db.add_all(REQUISITOS_DE_EJEMPLO)
        db.commit()
        print(f"Se insertaron {len(REQUISITOS_DE_EJEMPLO)} requisitos de ejemplo.")
    finally:
        db.close()


if __name__ == "__main__":
    poblar()
