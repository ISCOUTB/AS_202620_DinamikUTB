from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String, func

from app.core.database import Base


class RequisitoPrograma(Base):
    """Catálogo de requisitos configurados por programa académico (A-06)."""
    __tablename__ = "requisitos_programa"

    id = Column(Integer, primary_key=True, index=True)
    programa_id = Column(Integer, ForeignKey("programas.id"), nullable=False, index=True)
    nombre = Column(String(160), nullable=False)
    descripcion = Column(String(500), nullable=False, default="")
    semestre_recomendado = Column(Integer, nullable=False, default=1)
    obligatorio = Column(Boolean, nullable=False, default=True)
    activo = Column(Boolean, nullable=False, default=True)


class Requisito(Base):
    __tablename__ = "requisitos"

    id = Column(Integer, primary_key=True, index=True)
    estudiante_id = Column(String, index=True, nullable=False)
    nombre = Column(String, nullable=False)
    estado = Column(String, nullable=False)  # "cumplido", "pendiente", "en_proceso"
    catalogo_id = Column(Integer, nullable=True)


class RequisitoHistorial(Base):
    __tablename__ = "requisitos_historial"

    id = Column(Integer, primary_key=True, index=True)
    requisito_id = Column(Integer, ForeignKey("requisitos.id"), index=True, nullable=False)
    estudiante_id = Column(String, index=True, nullable=False)
    campo = Column(String(50), nullable=False)
    valor_anterior = Column(String, nullable=False)
    valor_nuevo = Column(String, nullable=False)
    actor_id = Column(Integer, nullable=True)
    creado_en = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
