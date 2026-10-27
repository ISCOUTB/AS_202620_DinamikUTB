from sqlalchemy import Boolean, Column, Integer, String

from app.core.database import Base


class Programa(Base):
    __tablename__ = "programas"

    id = Column(Integer, primary_key=True, index=True)
    codigo = Column(String(20), unique=True, index=True, nullable=False)
    nombre = Column(String(120), unique=True, nullable=False)
    facultad = Column(String(120), nullable=False)
    duracion_semestres = Column(Integer, nullable=False)
    activo = Column(Boolean, nullable=False, default=True)
