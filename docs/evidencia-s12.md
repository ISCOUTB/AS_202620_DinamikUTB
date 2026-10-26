# Evidencia S12 · Estrategia de datos y eventos

- Repositorio: https://github.com/ISCOUTB/AS_202620_DinamikUTB
- Commit evaluado: el vigente al cierre de la actividad (`git log -1 --format="%H %cI"`).
- Último commit con código de S12 (historial transaccional): `bd747bc` · fecha: 2026-10-25T21:24:51-05:00

## Dónde está cada entregable

| Criterio de la ficha | Dónde está |
|---|---|
| Tabla operación → garantía de consistencia | [arc42 §8.8](arc42/08-cross-cutting-concepts.md) (12 operaciones reales de la API y del arranque) |
| Dos operaciones verificadas contra el código | Más abajo |
| Diseño de caché: qué, dónde, cuánto | [arc42 §8.9](arc42/08-cross-cutting-concepts.md): decisión de no tener caché de servidor e inventario de las copias existentes |
| Política de invalidación tras escritura | [arc42 §8.9](arc42/08-cross-cutting-concepts.md): servidor sin copia; cliente invalidado con la respuesta del `PUT` (propia) o recarga manual (ajena); operación que se rompe y plan |
| Garantías del flujo por eventos | [arc42 §8.10](arc42/08-cross-cutting-concepts.md): no hay flujo por eventos ni broker |
| ADR de la decisión más costosa de revertir | [ADR-0011](adr/0011-historial-de-cambios-transaccional.md) |
| Argumento de por qué es la más costosa | ADR-0011, sección 2 (comparación con 4 decisiones alternativas) y sección 6 (costo de reversión) |
| Almacenes y brokers en el C4 nivel 2 | [docs/c4/contenedores.puml](c4/contenedores.puml): bases (SQLite local, Postgres desplegado en Render y el Postgres del laboratorio con su volumen `pgdata`), almacén de sesión del cliente y registro operativo; sin broker, declarado en el pie del diagrama |
| arc42 sección 8 con consistencia y caché | [arc42 §8.8–8.11](arc42/08-cross-cutting-concepts.md) |
| Segundo ambiente de despliegue (contexto de los almacenes) | [ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md) |

## Dos operaciones contrastadas con el código

**Fuerte: `PUT /requisitos/{id}/estado` con su historial (filas 1 y 2).**

```bash
git grep -nE "(db\.add\(RequisitoHistorial|RequisitoHistorial\(|db\.commit\(\))" -- backend/app/requisitos/service.py
```

Se esperan `RequisitoHistorial(`, `db.add(` y **un único** `db.commit()` en `actualizar_estado_requisito`: el `UPDATE` y la fila de historial se confirman juntos. La prueba `test_si_falla_el_historial_el_cambio_no_queda_aplicado` fuerza una violación `NOT NULL` en el historial y comprueba que el estado sigue como estaba.

**Eventual / mejor esfuerzo: log de auditoría y pantalla de inicio (filas 3 y 6).**

```bash
git grep -nE "(auditoria_cambio_estado|Future\.wait)" -- backend/app frontend/lib
```

El log se emite después del `commit` (puede perderse, por eso no es el registro de auditoría), y `dashboard_screen.dart` lanza tres consultas con `Future.wait` sin instantánea común. El desfase se acepta y se reconcilia al actualizar.

## Qué existe en el código que parece caché

```bash
git grep -nIE '(redis|memcach|cache|ttl|expire)' HEAD -- . ':!docs'
```

Las coincidencias reales son: `@lru_cache` de `get_settings` (configuración, no datos), `Cache-Control: no-store` en `main.py` (el opuesto a una caché), `cache_clear()` en pruebas y la expiración (`exp`) del JWT. El resto son falsos positivos: `expires_in` (respuesta del login), `pumpAndSettle` (pruebas de Flutter, contiene `ttl`) y entradas de `.gitignore` y archivos generados de plataformas. No hay caché de datos de dominio; ver [arc42 §8.9](arc42/08-cross-cutting-concepts.md).

## Credenciales (contrato §9)

```bash
git grep -nIE '(AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY|ghp_[A-Za-z0-9]{36}|xox[baprs]-|sk-[A-Za-z0-9]{20,}|(password|passwd|secret|token|api_?key)\s*[:=]\s*.{6,})' HEAD
```

Las coincidencias son firmas de funciones y nombres de variable, ninguna con un valor literal de secreto: `metrics_token` y `password: str` en `config.py`, `security.py` y `schemas.py`; `os.getenv("SEED_DEMO_PASSWORD", "")` en `seed.py`; `id-token: write` (permiso de Actions) en `deploy-pages.yml`; contraseñas de prueba en `backend/tests/test_auth.py`, que son datos de fixture. No hay claves AWS, claves privadas ni tokens de GitHub, Slack u OpenAI.

- Ningún `.env` versionado (`git ls-files` sin coincidencias; solo `.env.example` y `deploy/.env.example`, con valores vacíos).
- `git log -S` devuelve commits:
4226597 Create apply_s12.py
- Los secretos del laboratorio (`SECRET_KEY`, `POSTGRES_PASSWORD`, `SEED_DEMO_PASSWORD`) se definen en Dokploy; `deploy/compose.lab.yaml` solo los referencia con `${VARIABLE}`.

## Despliegue en el laboratorio

Registrado en [ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md). URL: https://dinamikutb.iscoutb.dev

<!-- verif:start -->

| Petición | Resultado |
| :--- | :--- |
| `GET https://dinamikutb-api.onrender.com/health` | HTTP 200 (`{"status":"ok"}`) |
| `GET https://dinamikutb-api.onrender.com/metrics` | HTTP 200 |
| `GET /requisitos/T000123456` | HTTP 401 (credenciales inválidas o sesión expirada) |

<!-- verif:end -->

## Limitaciones declaradas

- El historial solo cubre cambios de estado de `requisitos/` y **no tiene endpoint de consulta** (RF-08 y Q-08 parciales).
- La durabilidad del historial es la de la base; la gratuita de Render expira el 27/10/2026 (F7). En el laboratorio persiste en el volumen `pgdata`, **sin respaldo declarado**.
- Hay dos bases desplegadas (Render y laboratorio) **sin replicación**; el ADR-0012 fija el laboratorio como principal y Render como respaldo hasta su vencimiento.
- Sin control de versión en las escrituras: última escritura gana (F6). La prueba existente es secuencial, no demuestra una carrera.
- Las filas 6, 3 y 10 de la tabla de consistencia están descritas, sin prueba automatizada.
- Referencias entre módulos sin clave foránea: pueden existir filas huérfanas (fila 11).
- No se ejecutó prueba de carga ni medición de latencia que respalde la decisión de no tener caché: se apoya en el volumen de `docs/costos.md` y se reabre ante una medición real.
- El despliegue del laboratorio no está verificado desde fuera de la universidad (ver sección anterior).

## Archivos de este cambio

`backend/app/requisitos/models.py`, `backend/app/requisitos/service.py`, `backend/tests/test_historial.py`, `docs/adr/0011-historial-de-cambios-transaccional.md`, `docs/adr/0012-despliegue-en-servidor-del-laboratorio.md`, `deploy/compose.lab.yaml`, `deploy/.env.example`, `backend/Dockerfile`, `docs/c4/contenedores.puml`, `docs/arc42/07*`, `08*`, `09*`, `10*`, `11*`, `docs/aspectos.md`, `docs/ia.md`, `README.md`.
