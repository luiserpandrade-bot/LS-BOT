"""Registro, inicio de sesión (OAuth2 con formulario) y perfil."""
import logging

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..db import obtener_sesion
from ..models import Usuario
from ..schemas import Token, UsuarioCrear, UsuarioSalida
from ..security import crear_token, cifrar_clave, usuario_actual, verificar_clave

router = APIRouter(prefix="/usuarios", tags=["usuarios"])
log = logging.getLogger("lsbot")


@router.post("/", response_model=UsuarioSalida, status_code=status.HTTP_201_CREATED)
def registrar(datos: UsuarioCrear, sesion: Session = Depends(obtener_sesion)):
    email = datos.email.lower()
    if sesion.scalar(select(Usuario).where(Usuario.email == email)):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, f"El email {email} ya está registrado")
    usuario = Usuario(email=email, nombre=datos.nombre.strip(), hash_clave=cifrar_clave(datos.password))
    sesion.add(usuario)
    sesion.commit()
    log.info("Usuario registrado: usuario_id=%s", usuario.id)
    return usuario


@router.post("/token", response_model=Token)
def iniciar_sesion(form: OAuth2PasswordRequestForm = Depends(), sesion: Session = Depends(obtener_sesion)):
    usuario = sesion.scalar(select(Usuario).where(Usuario.email == form.username.lower()))
    if usuario is None or not verificar_clave(form.password, usuario.hash_clave):
        log.warning("Inicio de sesión fallido")
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED, "Email o contraseña incorrectos", headers={"WWW-Authenticate": "Bearer"}
        )
    return Token(access_token=crear_token(usuario.id))


@router.get("/me", response_model=UsuarioSalida)
def perfil(usuario: Usuario = Depends(usuario_actual)):
    return usuario
