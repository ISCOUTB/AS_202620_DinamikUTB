from typing import Annotated

from fastapi import APIRouter, HTTPException, Query

from app.core.database import DbSession
from app.curriculo import service
from app.curriculo.schemas import MallaOut

router = APIRouter(prefix="/malla", tags=["currículo"])


@router.get("", response_model=MallaOut)
def consultar_malla(
    db: DbSession,
    programa: Annotated[str, Query(min_length=3, max_length=120)],
):
    try:
        return service.obtener_malla(db, programa)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
