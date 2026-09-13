from sqlalchemy.orm import Session

from app.requisitos.models import Requisito


def obtener_requisitos_por_estudiante(db: Session, estudiante_id: str):
    return (
        db.query(Requisito)
        .filter(Requisito.estudiante_id == estudiante_id)
        .all()
    )

def actualizar_estado_requisito(db: Session, requisito_id: int, nuevo_estado: str):
    requisito = db.query(Requisito).filter(Requisito.id == requisito_id).first()
    if requisito is None:
        return None
    requisito.estado = nuevo_estado
    db.commit()
    db.refresh(requisito)
    return requisito
