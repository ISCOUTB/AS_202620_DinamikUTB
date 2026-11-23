import logging
from datetime import date

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.curriculo.progreso import creditos_del_estudiante
from app.requisitos.models import Requisito, RequisitoHistorial, RequisitoPrograma

logger = logging.getLogger("dinamikutb")


def obtener_requisitos_por_estudiante(db: Session, estudiante_id: str):
    return (
        db.query(Requisito)
        .filter(Requisito.estudiante_id == estudiante_id)
        .order_by(Requisito.id)
        .all()
    )


def calcular_elegibilidad(db: Session, estudiante_id: str) -> list[dict]:
    """Para cada requisito con umbral de créditos: cuántos faltan para habilitarse."""
    creditos = creditos_del_estudiante(db, estudiante_id)
    if creditos is None:
        return []
    total, aprobados = creditos
    filas = (
        db.query(Requisito, RequisitoPrograma)
        .join(RequisitoPrograma, RequisitoPrograma.id == Requisito.catalogo_id)
        .filter(
            Requisito.estudiante_id == estudiante_id,
            RequisitoPrograma.porcentaje_creditos_requerido.isnot(None),
        )
        .order_by(Requisito.id)
        .all()
    )
    resultado = []
    for requisito, catalogo in filas:
        pct = catalogo.porcentaje_creditos_requerido
        requeridos = (total * pct + 99) // 100  # techo entero, sin errores de flotante
        faltan = max(0, requeridos - aprobados)
        resultado.append(
            {
                "requisito_id": requisito.id,
                "nombre": requisito.nombre,
                "porcentaje_requerido": pct,
                "creditos_requeridos": requeridos,
                "creditos_aprobados": aprobados,
                "creditos_faltantes": faltan,
                "habilitado": faltan == 0,
            }
        )
    return resultado


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
        "elegibilidad": calcular_elegibilidad(db, estudiante_id),
    }


def obtener_ruta(db: Session, estudiante_id: str) -> list[dict]:
    """Requisitos del estudiante con su guía de cumplimiento y elegibilidad."""
    elegibilidad = {e["requisito_id"]: e for e in calcular_elegibilidad(db, estudiante_id)}
    filas = (
        db.query(Requisito, RequisitoPrograma)
        .outerjoin(RequisitoPrograma, RequisitoPrograma.id == Requisito.catalogo_id)
        .filter(Requisito.estudiante_id == estudiante_id)
        .order_by(Requisito.id)
        .all()
    )
    ruta = []
    for requisito, catalogo in filas:
        e = elegibilidad.get(requisito.id)
        ruta.append(
            {
                "id": requisito.id,
                "nombre": requisito.nombre,
                "estado": requisito.estado,
                "codigo_interno": catalogo.codigo_interno if catalogo else None,
                "categoria": catalogo.categoria if catalogo else None,
                "fecha_cumplimiento": requisito.fecha_cumplimiento,
                "periodo": requisito.periodo,
                "evidencia": requisito.evidencia,
                "porcentaje_creditos_requerido": e["porcentaje_requerido"] if e else None,
                "creditos_requeridos": e["creditos_requeridos"] if e else None,
                "creditos_faltantes": e["creditos_faltantes"] if e else None,
                "habilitado": e["habilitado"] if e else None,
                "portal_oficial": catalogo.portal_oficial if catalogo else None,
                "tiempo_estimado": catalogo.tiempo_estimado if catalogo else None,
                "guia_resumen": catalogo.guia_resumen if catalogo else None,
                "pasos_guia": (catalogo.pasos_guia or []) if catalogo else [],
            }
        )
    return ruta


def actualizar_estado_requisito(
    db: Session, requisito_id: int, nuevo_estado: str, actor_id: int | None = None
):
    # with_for_update=True serializa escrituras en PostgreSQL evitando condiciones de carrera
    requisito = db.get(Requisito, requisito_id, with_for_update=True)
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
    # single transaction: UPDATE + history row, atomic
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


class DetalleInvalido(ValueError):
    pass


def _txt(valor) -> str:
    return "" if valor is None else str(valor)


def actualizar_detalle_requisito(
    db: Session,
    requisito_id: int,
    fecha: date | None,
    periodo: str | None,
    evidencia: str | None,
    actor_id: int | None = None,
    hoy: date | None = None,
):
    """Fecha, periodo y evidencia de cumplimiento, con historial por campo."""
    if fecha is not None and fecha > (hoy or date.today()):
        raise DetalleInvalido("La fecha de cumplimiento no puede ser futura.")
    requisito = db.get(Requisito, requisito_id, with_for_update=True)
    if requisito is None:
        return None
    nuevos = {"fecha_cumplimiento": fecha, "periodo": periodo, "evidencia": evidencia or None}
    cambios = [
        (campo, getattr(requisito, campo), nuevo)
        for campo, nuevo in nuevos.items()
        if _txt(getattr(requisito, campo)) != _txt(nuevo)
    ]
    if not cambios:
        return requisito
    for campo, anterior, nuevo in cambios:
        setattr(requisito, campo, nuevo)
        db.add(
            RequisitoHistorial(
                requisito_id=requisito.id,
                estudiante_id=requisito.estudiante_id,
                campo=campo,
                valor_anterior=_txt(anterior),
                valor_nuevo=_txt(nuevo),
                actor_id=actor_id,
            )
        )
    # single transaction: UPDATE + history rows, atomic
    db.commit()
    db.refresh(requisito)
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
