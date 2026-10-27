"""Contraseñas con bcrypt y tokens JWT."""
from datetime import datetime, timedelta, timezone

import bcrypt
import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from .config import obtener_configuracion
from .db import obtener_sesion
from .models import Usuario

esquema_oauth2 = OAuth2PasswordBearer(tokenUrl="/usuarios/token")

CREDENCIALES_INVALIDAS = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="No se pudo validar las credenciales",
    headers={"WWW-Authenticate": "Bearer"},
)


def cifrar_clave(clave: str) -> str:
    return bcrypt.hashpw(clave.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verificar_clave(clave: str, hash_guardado: str) -> bool:
    try:
        return bcrypt.checkpw(clave.encode("utf-8"), hash_guardado.encode("utf-8"))
    except ValueError:
        return False


def crear_token(usuario_id: int) -> str:
    cfg = obtener_configuracion()
    vence = datetime.now(timezone.utc) + timedelta(minutes=cfg.minutos_token)
    return jwt.encode({"sub": str(usuario_id), "exp": vence}, cfg.secret_key, algorithm=cfg.algoritmo_jwt)


def usuario_actual(token: str = Depends(esquema_oauth2), sesion: Session = Depends(obtener_sesion)) -> Usuario:
    cfg = obtener_configuracion()
    try:
        datos = jwt.decode(token, cfg.secret_key, algorithms=[cfg.algoritmo_jwt])
        usuario_id = int(datos["sub"])
    except (jwt.PyJWTError, KeyError, ValueError):
        raise CREDENCIALES_INVALIDAS
    usuario = sesion.get(Usuario, usuario_id)
    if usuario is None:
        raise CREDENCIALES_INVALIDAS
    return usuario
