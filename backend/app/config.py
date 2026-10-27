"""Configuración del backend de LS-bot.

Todo sale de variables de entorno (archivo backend/.env, que NO se versiona).
backend/.env.example documenta cada variable sin valores reales.
"""
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Configuracion(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Base de datos: PostgreSQL en Docker; las pruebas usan SQLite en memoria.
    database_url: str = "sqlite:///./lsbot.db"

    # Firma de los JWT. Debe ser larga y aleatoria; nunca se escribe en el código.
    secret_key: str = "solo-para-desarrollo-cambiar-en-backend-env"
    algoritmo_jwt: str = "HS256"
    minutos_token: int = 60

    # Asistente: sin clave, LS-bot responde en modo reglas (sin internet).
    gemini_api_key: str = ""
    gemini_model: str = "gemini-3.5-flash-lite"
    gemini_base_url: str = "https://generativelanguage.googleapis.com"
    segundos_espera_ia: float = 20.0

    # Solo para la práctica: expone /pruebas/error/{codigo} para forzar 400/401/422/500.
    permitir_errores_de_prueba: bool = False


@lru_cache
def obtener_configuracion() -> Configuracion:
    return Configuracion()
