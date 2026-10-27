"""Fichas de estudio (solo lectura) y sus dudas (CRUD colaborativo)."""
import logging
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from ..db import obtener_sesion
from ..models import Duda, Ficha, Usuario
from ..schemas import DudaEntrada, DudaSalida, FichaDetalle, FichaResumen, Materia
from ..security import usuario_actual

router = APIRouter(tags=["fichas"])
log = logging.getLogger("lsbot")


def _ficha_o_404(sesion: Session, ficha_id: int) -> Ficha:
    ficha = sesion.get(Ficha, ficha_id)
    if ficha is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "La ficha no existe")
    return ficha


def _duda_salida(duda: Duda, usuario: Usuario) -> DudaSalida:
    return DudaSalida(
        id=duda.id, ficha_id=duda.ficha_id, texto=duda.texto, autor=duda.autor.nombre,
        es_mia=duda.usuario_id == usuario.id, creado=duda.creado, editado=duda.editado,
    )


@router.get("/fichas/materias", response_model=list[Materia])
def materias(sesion: Session = Depends(obtener_sesion), _: Usuario = Depends(usuario_actual)):
    filas = sesion.execute(
        select(Ficha.materia, Ficha.materia_nombre, func.count(Ficha.id))
        .group_by(Ficha.materia, Ficha.materia_nombre)
        .order_by(Ficha.materia)
    ).all()
    return [Materia(materia=m, materia_nombre=n, total_fichas=t) for m, n, t in filas]


@router.get("/fichas/", response_model=list[FichaResumen])
def listar_fichas(
    response: Response,
    materia: str | None = None,
    q: str | None = Query(default=None, max_length=100),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=100, ge=1, le=200),
    sesion: Session = Depends(obtener_sesion),
    _: Usuario = Depends(usuario_actual),
):
    consulta = select(Ficha)
    if materia:
        consulta = consulta.where(Ficha.materia == materia)
    if q:
        patron = f"%{q.strip()}%"
        consulta = consulta.where(or_(Ficha.titulo.ilike(patron), Ficha.unidad_nombre.ilike(patron)))
    total = sesion.scalar(select(func.count()).select_from(consulta.subquery()))
    response.headers["X-Total-Count"] = str(total)
    return sesion.scalars(consulta.order_by(Ficha.id).offset(skip).limit(limit)).all()


@router.get("/fichas/{ficha_id}", response_model=FichaDetalle)
def detalle_ficha(ficha_id: int, sesion: Session = Depends(obtener_sesion), _: Usuario = Depends(usuario_actual)):
    ficha = _ficha_o_404(sesion, ficha_id)
    detalle = FichaDetalle.model_validate(ficha)
    detalle.total_dudas = sesion.scalar(select(func.count(Duda.id)).where(Duda.ficha_id == ficha_id)) or 0
    return detalle


@router.get("/fichas/{ficha_id}/dudas", response_model=list[DudaSalida])
def listar_dudas(ficha_id: int, sesion: Session = Depends(obtener_sesion), usuario: Usuario = Depends(usuario_actual)):
    _ficha_o_404(sesion, ficha_id)
    dudas = sesion.scalars(select(Duda).where(Duda.ficha_id == ficha_id).order_by(Duda.creado.desc(), Duda.id.desc()))
    return [_duda_salida(d, usuario) for d in dudas]


@router.post("/fichas/{ficha_id}/dudas", response_model=DudaSalida, status_code=status.HTTP_201_CREATED)
def crear_duda(
    ficha_id: int, datos: DudaEntrada, sesion: Session = Depends(obtener_sesion), usuario: Usuario = Depends(usuario_actual)
):
    _ficha_o_404(sesion, ficha_id)
    duda = Duda(ficha_id=ficha_id, usuario_id=usuario.id, texto=datos.texto.strip())
    sesion.add(duda)
    sesion.commit()
    sesion.refresh(duda)
    log.info("Duda creada: duda_id=%s ficha_id=%s usuario_id=%s", duda.id, ficha_id, usuario.id)
    return _duda_salida(duda, usuario)


def _duda_propia(sesion: Session, duda_id: int, usuario: Usuario) -> Duda:
    duda = sesion.get(Duda, duda_id)
    if duda is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "La duda no existe")
    if duda.usuario_id != usuario.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Solo el autor puede modificar o borrar esta duda")
    return duda


@router.patch("/dudas/{duda_id}", response_model=DudaSalida)
def editar_duda(
    duda_id: int, datos: DudaEntrada, sesion: Session = Depends(obtener_sesion), usuario: Usuario = Depends(usuario_actual)
):
    duda = _duda_propia(sesion, duda_id, usuario)
    duda.texto = datos.texto.strip()
    duda.editado = datetime.now(timezone.utc)
    sesion.commit()
    log.info("Duda editada: duda_id=%s usuario_id=%s", duda_id, usuario.id)
    return _duda_salida(duda, usuario)


@router.delete("/dudas/{duda_id}", status_code=status.HTTP_204_NO_CONTENT)
def borrar_duda(duda_id: int, sesion: Session = Depends(obtener_sesion), usuario: Usuario = Depends(usuario_actual)):
    duda = _duda_propia(sesion, duda_id, usuario)
    sesion.delete(duda)
    sesion.commit()
    log.info("Duda borrada: duda_id=%s usuario_id=%s", duda_id, usuario.id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
