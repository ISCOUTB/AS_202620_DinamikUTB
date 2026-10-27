import csv
from io import StringIO

from fastapi import APIRouter, Response
from sqlalchemy import Integer, func

from app.core.database import DbSession
from app.estudiantes.models import Estudiante
from app.requisitos.models import Requisito
from app.usuarios.dependencies import GestorUser
from app.usuarios.models import Usuario

router = APIRouter(prefix="/reportes", tags=["reportes"])


def _celda_csv(value: object) -> str:
    text = str(value if value is not None else "")
    if text.startswith(("=", "+", "-", "@", "\t", "\r")):
        return f"'{text}"
    return text


@router.get("/estudiantes.csv")
def exportar_estudiantes(_gestor: GestorUser, db: DbSession):
    filas = (
        db.query(
            Estudiante.codigo_estudiantil,
            Estudiante.nombre,
            Usuario.email,
            Estudiante.programa,
            Estudiante.semestre,
            Usuario.activo,
            func.sum(func.cast(Requisito.estado == "cumplido", Integer)),
            func.count(Requisito.id),
        )
        .join(Usuario, Usuario.codigo_estudiantil == Estudiante.codigo_estudiantil)
        .outerjoin(Requisito, Requisito.estudiante_id == Estudiante.codigo_estudiantil)
        .filter(Usuario.rol == "estudiante")
        .group_by(
            Estudiante.id,
            Usuario.id,
        )
        .order_by(Estudiante.codigo_estudiantil)
        .all()
    )
    buffer = StringIO(newline="")
    writer = csv.writer(buffer)
    writer.writerow(
        [
            "codigo_estudiantil",
            "nombre",
            "correo",
            "programa",
            "semestre",
            "estado_cuenta",
            "requisitos_cumplidos",
            "total_requisitos",
        ]
    )
    for row in filas:
        writer.writerow([_celda_csv(value) for value in row])
    return Response(
        content="\ufeff" + buffer.getvalue(),
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": 'attachment; filename="dinamikutb-estudiantes.csv"'},
    )
