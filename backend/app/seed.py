"""Datos de ejemplo: un usuario por rol, bien armado.

- Estudiante demo (Ana Pérez, Ingeniería de Sistemas y Computación, semestre 7):
  niveles 1 a 6 aprobados con fecha y nota, nivel 7 en curso (2026-2).
- Coordinador demo asignado al programa (directorio de `ayuda/`).
- Administrador demo.

Es idempotente. Para volver al estado inicial del demo:
    python -m app.seed --reiniciar-demo
"""

import os
import sys
from datetime import date

from sqlalchemy import func

from app.ayuda.models import CoordinadorPrograma
from app.core.database import Base, SessionLocal, engine
from app.core.migraciones import asegurar_columnas
from app.core.security import LARGO_MINIMO_PASSWORD
from app.curriculo.catalogo import CODIGO_PLAN, CURSOS_PLAN
from app.curriculo.models import Curso, CursoEstudiante, CursoEstudianteHistorial, PlanEstudio
from app.curriculo.service import poblar_malla_sistemas
from app.estudiantes.models import Estudiante
from app.programas.models import Programa
from app.requisitos.catalogo_utb import ESTADO_DEMO, REQUISITOS_UTB
from app.requisitos.models import Requisito, RequisitoHistorial, RequisitoPrograma
from app.usuarios.roles import Rol
from app.usuarios.service import crear_usuario, obtener_por_email

CODIGO_DEMO = "T000123456"

USUARIOS_DEMO = [
    ("estudiante.demo@dinamikutb.dev", Rol.ESTUDIANTE, CODIGO_DEMO),
    ("coordinador.demo@dinamikutb.dev", Rol.COORDINADOR, None),
    ("administrador.demo@dinamikutb.dev", Rol.ADMINISTRADOR, None),
]

# Nivel -> periodo en que Ana lo aprobó. Ingresó en 2023-2.
PERIODO_POR_NIVEL = {1: "2023-2", 2: "2024-1", 3: "2024-2", 4: "2025-1", 5: "2025-2", 6: "2026-1"}
NIVEL_EN_CURSO = 7
PERIODO_EN_CURSO = "2026-2"
NOTAS = (3.8, 4.2, 3.6, 4.5, 4.0, 3.9, 4.7, 3.5, 4.3, 4.1)


def _cierre_de(periodo: str) -> date:
    anio, semestre = periodo.split("-")
    return date(int(anio), 6, 6) if semestre == "1" else date(int(anio), 11, 24)


def _programa_sistemas(db) -> Programa:
    return (
        db.query(Programa)
        .join(PlanEstudio, PlanEstudio.programa_id == Programa.id)
        .filter(PlanEstudio.codigo == CODIGO_PLAN, Programa.activo.is_(True))
        .first()
    )


def _reiniciar_demo(db) -> None:
    db.query(CursoEstudianteHistorial).filter(CursoEstudianteHistorial.estudiante_id == CODIGO_DEMO).delete()
    db.query(CursoEstudiante).filter(CursoEstudiante.estudiante_id == CODIGO_DEMO).delete()
    db.query(RequisitoHistorial).filter(RequisitoHistorial.estudiante_id == CODIGO_DEMO).delete()
    db.query(Requisito).filter(Requisito.estudiante_id == CODIGO_DEMO).delete()
    db.commit()
    print("Demo reiniciado: se borró el avance y los requisitos del estudiante demo.")


def _poblar_estudiante(db, programa: Programa) -> None:
    estudiante = db.query(Estudiante).filter(Estudiante.codigo_estudiantil == CODIGO_DEMO).first()
    if estudiante is None:
        db.add(Estudiante(codigo_estudiantil=CODIGO_DEMO, nombre="Ana Pérez", programa=programa.nombre, semestre=7))
        print("Se insertó el estudiante demo.")
    else:
        estudiante.programa = programa.nombre
        estudiante.semestre = 7
    db.flush()


def _poblar_catalogo(db, programa: Programa) -> None:
    for item in REQUISITOS_UTB:
        fila = (
            db.query(RequisitoPrograma)
            .filter(
                RequisitoPrograma.programa_id == programa.id,
                RequisitoPrograma.codigo_interno == item["codigo_interno"],
            )
            .first()
        )
        if fila is None:
            # Si ya existía uno con ese nombre y sin código, lo adopta en vez de duplicarlo.
            fila = (
                db.query(RequisitoPrograma)
                .filter(
                    RequisitoPrograma.programa_id == programa.id,
                    func.lower(RequisitoPrograma.nombre) == item["nombre"].lower(),
                    RequisitoPrograma.codigo_interno.is_(None),
                )
                .first()
            )
        if fila is None:
            fila = RequisitoPrograma(programa_id=programa.id)
            db.add(fila)
        for campo, valor in item.items():
            setattr(fila, campo, valor)
        fila.obligatorio = True
        fila.activo = True
    db.flush()


