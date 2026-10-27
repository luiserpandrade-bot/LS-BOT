"""Pruebas del contrato de la API de LS-bot."""
import httpx

from app import asistente
from app.config import obtener_configuracion

from .conftest import registrar_y_entrar


# ---------------- Salud y autenticación ----------------
def test_salud(cliente):
    assert cliente.get("/health").json() == {"status": "ok", "db": "ok"}


def test_registro_login_y_perfil(cliente):
    cab = registrar_y_entrar(cliente)
    r = cliente.get("/usuarios/me", headers=cab)
    assert r.status_code == 200
    assert r.json()["email"] == "ana@ups.edu.ec"
    assert "hash_clave" not in r.json()


def test_registro_repetido_da_400(cliente):
    registrar_y_entrar(cliente)
    r = cliente.post("/usuarios/", json={"email": "ANA@ups.edu.ec", "nombre": "Ana", "password": "clave12345"})
    assert r.status_code == 400
    assert "ya está registrado" in r.json()["detail"]


def test_contrasena_corta_da_422_en_espanol(cliente):
    r = cliente.post("/usuarios/", json={"email": "b@ups.edu.ec", "nombre": "Beto", "password": "abc"})
    assert r.status_code == 422
    assert r.json()["detail"].startswith("Datos inválidos — password")


def test_login_incorrecto_da_401(cliente):
    registrar_y_entrar(cliente)
    r = cliente.post("/usuarios/token", data={"username": "ana@ups.edu.ec", "password": "otra-clave"})
    assert r.status_code == 401
    assert r.json()["detail"] == "Email o contraseña incorrectos"


def test_sin_token_o_token_invalido_da_401(cliente):
    assert cliente.get("/fichas/").status_code == 401
    r = cliente.get("/fichas/", headers={"Authorization": "Bearer token-invalido"})
    assert r.status_code == 401
    assert r.json()["detail"] == "No se pudo validar las credenciales"


# ---------------- Fichas ----------------
def test_fichas_sembradas_y_filtro_por_materia(cliente):
    cab = registrar_y_entrar(cliente)
    r = cliente.get("/fichas/", headers=cab)
    assert r.status_code == 200
    assert int(r.headers["x-total-count"]) == len(r.json()) == 64
    materias = {m["materia"]: m["total_fichas"] for m in cliente.get("/fichas/materias", headers=cab).json()}
    assert materias == {"diseno_electronico": 14, "sistemas_digitales_1": 25, "sistemas_digitales_2": 25}
    r = cliente.get("/fichas/", params={"materia": "diseno_electronico"}, headers=cab)
    assert {f["materia"] for f in r.json()} == {"diseno_electronico"}


def test_busqueda_y_detalle(cliente):
    cab = registrar_y_entrar(cliente)
    r = cliente.get("/fichas/", params={"q": "PWM"}, headers=cab)
    assert any(f["codigo"] == "SD1-S14" for f in r.json())
    ficha = cliente.get("/fichas/", params={"q": "IPC-2221B"}, headers=cab).json()[0]
    d = cliente.get(f"/fichas/{ficha['id']}", headers=cab).json()
    assert d["codigo"] == "DE-T05" and "IPC-2221B" in d["normas"]
    assert d["ideas_clave"] and d["preguntas"] and d["total_dudas"] == 0
    assert cliente.get("/fichas/9999", headers=cab).status_code == 404


