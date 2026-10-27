"""Conexión a la base de datos (SQLAlchemy 2)."""
from collections.abc import Iterator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker
from sqlalchemy.pool import StaticPool

from .config import obtener_configuracion


class Base(DeclarativeBase):
    pass


def crear_motor(url: str):
    if url.startswith("sqlite"):
        # SQLite en memoria (pruebas) necesita una sola conexión compartida.
        extra = {"poolclass": StaticPool} if ":memory:" in url else {}
        return create_engine(url, connect_args={"check_same_thread": False}, **extra)
    return create_engine(url, pool_pre_ping=True)


motor = crear_motor(obtener_configuracion().database_url)
SesionLocal = sessionmaker(bind=motor, autoflush=False, expire_on_commit=False)


def obtener_sesion() -> Iterator[Session]:
    sesion = SesionLocal()
    try:
        yield sesion
    finally:
        sesion.close()
