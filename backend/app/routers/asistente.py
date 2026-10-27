"""Endpoint del asistente LS-bot (protegido con JWT)."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import asistente
from ..db import obtener_sesion
from ..models import Usuario
from ..schemas import FuenteRespuesta, PreguntaAsistente, RespuestaAsistente
from ..security import usuario_actual

router = APIRouter(prefix="/asistente", tags=["asistente"])


@router.post("/", response_model=RespuestaAsistente)
def preguntar(datos: PreguntaAsistente, sesion: Session = Depends(obtener_sesion), _: Usuario = Depends(usuario_actual)):
    try:
        texto, modo, fichas = asistente.responder(sesion, datos.pregunta.strip(), datos.materia, datos.ficha_id)
    except asistente.ErrorAsistente as e:
        raise HTTPException(e.codigo, e.mensaje)
    return RespuestaAsistente(
        respuesta=texto, modo=modo, fuentes=[FuenteRespuesta(id=f.id, codigo=f.codigo, titulo=f.titulo) for f in fichas]
    )
