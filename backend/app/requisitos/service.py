import logging

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.requisitos.models import Requisito, RequisitoHistorial

logger = logging.getLogger("dinamikutb")


def obtener_requisitos_por_estudiante(db: Session, estudiante_id: str):
    return (
        db.query(Requisito)
        .filter(Requisito.estudiante_id == estudiante_id)
        .order_by(Requisito.id)
        .all()
    )


def calcular_resumen(db: Session, estudiante_id: str) -> dict:
    """Resumen de avance calculado en la base (Q-01 / A-02).

    Solo los requisitos en estado «cumplido» cuentan como avance: «en_proceso» no suma.
    """
    filas = (
        db.query(Requisito.estado, func.count(Requisito.id))
        .filter(Requisito.estudiante_id == estudiante_id)
        .group_by(Requisito.estado)
        .all()
    )
    conteo = dict(filas)
    cumplidos = conteo.get("cumplido", 0)
    en_proceso = conteo.get("en_proceso", 0)
    pendientes = conteo.get("pendiente", 0)
    total = cumplidos + en_proceso + pendientes
    porcentaje = round(cumplidos * 100 / total, 1) if total else 0.0
    return {
        "total": total,
        "cumplidos": cumplidos,
        "en_proceso": en_proceso,
        "pendientes": pendientes,
        "porcentaje_avance": porcentaje,
    }


def actualizar_estado_requisito(
    db: Session, requisito_id: int, nuevo_estado: str, actor_id: int | None = None
):
    requisito = db.get(Requisito, requisito_id)
    if requisito is None:
        return None
    anterior = requisito.estado
    if anterior == nuevo_estado:
        # Repetir el mismo valor no cambia nada ni genera historial (idempotencia, ADR-0011).
        return requisito

    requisito.estado = nuevo_estado
    # El historial va en la misma transacción que el cambio: quedan ambos o ninguno.
    db.add(
        RequisitoHistorial(
            requisito_id=requisito.id,
            estudiante_id=requisito.estudiante_id,
            campo="estado",
            valor_anterior=anterior,
            valor_nuevo=nuevo_estado,
            actor_id=actor_id,
        )
    )
    db.commit()
    db.refresh(requisito)
    # Telemetría operativa; el registro de auditoría es la tabla requisitos_historial.
    logger.info(
        "auditoria_cambio_estado",
        extra={"campos": {
            "actor_id": actor_id,
            "requisito_id": requisito_id,
            "estado_anterior": anterior,
            "estado_nuevo": nuevo_estado,
        }},
    )
    return requisito


def obtener_historial(db: Session, requisito_id: int):
    """Cambios de un requisito en orden cronológico; None si el requisito no existe."""
    if db.get(Requisito, requisito_id) is None:
        return None
    return (
        db.query(RequisitoHistorial)
        .filter(RequisitoHistorial.requisito_id == requisito_id)
        .order_by(RequisitoHistorial.id)
        .all()
    )
