from sqlalchemy import (
    Boolean,
    Column,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Table,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import relationship

from app.core.database import Base

CURSO_ID_FK = "cursos.id"

curso_prerrequisitos = Table(
    "curso_prerrequisitos",
    Base.metadata,
    Column("curso_id", ForeignKey(CURSO_ID_FK, ondelete="CASCADE"), primary_key=True),
    Column(
        "prerrequisito_id",
        ForeignKey(CURSO_ID_FK, ondelete="CASCADE"),
        primary_key=True,
    ),
)


class PlanEstudio(Base):
    __tablename__ = "planes_estudio"
    __table_args__ = (
        UniqueConstraint("programa_id", "codigo", name="uq_plan_programa_codigo"),
    )

    id = Column(Integer, primary_key=True, index=True)
    programa_id = Column(Integer, ForeignKey("programas.id"), nullable=False, index=True)
    codigo = Column(String(20), nullable=False)
    creditos_totales = Column(Integer, nullable=False)
    activo = Column(Boolean, nullable=False, default=True)

    cursos = relationship(
        "Curso",
        back_populates="plan",
        cascade="all, delete-orphan",
        order_by="Curso.nivel, Curso.codigo",
    )


class Curso(Base):
    __tablename__ = "cursos"
    __table_args__ = (
        UniqueConstraint("plan_id", "codigo", name="uq_curso_plan_codigo"),
    )

    id = Column(Integer, primary_key=True, index=True)
    plan_id = Column(Integer, ForeignKey("planes_estudio.id"), nullable=False, index=True)
    codigo = Column(String(20), nullable=False)
    nombre = Column(String(160), nullable=False)
    nivel = Column(Integer, nullable=False)
    creditos = Column(Integer, nullable=False)
    activo = Column(Boolean, nullable=False, default=True)

    plan = relationship("PlanEstudio", back_populates="cursos")
    prerequisitos = relationship(
        "Curso",
        secondary=curso_prerrequisitos,
        primaryjoin=id == curso_prerrequisitos.c.curso_id,
        secondaryjoin=id == curso_prerrequisitos.c.prerrequisito_id,
        back_populates="habilita",
        order_by="Curso.codigo",
    )
    habilita = relationship(
        "Curso",
        secondary=curso_prerrequisitos,
        primaryjoin=id == curso_prerrequisitos.c.prerrequisito_id,
        secondaryjoin=id == curso_prerrequisitos.c.curso_id,
        back_populates="prerequisitos",
        order_by="Curso.codigo",
    )


class CursoEstudiante(Base):
    """Estado de un curso para un estudiante (ADR-0015).

    `estudiante_id` es un valor (código estudiantil), no una clave foránea hacia
    `estudiantes/`: la propiedad de datos se respeta igual que en `Requisito`.
    `curso_id` sí es FK porque el curso es del mismo módulo.
    Un curso sin fila equivale a «pendiente».
    """

    __tablename__ = "cursos_estudiante"
    __table_args__ = (
        UniqueConstraint("estudiante_id", "curso_id", name="uq_curso_estudiante"),
    )

    id = Column(Integer, primary_key=True, index=True)
    estudiante_id = Column(String(20), nullable=False, index=True)
    curso_id = Column(Integer, ForeignKey("cursos.id"), nullable=False, index=True)
    estado = Column(String(20), nullable=False, default="pendiente")  # aprobado | en_curso | pendiente
    fecha_aprobacion = Column(Date, nullable=True)
    periodo = Column(String(10), nullable=True)  # "2025-1"
    nota = Column(Float, nullable=True)

    curso = relationship("Curso")


class CursoEstudianteHistorial(Base):
    """Auditoría append-only de `cursos_estudiante` (ADR-0011, mismo patrón)."""

    __tablename__ = "cursos_estudiante_historial"

    id = Column(Integer, primary_key=True, index=True)
    curso_estudiante_id = Column(
        Integer, ForeignKey("cursos_estudiante.id"), nullable=False, index=True
    )
    estudiante_id = Column(String(20), nullable=False, index=True)
    curso_codigo = Column(String(20), nullable=False)
    campo = Column(String(50), nullable=False)
    valor_anterior = Column(String, nullable=False)
    valor_nuevo = Column(String, nullable=False)
    actor_id = Column(Integer, nullable=True)
    creado_en = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
