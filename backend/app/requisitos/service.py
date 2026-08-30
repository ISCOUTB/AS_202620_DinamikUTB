from sqlalchemy.orm import Session

from app.requisitos.models import Requisito


def obtener_requisitos_por_estudiante(db: Session, estudiante_id: str):
    return (
        db.query(Requisito)
        .filter(Requisito.estudiante_id == estudiante_id)
        .all()
    )
