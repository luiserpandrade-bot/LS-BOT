"""Las pruebas usan SQLite en memoria: no necesitan Docker, PostgreSQL ni internet."""
import os

os.environ["DATABASE_URL"] = "sqlite:///:memory:"
os.environ["SECRET_KEY"] = "clave-solo-para-pruebas-automaticas-0123456789"
os.environ["GEMINI_API_KEY"] = ""
os.environ["PERMITIR_ERRORES_DE_PRUEBA"] = "true"

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

from app.db import Base, SesionLocal, motor  # noqa: E402
from app.main import app  # noqa: E402
from app.seed import sembrar_fichas  # noqa: E402


@pytest.fixture()
def cliente():
    Base.metadata.drop_all(bind=motor)
    Base.metadata.create_all(bind=motor)
    with SesionLocal() as s:
        sembrar_fichas(s)
    with TestClient(app, raise_server_exceptions=False) as c:
        yield c


def registrar_y_entrar(cliente, email="ana@ups.edu.ec", nombre="Ana", clave="clave12345") -> dict:
    r = cliente.post("/usuarios/", json={"email": email, "nombre": nombre, "password": clave})
    assert r.status_code == 201, r.text
    r = cliente.post("/usuarios/token", data={"username": email, "password": clave})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}
