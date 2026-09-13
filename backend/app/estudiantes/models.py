from sqlalchemy import Column, Integer, String

from app.core.database import Base


class Estudiante(Base):
    __tablename__ = "estudiantes"

    id = Column(Integer, primary_key=True, index=True)
    codigo_estudiantil = Column(String, unique=True, index=True, nullable=False)
    nombre = Column(String, nullable=False)
    programa = Column(String, nullable=False)
