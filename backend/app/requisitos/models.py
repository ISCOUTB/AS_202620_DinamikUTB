from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, func

from app.core.database import Base


class Requisito(Base):
    __tablename__ = "requisitos"

    id = Column(Integer, primary_key=True, index=True)
    estudiante_id = Column(String, index=True, nullable=False)
    nombre = Column(String, nullable=False)
    estado = Column(String, nullable=False)  # "cumplido", "pendiente", "en_proceso"


class RequisitoHistorial(Base):
    """Registro inmutable de cada cambio sobre un requisito (A-08, ADR-0011).

    Solo se inserta, en la misma transacción que el cambio. Nunca se actualiza ni se borra.
    `actor_id` no es clave foránea: `usuarios/` es otro módulo (ver arc42 §8.4).
    """

    __tablename__ = "requisitos_historial"

    id = Column(Integer, primary_key=True, index=True)
    requisito_id = Column(Integer, ForeignKey("requisitos.id"), index=True, nullable=False)
    estudiante_id = Column(String, index=True, nullable=False)
    campo = Column(String(50), nullable=False)
    valor_anterior = Column(String, nullable=False)
    valor_nuevo = Column(String, nullable=False)
    actor_id = Column(Integer, nullable=True)
    creado_en = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
