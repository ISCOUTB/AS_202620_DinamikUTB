from datetime import date
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field, StringConstraints

Categoria = Literal["Academico", "Idiomas", "Evaluacion", "Proyeccion", "Administrativo"]


class RequisitoOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    estado: str


class RequisitoEstadoUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    estado: Literal["cumplido", "pendiente", "en_proceso"]


class ElegibilidadOut(BaseModel):
    requisito_id: int
    nombre: str
    porcentaje_requerido: int
    creditos_requeridos: int
    creditos_aprobados: int
    creditos_faltantes: int
    habilitado: bool


class ResumenRequisitosOut(BaseModel):
    total: int
    cumplidos: int
    en_proceso: int
    pendientes: int
    porcentaje_avance: float
    elegibilidad: list[ElegibilidadOut] = []


class PasoGuia(BaseModel):
    titulo: Annotated[str, StringConstraints(strip_whitespace=True, min_length=2, max_length=120)]
    detalle: Annotated[str, StringConstraints(strip_whitespace=True, max_length=400)] = ""
    oficina: Annotated[str, StringConstraints(strip_whitespace=True, max_length=120)] = ""


class RequisitoRutaOut(BaseModel):
    id: int
    nombre: str
    estado: str
    codigo_interno: str | None = None
    categoria: str | None = None
    fecha_cumplimiento: date | None = None
    periodo: str | None = None
    evidencia: str | None = None
    porcentaje_creditos_requerido: int | None = None
    creditos_requeridos: int | None = None
    creditos_faltantes: int | None = None
    habilitado: bool | None = None
    portal_oficial: str | None = None
    tiempo_estimado: str | None = None
    guia_resumen: str | None = None
    pasos_guia: list[PasoGuia] = []


class RequisitoDetalleUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    fecha_cumplimiento: date | None = None
    periodo: Annotated[str, StringConstraints(pattern=r"^\d{4}-[12]$")] | None = None
    evidencia: Annotated[str, StringConstraints(strip_whitespace=True, max_length=300)] | None = None


class RequisitoDetalleOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    estado: str
    fecha_cumplimiento: date | None
    periodo: str | None
    evidencia: str | None


class RequisitoCatalogoIn(BaseModel):
    programa_id: int
    nombre: str
    descripcion: str = ""
    semestre_recomendado: int = 1
    obligatorio: bool = True
    codigo_interno: Annotated[str, StringConstraints(max_length=30)] | None = None
    categoria: Categoria | None = None
    porcentaje_creditos_requerido: int | None = Field(default=None, ge=1, le=100)
    portal_oficial: Annotated[str, StringConstraints(max_length=300)] | None = None
    tiempo_estimado: Annotated[str, StringConstraints(max_length=80)] | None = None
    guia_resumen: Annotated[str, StringConstraints(max_length=800)] | None = None
    pasos_guia: list[PasoGuia] | None = None


class RequisitoCatalogoUpdate(RequisitoCatalogoIn):
    """Edición de un requisito del catálogo.

    Solo se escriben los campos que el cliente envía (`exclude_unset`): el panel
    de administración no manda la guía, y no debe borrarla al guardar.
    """

    activo: bool = True
