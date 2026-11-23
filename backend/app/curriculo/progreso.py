"""Progreso curricular de un estudiante sobre el plan de su programa.

Sirve a A-02 (cálculo correcto), A-06 (varios programas) y A-08 (historial).
Toda escritura va en una sola transacción con su fila de historial (ADR-0011).
"""

from __future__ import annotations

from datetime import date

from sqlalchemy.orm import Session

from app.curriculo.models import (
    Curso,
    CursoEstudiante,
    CursoEstudianteHistorial,
    PlanEstudio,
)
from app.estudiantes.models import Estudiante
from app.estudiantes.service import obtener_estudiante
from app.programas.models import Programa

NOTA_MINIMA = 3.0


class ProgresoInvalido(ValueError):
    """Combinación de estado, fecha, periodo o nota que no tiene sentido."""


class PrerrequisitosPendientes(Exception):
    def __init__(self, faltantes: list[str]):
        super().__init__("Faltan prerrequisitos por aprobar.")
        self.faltantes = faltantes


def periodo_de(fecha: date) -> str:
    return f"{fecha.year}-{1 if fecha.month <= 6 else 2}"


def sumar_periodos(periodo: str, n: int) -> str:
    anio, semestre = (int(x) for x in periodo.split("-"))
    indice = anio * 2 + (semestre - 1) + n
    return f"{indice // 2}-{indice % 2 + 1}"


def _contexto(db: Session, codigo: str) -> tuple[Estudiante, PlanEstudio]:
    estudiante = obtener_estudiante(db, codigo)
    if estudiante is None:
        raise LookupError("Estudiante no encontrado.")
    programa = (
        db.query(Programa)
        .filter(Programa.nombre == estudiante.programa.strip(), Programa.activo.is_(True))
        .first()
    )
    if programa is None:
        raise LookupError("El programa del estudiante no está activo en el catálogo.")
    plan = (
        db.query(PlanEstudio)
        .filter(PlanEstudio.programa_id == programa.id, PlanEstudio.activo.is_(True))
        .order_by(PlanEstudio.codigo.desc())
        .first()
    )
    if plan is None:
        raise LookupError("El programa todavía no tiene una malla curricular publicada.")
    return estudiante, plan


def calcular_progreso(db: Session, codigo: str, hoy: date | None = None) -> dict:
    hoy = hoy or date.today()
    estudiante, plan = _contexto(db, codigo)
    cursos = [c for c in plan.cursos if c.activo]
    filas = {
        f.curso_id: f
        for f in db.query(CursoEstudiante).filter(CursoEstudiante.estudiante_id == codigo).all()
    }

    def estado_de(curso: Curso) -> str:
        fila = filas.get(curso.id)
        return fila.estado if fila else "pendiente"

    aprobados = {c.id for c in cursos if estado_de(c) == "aprobado"}

    items = []
    for curso in cursos:
        fila = filas.get(curso.id)
        estado = estado_de(curso)
        prerequisitos = [p for p in curso.prerequisitos if p.activo]
        faltantes = [p.codigo for p in prerequisitos if p.id not in aprobados]
        desbloqueada = estado != "pendiente" or not faltantes
        items.append(
            {
                "codigo": curso.codigo,
                "nombre": curso.nombre,
                "nivel": curso.nivel,
                "creditos": curso.creditos,
                "prerequisitos": [p.codigo for p in prerequisitos],
                "desbloquea": [h.codigo for h in curso.habilita if h.activo],
                "estado": estado,
                "desbloqueada": desbloqueada,
                "prerequisitos_faltantes": [] if desbloqueada else faltantes,
                "fecha_aprobacion": fila.fecha_aprobacion if fila else None,
                "periodo": fila.periodo if fila else None,
                "nota": fila.nota if fila else None,
            }
        )

    total = plan.creditos_totales
    cred_aprobados = sum(i["creditos"] for i in items if i["estado"] == "aprobado")
    cred_en_curso = sum(i["creditos"] for i in items if i["estado"] == "en_curso")
    pendientes = max(0, total - cred_aprobados - cred_en_curso)

    con_nota = [
        (i["nota"], i["creditos"])
        for i in items
        if i["estado"] == "aprobado" and i["nota"] is not None and i["creditos"] > 0
    ]
    peso = sum(cr for _, cr in con_nota)
    promedio = round(sum(n * cr for n, cr in con_nota) / peso, 2) if peso else None

    por_nivel: dict[int, list[int]] = {}
    for i in items:
        acumulado = por_nivel.setdefault(i["nivel"], [0, 0])
        acumulado[0] += i["creditos"]
        if i["estado"] == "aprobado":
            acumulado[1] += i["creditos"]
    niveles = [
        {
            "nivel": nivel,
            "creditos_totales": tot,
            "creditos_aprobados": apr,
            "porcentaje": round(apr * 100 / tot, 1) if tot else 0.0,
        }
        for nivel, (tot, apr) in sorted(por_nivel.items())
    ]

    # Proyección: ritmo medio del plan = créditos totales / número de niveles.
    # Techo con enteros (pendientes / ritmo) para no depender de errores de flotante.
    niveles_plan = max(len(por_nivel), 1)
    restantes = (pendientes * niveles_plan + total - 1) // total if pendientes and total else 0
    periodos_en_curso = [i["periodo"] for i in items if i["estado"] == "en_curso" and i["periodo"]]
    periodo_actual = max(periodos_en_curso) if periodos_en_curso else periodo_de(hoy)
    if cred_aprobados >= total:
        grado = None
    elif periodos_en_curso:
        grado = sumar_periodos(periodo_actual, restantes)
    else:
        grado = sumar_periodos(periodo_actual, max(restantes - 1, 0))

    return {
        "codigo_estudiantil": codigo,
        "programa": estudiante.programa,
        "plan": plan.codigo,
        "periodo_actual": periodo_actual,
        "resumen": {
            "creditos_totales": total,
            "creditos_aprobados": cred_aprobados,
            "creditos_en_curso": cred_en_curso,
            "creditos_pendientes": pendientes,
            "porcentaje_global": round(cred_aprobados * 100 / total, 1) if total else 0.0,
            "promedio_acumulado": promedio,
            "cursos_aprobados": sum(1 for i in items if i["estado"] == "aprobado"),
            "cursos_total": len(items),
            "semestres_restantes": restantes,
            "periodo_grado_estimado": grado,
        },
        "niveles": niveles,
        "cursos": items,
    }


