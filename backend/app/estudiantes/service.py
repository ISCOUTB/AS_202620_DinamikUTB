from sqlalchemy.orm import Session

from app.estudiantes.models import Estudiante


def obtener_estudiante(db: Session, codigo_estudiantil: str):
    return (
        db.query(Estudiante)
        .filter(Estudiante.codigo_estudiantil == codigo_estudiantil)
        .first()
    )
