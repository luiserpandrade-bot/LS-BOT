"""Backend de LS-bot: FastAPI + PostgreSQL + JWT.

Arranque: crea las tablas, siembra las fichas y registra cada petición
(método, ruta, código y tiempo) sin cabeceras ni cuerpos: nunca se registra un token.
"""
import logging
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy import text

from .config import obtener_configuracion
from .db import Base, SesionLocal, motor
from .routers import asistente, fichas, usuarios
from .seed import sembrar_fichas

logging.basicConfig(level=logging.INFO, format="[%(asctime)s] %(levelname)s %(message)s", datefmt="%m/%d/%y %H:%M:%S")
log = logging.getLogger("lsbot")


@asynccontextmanager
async def ciclo_de_vida(_: FastAPI):
    Base.metadata.create_all(bind=motor)
    with SesionLocal() as sesion:
        sembrar_fichas(sesion)
    yield


app = FastAPI(title="LS-bot API", version="1.0.0", lifespan=ciclo_de_vida)
app.include_router(usuarios.router)
app.include_router(fichas.router)
app.include_router(asistente.router)


@app.middleware("http")
async def registrar_peticion(request: Request, call_next):
    inicio = time.perf_counter()
    respuesta = await call_next(request)
    ms = (time.perf_counter() - inicio) * 1000
    log.info("%s %s -> %s (%.1f ms)", request.method, request.url.path, respuesta.status_code, ms)
    return respuesta


@app.exception_handler(RequestValidationError)
async def error_de_validacion(_: Request, exc: RequestValidationError):
    """422 con un mensaje legible en español (además del detalle por campo)."""
    errores = []
    for e in exc.errors():
        campo = ".".join(str(p) for p in e.get("loc", []) if p not in ("body", "query", "path"))
        errores.append({"campo": campo, "mensaje": e.get("msg", "")})
    primero = errores[0] if errores else {"campo": "", "mensaje": "datos incorrectos"}
    return JSONResponse(
        status_code=422,
        content={"detail": f"Datos inválidos — {primero['campo']}: {primero['mensaje']}", "errores": errores},
    )


@app.exception_handler(Exception)
async def error_inesperado(_: Request, exc: Exception):
    log.error("Error no controlado: %s", type(exc).__name__)
    return JSONResponse(status_code=500, content={"detail": "Error interno del servidor. Inténtalo más tarde."})


@app.get("/health", tags=["salud"])
def salud():
    try:
        with motor.connect() as c:
            c.execute(text("SELECT 1"))
        db = "ok"
    except Exception:
        db = "error"
    return {"status": "ok", "db": db}


@app.get("/pruebas/error/{codigo}", tags=["pruebas"], include_in_schema=False)
def forzar_error(codigo: int):
    """Solo si PERMITIR_ERRORES_DE_PRUEBA=true: provoca 400, 401, 422 o 500 para probar la app."""
    if not obtener_configuracion().permitir_errores_de_prueba:
        raise HTTPException(404, "Not Found")
    if codigo == 500:
        raise RuntimeError("error provocado para la práctica")
    if codigo in (400, 401, 403, 404, 422, 429, 503):
        raise HTTPException(codigo, f"Error {codigo} provocado para la práctica")
    raise HTTPException(400, "Código no soportado")
