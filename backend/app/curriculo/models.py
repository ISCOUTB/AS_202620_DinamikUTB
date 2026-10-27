from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Table, UniqueConstraint
from sqlalchemy.orm import relationship

from app.core.database import Base

curso_prerrequisitos = Table(
    "curso_prerrequisitos",
    Base.metadata,
    Column("curso_id", ForeignKey("cursos.id", ondelete="CASCADE"), primary_key=True),
    Column(
        "prerrequisito_id",
        ForeignKey("cursos.id", ondelete="CASCADE"),
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