def creditos_del_estudiante(db: Session, codigo: str) -> tuple[int, int] | None:
    """(créditos totales del plan, créditos aprobados) o None si no hay plan."""
    try:
        resumen = calcular_progreso(db, codigo)["resumen"]
    except LookupError:
        return None
    return resumen["creditos_totales"], resumen["creditos_aprobados"]


def _txt(valor) -> str:
    return "" if valor is None else str(valor)


def _validar(estado: str, fecha: date | None, periodo: str | None, nota: float | None, hoy: date):
    if estado == "aprobado":
        if fecha is None or periodo is None:
            raise ProgresoInvalido("Un curso aprobado necesita fecha de aprobación y periodo.")
        if fecha > hoy:
            raise ProgresoInvalido("La fecha de aprobación no puede ser futura.")
        if nota is not None and nota < NOTA_MINIMA:
            raise ProgresoInvalido(f"Con nota menor a {NOTA_MINIMA} el curso no está aprobado.")
    elif estado == "en_curso" and periodo is None:
        raise ProgresoInvalido("Un curso en curso necesita su periodo.")


def actualizar_progreso(
    db: Session,
    codigo: str,
    curso_codigo: str,
    estado: str,
    fecha: date | None,
    periodo: str | None,
    nota: float | None,
    actor_id: int | None = None,
    hoy: date | None = None,
) -> dict:
    hoy = hoy or date.today()
    _, plan = _contexto(db, codigo)
    curso = (
        db.query(Curso)
        .filter(Curso.plan_id == plan.id, Curso.codigo == curso_codigo, Curso.activo.is_(True))
        .first()
    )
    if curso is None:
        raise LookupError("El curso no existe en el plan del estudiante.")

    _validar(estado, fecha, periodo, nota, hoy)
    nota = round(float(nota), 2) if nota is not None else None
    if estado == "pendiente":
        fecha = periodo = nota = None
    elif estado == "en_curso":
        fecha = nota = None

    if estado in ("aprobado", "en_curso"):
        aprobados = {
            fila[0]
            for fila in db.query(CursoEstudiante.curso_id).filter(
                CursoEstudiante.estudiante_id == codigo, CursoEstudiante.estado == "aprobado"
            )
        }
        faltantes = [p.codigo for p in curso.prerequisitos if p.activo and p.id not in aprobados]
        if faltantes:
            raise PrerrequisitosPendientes(faltantes)

    fila = (
        db.query(CursoEstudiante)
        .filter(CursoEstudiante.estudiante_id == codigo, CursoEstudiante.curso_id == curso.id)
        .with_for_update()
        .first()
    )
    previos = {
        "estado": fila.estado if fila else "pendiente",
        "fecha_aprobacion": _txt(fila.fecha_aprobacion if fila else None),
        "periodo": _txt(fila.periodo if fila else None),
        "nota": _txt(fila.nota if fila else None),
    }
    nuevos = {
        "estado": estado,
        "fecha_aprobacion": _txt(fecha),
        "periodo": _txt(periodo),
        "nota": _txt(nota),
    }
    cambios = [(c, previos[c], nuevos[c]) for c in nuevos if previos[c] != nuevos[c]]

    if cambios:
        if fila is None:
            fila = CursoEstudiante(estudiante_id=codigo, curso_id=curso.id)
            db.add(fila)
            db.flush()
        fila.estado = estado
        fila.fecha_aprobacion = fecha
        fila.periodo = periodo
        fila.nota = nota
        for campo, anterior, nuevo in cambios:
            db.add(
                CursoEstudianteHistorial(
                    curso_estudiante_id=fila.id,
                    estudiante_id=codigo,
                    curso_codigo=curso.codigo,
                    campo=campo,
                    valor_anterior=anterior,
                    valor_nuevo=nuevo,
                    actor_id=actor_id,
                )
            )
        # single transaction: UPDATE + history rows, atomic
        db.commit()

    progreso = calcular_progreso(db, codigo, hoy)
    return next(c for c in progreso["cursos"] if c["codigo"] == curso.codigo)


def obtener_historial(db: Session, codigo: str):
    return (
        db.query(CursoEstudianteHistorial)
        .filter(CursoEstudianteHistorial.estudiante_id == codigo)
        .order_by(CursoEstudianteHistorial.id)
        .all()
    )
