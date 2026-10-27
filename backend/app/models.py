"""Modelos de la base de datos: usuarios, fichas de estudio y dudas."""
from datetime import datetime, timezone

from sqlalchemy import JSON, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .db import Base


def ahora() -> datetime:
    return datetime.now(timezone.utc)


class Usuario(Base):
    __tablename__ = "usuarios"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    email: Mapped[str] = mapped_column(String(254), unique=True, index=True)
    nombre: Mapped[str] = mapped_column(String(80))
    hash_clave: Mapped[str] = mapped_column(String(100))
    creado: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=ahora)

    dudas: Mapped[list["Duda"]] = relationship(back_populates="autor")


class Ficha(Base):
    """Ficha de estudio de una sesión. Se siembra desde app/data/fichas.json."""

    __tablename__ = "fichas"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    codigo: Mapped[str] = mapped_column(String(20), unique=True, index=True)
    materia: Mapped[str] = mapped_column(String(40), index=True)
    materia_nombre: Mapped[str] = mapped_column(String(60))
    unidad: Mapped[int] = mapped_column(Integer)
    unidad_nombre: Mapped[str] = mapped_column(String(200))
    sesion: Mapped[str] = mapped_column(String(10))
    titulo: Mapped[str] = mapped_column(String(200))
    silabo: Mapped[str] = mapped_column(String(300))
    ideas_clave: Mapped[list[str]] = mapped_column(JSON)
    formulas: Mapped[list[str]] = mapped_column(JSON)
    preguntas: Mapped[list[str]] = mapped_column(JSON)
    normas: Mapped[list[str]] = mapped_column(JSON)
    fuente: Mapped[str] = mapped_column(String(200))

    dudas: Mapped[list["Duda"]] = relationship(back_populates="ficha", cascade="all, delete-orphan")


class Duda(Base):
    """Duda que un estudiante publica en una ficha. La ven todos; la edita o borra solo su autor."""

    __tablename__ = "dudas"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    ficha_id: Mapped[int] = mapped_column(ForeignKey("fichas.id", ondelete="CASCADE"), index=True)
    usuario_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id", ondelete="CASCADE"), index=True)
    texto: Mapped[str] = mapped_column(Text)
    creado: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=ahora)
    editado: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    ficha: Mapped[Ficha] = relationship(back_populates="dudas")
    autor: Mapped[Usuario] = relationship(back_populates="dudas")
