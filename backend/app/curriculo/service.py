import unicodedata

from sqlalchemy.orm import Session

from app.curriculo.catalogo import CODIGO_PLAN, CREDITOS_PLAN, CURSOS_PLAN
from app.curriculo.models import Curso, PlanEstudio
from app.programas.models import Programa


def _normalizar(texto: str) -> str:
    descompuesto = unicodedata.normalize("NFKD", texto.casefold())
    return "".join(caracter for caracter in descompuesto if not unicodedata.combining(caracter))


def poblar_malla_sistemas(db: Session) -> int:
    programas = [
        programa
        for programa in db.query(Programa).filter(Programa.activo.is_(True)).all()
        if _normalizar(programa.nombre).startswith("ingenieria de sistemas")
    ]
    if not programas:
        programa = Programa(
            codigo="IS-ISC-201910",
            nombre="Ingeniería de Sistemas y Computación",
            facultad="Facultad de Ingeniería",
            duracion_semestres=10,
            activo=True,
        )
        db.add(programa)
        db.flush()
        programas.append(programa)

    for programa in programas:
        plan = (
            db.query(PlanEstudio)
            .filter(
                PlanEstudio.programa_id == programa.id,
                PlanEstudio.codigo == CODIGO_PLAN,
            )
            .first()
        )
        if plan is None:
            plan = PlanEstudio(
                programa_id=programa.id,
                codigo=CODIGO_PLAN,
                creditos_totales=CREDITOS_PLAN,
                activo=True,
            )
            db.add(plan)
            db.flush()

        existentes = {
            curso.codigo: curso
            for curso in db.query(Curso).filter(Curso.plan_id == plan.id).all()
        }
        for codigo, nombre, nivel, creditos, _ in CURSOS_PLAN:
            if codigo not in existentes:
                curso = Curso(
                    plan_id=plan.id,
                    codigo=codigo,
                    nombre=nombre,
                    nivel=nivel,
                    creditos=creditos,
                    activo=True,
                )
                db.add(curso)
                existentes[codigo] = curso
        db.flush()

        for codigo, _, _, _, codigos_prerrequisitos in CURSOS_PLAN:
            curso = existentes[codigo]
            vinculados = {prerrequisito.codigo for prerrequisito in curso.prerequisitos}
            for codigo_prerrequisito in codigos_prerrequisitos:
                if codigo_prerrequisito not in existentes:
                    raise ValueError(
                        f"El prerrequisito {codigo_prerrequisito} no existe en el plan {CODIGO_PLAN}."
                    )
                if codigo_prerrequisito not in vinculados:
                    curso.prerequisitos.append(existentes[codigo_prerrequisito])
                    vinculados.add(codigo_prerrequisito)

    db.commit()
    return len(programas)


def obtener_malla(db: Session, nombre_programa: str) -> dict:
    programa = (
        db.query(Programa)
        .filter(Programa.nombre == nombre_programa.strip(), Programa.activo.is_(True))
        .first()
    )
    if programa is None:
        raise LookupError("No se encontró un programa académico activo con ese nombre.")

    plan = (
        db.query(PlanEstudio)
        .filter(PlanEstudio.programa_id == programa.id, PlanEstudio.activo.is_(True))
        .order_by(PlanEstudio.codigo.desc())
        .first()
    )
    if plan is None:
        raise LookupError("El programa todavía no tiene una malla curricular publicada.")

    cursos = [curso for curso in plan.cursos if curso.activo]
    return {
        "programa": programa.nombre,
        "plan": plan.codigo,
        "creditos_totales": plan.creditos_totales,
        "cursos": [
            {
                "codigo": curso.codigo,
                "nombre": curso.nombre,
                "nivel": curso.nivel,
                "creditos": curso.creditos,
                "prerequisitos": [
                    prerequisito.codigo
                    for prerequisito in curso.prerequisitos
                    if prerequisito.activo
                ],
            }
            for curso in cursos
        ],
    }
