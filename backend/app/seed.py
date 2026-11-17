import os

from app.core.database import Base, SessionLocal, engine
from app.core.security import LARGO_MINIMO_PASSWORD
from app.curriculo import models as curriculo_models  # noqa: F401
from app.estudiantes.models import Estudiante
from app.programas import models as programas_models  # noqa: F401
from app.requisitos.models import Requisito
from app.requisitos import models as requisitos_models  # noqa: F401
from app.usuarios import models as usuarios_models  # noqa: F401
from app.usuarios.roles import Rol
from app.usuarios.service import crear_usuario, obtener_por_email

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

USUARIOS_DEMO = [
    ("estudiante.demo@dinamikutb.dev", Rol.ESTUDIANTE, "T000123456"),
    ("coordinador.demo@dinamikutb.dev", Rol.COORDINADOR, None),
    ("administrador.demo@dinamikutb.dev", Rol.ADMINISTRADOR, None),
]


def _poblar_usuarios(db) -> None:
    password = os.getenv("SEED_DEMO_PASSWORD", "")
    if len(password) < LARGO_MINIMO_PASSWORD:
        print("SEED_DEMO_PASSWORD no definida (o < 12 caracteres): no se crearon usuarios demo.")
        return
    for email, rol, codigo in USUARIOS_DEMO:
        if obtener_por_email(db, email) is None:
            crear_usuario(db, email, password, rol, codigo)
            print(f"Se creó el usuario demo {email} ({rol.value}).")
        else:
            print(f"El usuario demo {email} ya existe.")


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
        _poblar_usuarios(db)
    finally:
        db.close()


if __name__ == "__main__":
    poblar()
