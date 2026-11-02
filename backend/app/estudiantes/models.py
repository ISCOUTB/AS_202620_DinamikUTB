from sqlalchemy import Column, DateTime, Integer, String, func

from app.core.database import Base


class Estudiante(Base):
    __tablename__ = "estudiantes"

    id = Column(Integer, primary_key=True, index=True)
    codigo_estudiantil = Column(String, unique=True, index=True, nullable=False)
    nombre = Column(String, nullable=False)
    programa = Column(String, nullable=False)
    semestre = Column(Integer, nullable=True, default=1)


class EstudianteHistorial(Base):
    """Registro inmutable de modificaciones sobre datos del estudiante (A-08, ADR-0014).

    Registra cambios de nombre, programa o semestre en la misma transacción.
    """

    __tablename__ = "estudiantes_historial"

    id = Column(Integer, primary_key=True, index=True)
    estudiante_id = Column(String, index=True, nullable=False)
    campo = Column(String(50), nullable=False)
    valor_anterior = Column(String, nullable=False)
    valor_nuevo = Column(String, nullable=False)
    actor_id = Column(Integer, nullable=True)
    creado_en = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
