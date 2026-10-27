# AGENTS.md — reglas del proyecto LS-bot

Archivo de contexto para agentes de código (Claude Code, Codex, Antigravity). Se mantiene corto y concreto.

## Qué es el proyecto

LS-bot es una app Flutter (Android) para el aprendizaje de Diseño Electrónico, Sistemas Digitales I y Sistemas Digitales II (Universidad Politécnica Salesiana). La persona inicia sesión, consulta fichas de estudio por materia, publica dudas en cada ficha (visibles para todos los usuarios), guarda fichas favoritas y conversa con un asistente de IA (LS-bot) que responde usando solo el contenido de las fichas.

## Arquitectura

- App (raíz del repositorio): estado con GetX; `dio` contra el backend; token en `flutter_secure_storage`; Hive para favoritos e historial del chat.
- Backend (`backend/`): FastAPI + PostgreSQL + JWT, con Docker Compose.
  - `/usuarios`: registro, token y perfil.
  - `/fichas`: lista y detalle (solo lectura; datos sembrados en la base).
  - `/fichas/{id}/dudas`: crear, listar, editar y borrar; cada usuario edita y borra solo las suyas.
  - `/asistente`: busca las fichas relacionadas con la pregunta y llama a Gemini; sin clave, responde en modo reglas.
- `GEMINI_API_KEY` y `SECRET_KEY` viven solo en variables de entorno del backend (`backend/.env`, no versionado). `backend/.env.example` documenta las variables sin valores reales.
- La app recibe la dirección del backend con `--dart-define=API_BASE_URL` (por defecto `http://10.0.2.2:8000`, la del emulador).

## Dónde está cada cosa

- `lib/controllers/` — controladores GetX (estado compartido).
- `lib/services/` y `lib/repositories/` — acceso al backend y a Hive.
- `lib/screens/` y `lib/widgets/` — pantallas y piezas de interfaz.
- `lib/models/`, `lib/utils/` — modelos y utilidades.
- `test/` — pruebas de widgets y de servicios.
- `backend/app/` — código del backend; `backend/tests/` — sus pruebas.

## Cómo verificar (siempre, antes de dar un cambio por terminado)

```bash
flutter analyze
flutter test

Si cambias algo en `backend/`:

```powershell
cd backend
docker compose run --rm api python -m pytest -q
```
```

Los dos deben terminar sin errores. Si fallan, corrige el código; no desactives el análisis ni borres pruebas para que pasen.

## Convenciones

- Capas: pantalla → controlador GetX → servicio o repositorio → API o Hive. Ninguna pantalla llama directamente a `dio` ni a Hive.
- Todo texto visible va en español neutro. Los nombres de clases, funciones y variables van en español.
- Cada pantalla con datos cubre cargando, vacío y error, con mensajes distintos para 400, 401, 422, 5xx y sin conexión.
- Cambios pequeños y enfocados, con una prueba por cada comportamiento nuevo.
- Antes de crear un widget nuevo, revisa si ya existe uno parecido en `lib/widgets/`.
- Las fichas son de redacción propia: citan las normas (nombre y sección) sin copiar su texto.

## Prohibido

- Escribir claves, tokens o contraseñas en el código, en los registros o en este archivo. No leer ni modificar `.env` ni `backend/.env`.
- Copiar texto de normas con derechos de autor (IPC, IEEE, IEC…).
- Agregar dependencias nuevas sin avisar antes y explicar por qué hacen falta.
- Ejecutar `git push` o crear etiquetas: eso lo hace la persona después de revisar el cambio.