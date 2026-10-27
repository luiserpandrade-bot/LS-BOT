"""Siembra de las fichas de estudio desde app/data/fichas.json.

Las fichas son de redacción propia (guías de estudio por sesión del docente).
Citan las normas por su nombre, sin copiar su texto.
"""
import json
import logging
from pathlib import Path

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from .models import Ficha

RUTA_FICHAS = Path(__file__).parent / "data" / "fichas.json"
log = logging.getLogger("lsbot")


def sembrar_fichas(sesion: Session) -> int:
    """Carga las fichas si la tabla está vacía. Devuelve cuántas se insertaron."""
    if sesion.scalar(select(func.count(Ficha.id))):
        return 0
    datos = json.loads(RUTA_FICHAS.read_text(encoding="utf-8"))
    sesion.add_all(Ficha(**f) for f in datos)
    sesion.commit()
    log.info("Fichas sembradas: %d", len(datos))
    return len(datos)
