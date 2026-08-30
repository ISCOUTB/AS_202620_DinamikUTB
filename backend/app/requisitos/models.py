from sqlalchemy import Column, Integer, String

from app.core.database import Base


class Requisito(Base):
    __tablename__ = "requisitos"

    id = Column(Integer, primary_key=True, index=True)
    estudiante_id = Column(String, index=True, nullable=False)
    nombre = Column(String, nullable=False)
    estado = Column(String, nullable=False)  # "cumplido", "pendiente", "en_proceso"