def _poblar_requisitos_demo(db, programa: Programa) -> None:
    catalogo = db.query(RequisitoPrograma).filter(RequisitoPrograma.programa_id == programa.id).all()
    for fila in catalogo:
        if fila.codigo_interno not in ESTADO_DEMO:
            continue
        if (
            db.query(Requisito)
            .filter(Requisito.estudiante_id == CODIGO_DEMO, Requisito.catalogo_id == fila.id)
            .first()
        ):
            continue
        existente = (
            db.query(Requisito)
            .filter(
                Requisito.estudiante_id == CODIGO_DEMO,
                func.lower(Requisito.nombre) == fila.nombre.lower(),
                Requisito.catalogo_id.is_(None),
            )
            .first()
        )
        estado, fecha, periodo, evidencia = ESTADO_DEMO[fila.codigo_interno]
        if existente is None:
            existente = Requisito(
                estudiante_id=CODIGO_DEMO,
                nombre=fila.nombre,
                estado=estado,
                fecha_cumplimiento=fecha,
                periodo=periodo,
                evidencia=evidencia or None,
            )
            db.add(existente)
        existente.catalogo_id = fila.id
    db.flush()


def _poblar_progreso_demo(db) -> None:
    plan = db.query(PlanEstudio).filter(PlanEstudio.codigo == CODIGO_PLAN).first()
    cursos = {c.codigo: c for c in db.query(Curso).filter(Curso.plan_id == plan.id).all()}
    ya = {
        f[0]
        for f in db.query(CursoEstudiante.curso_id).filter(CursoEstudiante.estudiante_id == CODIGO_DEMO)
    }
    creados = 0
    for indice, (codigo, _, nivel, _, _) in enumerate(CURSOS_PLAN):
        curso = cursos[codigo]
        if curso.id in ya:
            continue
        if nivel in PERIODO_POR_NIVEL:
            periodo = PERIODO_POR_NIVEL[nivel]
            fila = CursoEstudiante(
                estudiante_id=CODIGO_DEMO,
                curso_id=curso.id,
                estado="aprobado",
                fecha_aprobacion=_cierre_de(periodo),
                periodo=periodo,
                nota=NOTAS[(indice * 7 + nivel) % len(NOTAS)],
            )
        elif nivel == NIVEL_EN_CURSO:
            fila = CursoEstudiante(
                estudiante_id=CODIGO_DEMO, curso_id=curso.id, estado="en_curso", periodo=PERIODO_EN_CURSO
            )
        else:
            continue
        db.add(fila)
        creados += 1
    if creados:
        print(f"Se registraron {creados} cursos del estudiante demo.")


def _poblar_coordinador(db, programa: Programa) -> None:
    correo = "coordinador.demo@dinamikutb.dev"
    fila = db.query(CoordinadorPrograma).filter(CoordinadorPrograma.correo == correo).first()
    if fila is None:
        fila = CoordinadorPrograma(correo=correo)
        db.add(fila)
    # Datos de ejemplo: reemplazar por los reales de la coordinación antes de usar fuera del curso.
    fila.programa = programa.nombre
    fila.nombre = "Coordinador Demo (Sistemas)"
    fila.cargo = "Coordinación de programa"
    fila.oficina = "Bloque de Ingeniería (por confirmar)"
    fila.campus = "Campus Tecnológico (Ternera)"
    fila.horario = "Lunes a viernes, 8:00-12:00 y 14:00-17:00 (ejemplo)"


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


def poblar(reiniciar: bool = False):
    Base.metadata.create_all(bind=engine)
    for columna in asegurar_columnas(engine, Base.metadata):
        print(f"Columna agregada: {columna}")
    db = SessionLocal()
    try:
        if reiniciar:
            _reiniciar_demo(db)
        poblar_malla_sistemas(db)
        programa = _programa_sistemas(db)
        _poblar_estudiante(db, programa)
        _poblar_catalogo(db, programa)
        _poblar_requisitos_demo(db, programa)
        _poblar_progreso_demo(db)
        _poblar_coordinador(db, programa)
        db.commit()
        _poblar_usuarios(db)
    finally:
        db.close()


if __name__ == "__main__":
    poblar(reiniciar="--reiniciar-demo" in sys.argv)
