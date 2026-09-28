"""
Script de datos de ejemplo para desarrollo local y para el ambiente desplegado.

Inserta un estudiante y requisitos de prueba para poder ver la pantalla de
Flutter con contenido real. Es idempotente: no duplica datos por tabla.

Uso: desde la carpeta backend/, con el entorno virtual activado:
    python -m app.seed
"""

from app.core.database import Base, SessionLocal, engine
from app.estudiantes.models import Estudiante
from app.requisitos.models import Requisito

ESTUDIANTE_DE_EJEMPLO = {
    "codigo_estudiantil": "T000123456",
    "nombre": "Ana Pérez",
    "programa": "Ingeniería de Sistemas",
}

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
        if db.query(Estudiante).count() == 0:
            db.add(Estudiante(**ESTUDIANTE_DE_EJEMPLO))
            print("Se insertó 1 estudiante de ejemplo.")
        else:
            print("Ya hay estudiantes en la base. No se insertó ninguno.")

        if db.query(Requisito).count() == 0:
            db.add_all(REQUISITOS_DE_EJEMPLO)
            print(f"Se insertaron {len(REQUISITOS_DE_EJEMPLO)} requisitos de ejemplo.")
        else:
            print("Ya hay requisitos en la base. No se insertó ninguno.")

        db.commit()
    finally:
        db.close()


if __name__ == "__main__":
    poblar()
