from fastapi import APIRouter, HTTPException

from app.core.database import DbSession
from app.core.validation import CodigoEstudiantilPath
from app.estudiantes import service
from .schemas import EstudianteOut
from app.usuarios.dependencies import CurrentUser, verificar_acceso_estudiante

router = APIRouter(prefix="/estudiantes", tags=["estudiantes"])


@router.get(
    "/{codigo_estudiantil}",
    response_model=EstudianteOut,
    responses={
        401: {"description": "No autenticado"},
        403: {"description": "Sin permisos sobre este recurso"},
        404: {"description": "Estudiante no encontrado"},
    },
)
def consultar_estudiante(codigo_estudiantil: CodigoEstudiantilPath, usuario: CurrentUser, db: DbSession):
    verificar_acceso_estudiante(usuario, codigo_estudiantil)
    estudiante = service.obtener_estudiante(db, codigo_estudiantil)
    if estudiante is None:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")
    return estudiante
