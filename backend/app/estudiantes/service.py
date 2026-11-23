from sqlalchemy.orm import Session

from app.estudiantes.models import Estudiante, EstudianteHistorial


def obtener_estudiante(db: Session, codigo_estudiantil: str):
    return (
        db.query(Estudiante)
        .filter(Estudiante.codigo_estudiantil == codigo_estudiantil)
        .first()
    )


def actualizar_datos_estudiante(
    db: Session,
    codigo_estudiantil: str,
    nombre: str,
    programa: str,
    semestre: int | None,
    actor_id: int | None = None,
) -> Estudiante | None:
    estudiante = (
        db.query(Estudiante)
        .filter(Estudiante.codigo_estudiantil == codigo_estudiantil)
        .with_for_update()
        .first()
    )
    if not estudiante:
        return None

    cambios = [
        ("nombre", estudiante.nombre, nombre),
        ("programa", estudiante.programa, programa),
        ("semestre", str(estudiante.semestre or ""), str(semestre or "")),
    ]

    for campo, anterior, nuevo in cambios:
        if anterior != nuevo:
            setattr(estudiante, campo, int(nuevo) if campo == "semestre" and nuevo else nuevo)
            db.add(
                EstudianteHistorial(
                    estudiante_id=codigo_estudiantil,
                    campo=campo,
                    valor_anterior=anterior,
                    valor_nuevo=nuevo,
                    actor_id=actor_id,
                )
            )

    # single transaction: UPDATE + history rows, atomic
    db.commit()
    db.refresh(estudiante)
    return estudiante


def actualizar_programa_masivo(
    db: Session,
    nombre_anterior: str,
    nombre_nuevo: str,
    actor_id: int | None = None,
) -> int:
    """Actualiza en masa el programa de los estudiantes y registra su historial."""
    estudiantes = (
        db.query(Estudiante)
        .filter(Estudiante.programa == nombre_anterior)
        .all()
    )
    for est in estudiantes:
        est.programa = nombre_nuevo
        db.add(
            EstudianteHistorial(
                estudiante_id=est.codigo_estudiantil,
                campo="programa",
                valor_anterior=nombre_anterior,
                valor_nuevo=nombre_nuevo,
                actor_id=actor_id,
            )
        )
    return len(estudiantes)
