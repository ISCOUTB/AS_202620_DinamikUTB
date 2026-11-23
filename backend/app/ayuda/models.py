from sqlalchemy import Column, DateTime, Integer, String, func

from app.core.database import Base


class CoordinadorPrograma(Base):
    """Directorio de coordinación por programa (ADR-0016).

    El correo es el vínculo con la cuenta de usuario del coordinador: así
    `usuarios/` no necesita saber de programas.
    """

    __tablename__ = "coordinadores_programa"

    id = Column(Integer, primary_key=True, index=True)
    programa = Column(String(120), nullable=False, index=True)
    nombre = Column(String(120), nullable=False)
    cargo = Column(String(120), nullable=False)
    correo = Column(String(254), unique=True, nullable=False, index=True)
    oficina = Column(String(160), nullable=False, default="")
    campus = Column(String(80), nullable=False, default="")
    horario = Column(String(160), nullable=False, default="")


class SolicitudDiscrepancia(Base):
    __tablename__ = "solicitudes_discrepancia"

    id = Column(Integer, primary_key=True, index=True)
    radicado = Column(String(32), unique=True, nullable=False, index=True)
    estudiante_id = Column(String(20), nullable=False, index=True)
    programa = Column(String(120), nullable=False, index=True)
    tipo_discrepancia = Column(String(40), nullable=False)
    elemento_afectado = Column(String(160), nullable=False)
    descripcion = Column(String(1500), nullable=False)
    referencia_soporte = Column(String(200), nullable=False, default="")
    estado = Column(String(20), nullable=False, default="pendiente")
    respuesta_coordinador = Column(String(1500), nullable=False, default="")
    creado_en = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    actualizado_en = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