# ---------------- Dudas (colaborativo) ----------------
def test_dudas_visibles_para_todos_y_solo_el_autor_modifica(cliente):
    ana = registrar_y_entrar(cliente)
    luis = registrar_y_entrar(cliente, email="luis@ups.edu.ec", nombre="Luis")
    r = cliente.post("/fichas/1/dudas", json={"texto": "¿Por qué FR-4 de 1.6 mm?"}, headers=ana)
    assert r.status_code == 201 and r.json()["es_mia"] is True
    duda_id = r.json()["id"]

    vista_luis = cliente.get("/fichas/1/dudas", headers=luis).json()
    assert len(vista_luis) == 1 and vista_luis[0]["autor"] == "Ana" and vista_luis[0]["es_mia"] is False

    assert cliente.patch(f"/dudas/{duda_id}", json={"texto": "Texto ajeno"}, headers=luis).status_code == 403
    assert cliente.delete(f"/dudas/{duda_id}", headers=luis).status_code == 403

    r = cliente.patch(f"/dudas/{duda_id}", json={"texto": "¿Por qué FR-4 y no Rogers?"}, headers=ana)
    assert r.status_code == 200 and r.json()["editado"] is not None
    assert cliente.get("/fichas/1", headers=ana).json()["total_dudas"] == 1
    assert cliente.delete(f"/dudas/{duda_id}", headers=ana).status_code == 204
    assert cliente.get("/fichas/1/dudas", headers=luis).json() == []
    assert cliente.delete(f"/dudas/{duda_id}", headers=ana).status_code == 404


def test_duda_corta_da_422(cliente):
    cab = registrar_y_entrar(cliente)
    r = cliente.post("/fichas/1/dudas", json={"texto": "hey"}, headers=cab)
    assert r.status_code == 422 and r.json()["detail"].startswith("Datos inválidos — texto")


# ---------------- Asistente ----------------
def test_asistente_modo_reglas_cita_la_ficha(cliente):
    cab = registrar_y_entrar(cliente)
    r = cliente.post("/asistente/", json={"pregunta": "¿Cómo calculo el periodo del PWM con Timer2?"}, headers=cab)
    assert r.status_code == 200
    datos = r.json()
    assert datos["modo"] == "reglas"
    assert datos["fuentes"][0]["codigo"] == "SD1-S14"
    assert "SD1-S14" in datos["respuesta"]


def test_asistente_requiere_sesion(cliente):
    assert cliente.post("/asistente/", json={"pregunta": "¿Qué es VHDL?"}).status_code == 401


def test_asistente_con_gemini_falso(cliente, monkeypatch):
    cab = registrar_y_entrar(cliente)
    cfg = obtener_configuracion()
    monkeypatch.setattr(cfg, "gemini_api_key", "clave-falsa")
    enviado = {}

    def post_falso(url, json, headers, timeout):
        enviado.update(url=url, json=json, headers=headers)
        return httpx.Response(200, json={"candidates": [{"content": {"parts": [{"text": "Usa IPC-2221B [DE-T05]."}]}}]})

    monkeypatch.setattr(asistente.httpx, "post", post_falso)
    r = cliente.post("/asistente/", json={"pregunta": "¿Qué ancho de pista para 3 A según IPC-2221B?"}, headers=cab)
    assert r.status_code == 200 and r.json()["modo"] == "gemini"
    assert r.json()["respuesta"] == "Usa IPC-2221B [DE-T05]."
    # La clave va en la cabecera, no en la URL; al modelo no viaja el correo de la persona.
    assert "key=" not in enviado["url"] and enviado["headers"]["x-goog-api-key"] == "clave-falsa"
    assert "ana@ups.edu.ec" not in str(enviado["json"])
    assert "DE-T05" in str(enviado["json"])


def test_asistente_cuota_agotada_da_429(cliente, monkeypatch):
    cab = registrar_y_entrar(cliente)
    monkeypatch.setattr(obtener_configuracion(), "gemini_api_key", "clave-falsa")
    monkeypatch.setattr(asistente.httpx, "post", lambda *a, **k: httpx.Response(429, json={}))
    r = cliente.post("/asistente/", json={"pregunta": "¿Qué es un RTOS?"}, headers=cab)
    assert r.status_code == 429 and "límite gratuito" in r.json()["detail"]


# ---------------- Errores de prueba ----------------
def test_error_500_controlado(cliente):
    r = cliente.get("/pruebas/error/500")
    assert r.status_code == 500
    assert r.json()["detail"].startswith("Error interno del servidor")
