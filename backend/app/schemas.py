"""Esquemas de entrada y salida (contrato de la API)."""
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field


# ---- Usuarios ----
class UsuarioCrear(BaseModel):
    email: EmailStr
    nombre: str = Field(min_length=2, max_length=80)
    password: str = Field(min_length=8, max_length=72)


class UsuarioSalida(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    email: str
    nombre: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


# ---- Fichas ----
class FichaResumen(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    codigo: str
    materia: str
    materia_nombre: str
    unidad: int
    unidad_nombre: str
    sesion: str
    titulo: str
    normas: list[str]


class FichaDetalle(FichaResumen):
    silabo: str
    ideas_clave: list[str]
    formulas: list[str]
    preguntas: list[str]
    fuente: str
    total_dudas: int = 0


class Materia(BaseModel):
    materia: str
    materia_nombre: str
    total_fichas: int


# ---- Dudas ----
class DudaEntrada(BaseModel):
    texto: str = Field(min_length=5, max_length=500)


class DudaSalida(BaseModel):
    id: int
    ficha_id: int
    texto: str
    autor: str
    es_mia: bool
    creado: datetime
    editado: datetime | None = None


# ---- Asistente ----
class PreguntaAsistente(BaseModel):
    pregunta: str = Field(min_length=3, max_length=500)
    materia: str | None = None
    ficha_id: int | None = None


class FuenteRespuesta(BaseModel):
    id: int
    codigo: str
    titulo: str


class RespuestaAsistente(BaseModel):
    respuesta: str
    modo: str  # "gemini" o "reglas"
    fuentes: list[FuenteRespuesta]
