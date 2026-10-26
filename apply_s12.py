import re
import subprocess
from pathlib import Path


def read(p):
    with open(p, "r", encoding="utf-8", newline="") as f:
        return f.read()


def write(p, s):
    with open(p, "w", encoding="utf-8", newline="") as f:
        f.write(s)


def git(*a):
    r = subprocess.run(["git", *a], capture_output=True, text=True, encoding="utf-8")
    return r.stdout.strip()


def sub(path, old, new):
    s = read(path)
    if new in s:
        print("ya aplicado:", path)
        return
    assert old in s, f"No encontré en {path}: {old[:70]}"
    write(path, s.replace(old, new, 1))
    print("ok:", path)


def insert_after(path, startswith, new_lines, marker):
    s = read(path)
    if marker in s:
        print("ya aplicado:", path)
        return
    nl = "\r\n" if "\r\n" in s else "\n"
    lines = s.split(nl)
    for i, l in enumerate(lines):
        if l.startswith(startswith):
            lines[i + 1:i + 1] = new_lines
            write(path, nl.join(lines))
            print("ok:", path)
            return
    raise AssertionError(f"No encontré línea que empiece con {startswith!r} en {path}")


# ---------- datos de git ----------
code = git("log", "-1", "--format=%h|%cI", "--", "backend/app/requisitos/service.py",
           "backend/tests/test_historial.py")
HASH_CODE, FECHA_CODE = (code.split("|") + ["", ""])[:2] if code else ("", "")
lab = git("log", "-1", "--format=%h", "--", "deploy/compose.lab.yaml", "backend/Dockerfile")

h_code = f"`{HASH_CODE}`" if HASH_CODE else "aún sin commit; se obtiene con `git log -1 --format=%h -- backend/app/requisitos/service.py backend/tests/test_historial.py`"
h_lab = f"`{lab}`" if lab else "aún sin commit; se obtiene con `git log -1 --format=%h -- deploy/compose.lab.yaml`"
f_code = FECHA_CODE or "ver `git log -1 --format=%cI`"

env_tracked = [f for f in git("ls-files").splitlines() if re.search(r"(^|/)\.env$", f)]
pk_hist = git("log", "--oneline", "-SBEGIN PRIVATE KEY")
ENV_LINE = "Ningún `.env` versionado (`git ls-files` sin coincidencias; solo `.env.example` y `deploy/.env.example`, con valores vacíos)." \
    if not env_tracked else f"ATENCIÓN: `.env` versionado en {env_tracked}; hay que rotar sus valores."
PK_LINE = "`git log -S'BEGIN PRIVATE KEY'` sin coincidencias." if not pk_hist else f"`git log -S` devuelve commits:\n{pk_hist}"

# ---------- ADR-0012 completo ----------
ADR12 = f"""---
id: ADR-0012
title: Despliegue en el servidor del laboratorio
status: Aceptado
date: 2026-10-25
deciders: Equipo de arquitectura DinamikUTB
---

# ADR-0012: Despliegue en el servidor del laboratorio

![Status: Aceptado](https://img.shields.io/badge/Status-Accepted-brightgreen?style=flat-square)
![Date: 2026--10--25](https://img.shields.io/badge/Date-2026--10--25-blue?style=flat-square)
![Scope: Deployment](https://img.shields.io/badge/Scope-Deployment-orange?style=flat-square)

## 1. Contexto y descripción del problema

[ADR-0005](0005-plataforma-despliegue-backend.md) descartó el servidor del laboratorio (alternativa 3.1) porque su alcance desde fuera de la universidad no estaba verificado y dependía de la coordinación de laboratorios. Esa condición cambió: el equipo lo desplegó con Dokploy, descrito como código en `deploy/compose.lab.yaml`. Este ADR registra esa decisión **sin reescribir** el ADR-0005, que sigue siendo válido para el despliegue en Render.

Hay además una fecha que fuerza la decisión: la base de Render gratuita se creó el 27/09/2026 y expira el 27/10/2026 ([ADR-0007](0007-persistencia-render-postgres.md), F7).

## 2. Factores de decisión

| Factor | Descripción |
| :--- | :--- |
| **Persistencia sin expiración** | La base de Render gratuita expira a los 30 días ([ADR-0007](0007-persistencia-render-postgres.md), F7); un volumen Docker no. |
| **Sin *spin down*** | El servicio del laboratorio no se duerme por inactividad (riesgo principal de Q-05 en Render). |
| **Costo cero y sin tarjeta** | Se mantiene ([02-architecture-constraints.md](../arc42/02-architecture-constraints.md)). |
| **Infraestructura como código** | `deploy/compose.lab.yaml` versionado, desplegado en cada push. |
| **Reglas del laboratorio** | Sin `ports:`, bind mounts ni `docker.sock`; límites por servicio; total del equipo ≤ 512 MB. |

## 3. Alternativas consideradas

### 3.1 Solo Render (estado de ADR-0005 y ADR-0007)
* **Desventajas:** *spin down* de ~1 min y base que expira a los 30 días (27/10/2026).

### 3.2 Solo el servidor del laboratorio
* **Ventajas:** persistencia sin expiración, sin arranque en frío.
* **Desventajas:** depende de la disponibilidad del laboratorio y de sus políticas. La accesibilidad desde fuera de la universidad **se comprueba con `curl` desde una red externa** sobre `https://dinamikutb.iscoutb.dev/health`; el resultado vigente está en la sección 8. El dominio pasa por Cloudflare y Traefik, así que es público a nivel de proxy; lo que debe confirmarse es que la ruta de la API responda.

### 3.3 Ambos despliegues en paralelo
* **Ventajas:** respaldo mutuo; la URL del backend se elige con `API_BASE_URL`.
* **Desventajas:** dos bases independientes **sin replicación**: los datos y el historial no se comparten entre ellas. Obliga a recrear la base de Render antes del 27/10 y a mantener dos ambientes.

## 4. Decisión

**Opción A: el sistema principal corre en el laboratorio.** El backend y su Postgres del laboratorio son el ambiente de referencia. Render queda como respaldo mientras dure su base (hasta el 27/10/2026), **no se recrea** y después se retira.

El frontend de GitHub Pages cambia de backend con la variable de repositorio `API_BASE_URL` (`https://dinamikutb.iscoutb.dev`), y solo después de que `/health` responda 200 desde fuera de la universidad. Mientras eso no ocurra, Render sigue siendo la URL en uso.

Servicios (`deploy/compose.lab.yaml`): `api` (FastAPI, 0,5 CPU, 192 MB) y `db` (`postgres:16-alpine`, volumen `pgdata`, 0,5 CPU, 160 MB), detrás de Traefik. Variables obligatorias: `SECRET_KEY`, `CORS_ORIGINS`, `SEED_DEMO_PASSWORD`, `POSTGRES_*`, definidas en Dokploy, nunca en el repositorio.

## 5. Consecuencias

### Positivas
* Historial y datos persisten sin la expiración de 30 días.
* Sin arranque en frío: mejora la medida de Q-05.
* Una sola base de referencia: no hay datos divergentes entre ambientes.

### Negativas
* **Disponibilidad atada al laboratorio**, fuera del control del equipo.
* **Sin copias de seguridad.** No hay `pg_dump` programado ni respaldo del volumen `pgdata`: si se pierde, se pierde el historial ([ADR-0011](0011-historial-de-cambios-transaccional.md)). Riesgo aceptado porque hoy solo hay datos de ejemplo; antes de cargar datos reales hay que definir un respaldo.
* **Postgres con 160 MB** y `max_connections=30`: ajustado; el *pool* de la API (5+5) cabe, pero no hay margen para crecer.
* **Transición:** entre el cambio de `API_BASE_URL` y la baja de Render, la base de Render queda sin uso y sin datos nuevos.

## 6. Relación con atributos de calidad

| Atributo | Relación |
| :--- | :--- |
| **Disponibilidad** | Elimina el *spin down*; añade dependencia del laboratorio. |
| **Trazabilidad** | El historial deja de perderse por expiración de la base. |
| **Seguridad** | Los secretos viven en Dokploy; la API no publica puertos. |

## 7. Estado de la decisión

**Aceptado.** No reemplaza al ADR-0005 ni al ADR-0007: los complementa para este ambiente. Se revisa si el laboratorio deja de ser accesible desde fuera de la universidad o si se define un respaldo del volumen.

## 8. Trazabilidad

| Elemento | Referencia |
| :--- | :--- |
| **Aspectos** | [A-04](../aspectos.md#a-04--disponibilidad-del-sistema), [A-01](../aspectos.md#a-01--seguimiento-del-cumplimiento-de-requisitos) |
| **Escenario** | [Q-05](../arc42/10-quality-requirements.md#escenario-q-05--disponibilidad-del-sistema) |
| **C4** | `backend_lab`, `database_lab`, `proxy` en `docs/c4/contenedores.puml` |
| **Código** | `deploy/compose.lab.yaml`, `deploy/.env.example`, `backend/Dockerfile` |
| **URL pública** | https://dinamikutb.iscoutb.dev (health: https://dinamikutb.iscoutb.dev/health) |
| **Commits** | {h_lab} |

### Comprobación del despliegue

<!-- verif:start -->
Comprobación del 25/10/2026, 22:52 (hora local del equipo), con `curl`:

| Petición | Resultado |
| :--- | :--- |
| `GET /health` | HTTP 404 (`404 page not found`, respuesta de Traefik vía Cloudflare) |
| `GET /requisitos/T000123456` | HTTP 404 |
| `GET /docs` | HTTP 404 (esperado en producción, `docs_url=None`) |

**Estado: No verificado.** El dominio resuelve y llega al proxy, pero Traefik no tiene una ruta activa para ese host: el despliegue de la API no estaba terminado. Falta repetir la comprobación con la ruta configurada y desde una red fuera de la universidad.
<!-- verif:end -->
"""

# ---------- evidencia-s12.md completo ----------
EVID = """# Evidencia S12 · Estrategia de datos y eventos

- Repositorio: https://github.com/ISCOUTB/AS_202620_DinamikUTB
- Commit evaluado: el vigente al cierre de la actividad (`git log -1 --format="%H %cI"`).
- Último commit con código de S12 (historial transaccional): @@HASH@@ · fecha: @@FECHA@@

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
git grep -nE "(db\\.add\\(RequisitoHistorial|RequisitoHistorial\\(|db\\.commit\\(\\))" -- backend/app/requisitos/service.py
```

Se esperan `RequisitoHistorial(`, `db.add(` y **un único** `db.commit()` en `actualizar_estado_requisito`: el `UPDATE` y la fila de historial se confirman juntos. La prueba `test_si_falla_el_historial_el_cambio_no_queda_aplicado` fuerza una violación `NOT NULL` en el historial y comprueba que el estado sigue como estaba.

**Eventual / mejor esfuerzo: log de auditoría y pantalla de inicio (filas 3 y 6).**

```bash
git grep -nE "(auditoria_cambio_estado|Future\\.wait)" -- backend/app frontend/lib
```

El log se emite después del `commit` (puede perderse, por eso no es el registro de auditoría), y `dashboard_screen.dart` lanza tres consultas con `Future.wait` sin instantánea común. El desfase se acepta y se reconcilia al actualizar.

## Qué existe en el código que parece caché

```bash
git grep -nIE '(redis|memcach|cache|ttl|expire)' HEAD -- . ':!docs'
```

Las coincidencias reales son: `@lru_cache` de `get_settings` (configuración, no datos), `Cache-Control: no-store` en `main.py` (el opuesto a una caché), `cache_clear()` en pruebas y la expiración (`exp`) del JWT. El resto son falsos positivos: `expires_in` (respuesta del login), `pumpAndSettle` (pruebas de Flutter, contiene `ttl`) y entradas de `.gitignore` y archivos generados de plataformas. No hay caché de datos de dominio; ver [arc42 §8.9](arc42/08-cross-cutting-concepts.md).

## Credenciales (contrato §9)

```bash
git grep -nIE '(AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY|ghp_[A-Za-z0-9]{36}|xox[baprs]-|sk-[A-Za-z0-9]{20,}|(password|passwd|secret|token|api_?key)\\s*[:=]\\s*.{6,})' HEAD
```

Las coincidencias son firmas de funciones y nombres de variable, ninguna con un valor literal de secreto: `metrics_token` y `password: str` en `config.py`, `security.py` y `schemas.py`; `os.getenv("SEED_DEMO_PASSWORD", "")` en `seed.py`; `id-token: write` (permiso de Actions) en `deploy-pages.yml`; contraseñas de prueba en `backend/tests/test_auth.py`, que son datos de fixture. No hay claves AWS, claves privadas ni tokens de GitHub, Slack u OpenAI.

- @@ENV@@
- @@PK@@
- Los secretos del laboratorio (`SECRET_KEY`, `POSTGRES_PASSWORD`, `SEED_DEMO_PASSWORD`) se definen en Dokploy; `deploy/compose.lab.yaml` solo los referencia con `${VARIABLE}`.

## Despliegue en el laboratorio

Registrado en [ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md). URL: https://dinamikutb.iscoutb.dev

<!-- verif:start -->
Comprobación del 25/10/2026, 22:52 (hora local): `GET /health` → HTTP 404 (respuesta de Traefik vía Cloudflare). **No verificado:** el dominio llega al proxy, pero la ruta de la API aún no estaba activa. Falta repetir la comprobación desde una red externa.
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
"""
EVID = (EVID.replace("@@HASH@@", h_code).replace("@@FECHA@@", f_code)
        .replace("@@ENV@@", ENV_LINE).replace("@@PK@@", PK_LINE))

write("docs/adr/0012-despliegue-en-servidor-del-laboratorio.md", ADR12)
print("ok: ADR-0012 escrito completo")
write("docs/evidencia-s12.md", EVID)
print("ok: evidencia-s12.md escrito completo")

# ---------- ADR-0011: hash de trazabilidad ----------
sub("docs/adr/0011-historial-de-cambios-transaccional.md",
    "| **Commits que lo implementan** | `<completar con el hash tras el commit>` |",
    f"| **Commits que lo implementan** | {h_code} |")

# ---------- arc42 §7: URL del laboratorio ----------
sub("docs/arc42/07-deployment-view.md", "<completar URL>",
    "`https://dinamikutb.iscoutb.dev` (`/health`); comprobación externa pendiente, ver [ADR-0012](../adr/0012-despliegue-en-servidor-del-laboratorio.md)")

# ---------- C4: pie sin broker ----------
sub("docs/c4/contenedores.puml", "SHOW_LEGEND()",
    "footer Sin broker de mensajes: integración síncrona (ADR-0004), sin flujo por eventos (arc42 §8.10)\nSHOW_LEGEND()")

# ---------- aspectos.md ----------
sub("docs/aspectos.md",
    "[ADR-0010](adr/0010-extraccion-de-modulo.md) | [main.py]",
    "[ADR-0010](adr/0010-extraccion-de-modulo.md), [ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md) | [main.py]")
sub("docs/aspectos.md",
    "[render.yaml](../render.yaml), [requisitos_service.dart]",
    "[render.yaml](../render.yaml), [compose.lab.yaml](../deploy/compose.lab.yaml), [requisitos_service.dart]")
sub("docs/aspectos.md",
    "[ADR-0010](adr/0010-extraccion-de-modulo.md) | [router.py]",
    "[ADR-0010](adr/0010-extraccion-de-modulo.md), [ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md) | [router.py]")

# ---------- arc42 §9.2 ----------
sub("docs/arc42/09-architecture-decisions.md",
    "ADR-0007, ADR-0008, ADR-0010 | Aceptado",
    "ADR-0007, ADR-0008, ADR-0010, ADR-0012 | Aceptado")
sub("docs/arc42/09-architecture-decisions.md",
    "ADR-0005, ADR-0007, ADR-0010 | Aceptado",
    "ADR-0005, ADR-0007, ADR-0010, ADR-0012 | Aceptado")

# ---------- arc42 §10.4 ----------
sub("docs/arc42/10-quality-requirements.md",
    "(plataforma de despliegue y su riesgo de *spin down*).",
    "(plataforma de despliegue y su riesgo de *spin down*), [ADR-0012](../adr/0012-despliegue-en-servidor-del-laboratorio.md) (despliegue en el laboratorio, sin *spin down*).")

# ---------- README ----------
sub("README.md", "(0001 a 0011)", "(0001 a 0012)")
insert_after("README.md", "├── render.yaml", [
    "├── docker-compose.yml                # PostgreSQL local para desarrollo",
    "├── deploy/",
    "│   ├── compose.lab.yaml              # Despliegue en el laboratorio con Dokploy (ADR-0012)",
    "│   └── .env.example                  # Variables del laboratorio (sin secretos)",
], "compose.lab.yaml")
insert_after("README.md", "│   ├── pyproject.toml", [
    "│   ├── Dockerfile                    # Imagen de la API (ADR-0012)",
], "Imagen de la API")
insert_after("README.md", "| Análisis estático | https://sonarcloud", [
    "| Backend (laboratorio, ADR-0012) | https://dinamikutb.iscoutb.dev (despliegue en curso al 25/10/2026) |",
    "| Health check (laboratorio) | https://dinamikutb.iscoutb.dev/health |",
], "Backend (laboratorio")

# ---------- ia.md: última fila ----------
IA_ROW = ("| 25/10/2026 | Claude | Apoyo en la evidencia S12: estrategia de datos, caché y ADR de la decisión más costosa de revertir "
          "| Se solicitó revisar el repositorio completo y proponer la tabla operación→garantía de consistencia, el diseño de caché con su política de invalidación, "
          "el ADR de la decisión de datos más costosa de revertir, y los cambios en el C4 y en arc42 sección 8. También se pidió revisar qué faltaba frente a la ficha S12 y completar los campos pendientes de los ADR. "
          "| Se propuso: la tabla de 12 operaciones, la decisión de no tener caché de servidor con inventario de copias del cliente, el ADR-0011 (historial transaccional) con su implementación y pruebas, "
          "el C4 con los almacenes de datos, y el registro del despliegue en el laboratorio (ADR-0012 con `deploy/compose.lab.yaml`). "
          "| **Aceptado parcialmente.** El equipo contrastó la tabla de §8.8 con el código y ejecutó `git grep` (marcadores pendientes, credenciales y caché) y `curl` contra el despliegue del laboratorio. "
          "Se rechazó: (1) la afirmación «sin broker, declarado en el pie» del C4, porque el diagrama no tenía pie; se agregó `footer` en `contenedores.puml`; "
          "(2) tratar como caché las coincidencias de `expire` y `ttl` (`expires_in`, `pumpAndSettle`), que son falsos positivos y se declararon como tales; "
          "(3) un resultado de comprobación exitoso para el laboratorio: el `curl` devolvió 404 de Traefik, así que ADR-0012 y la evidencia lo registran como «No verificado» hasta que la ruta esté activa. "
          "No se reescribió ningún ADR aceptado salvo completar campos de trazabilidad que estaban vacíos. |")
p = "docs/ia.md"
s = read(p)
if "ADR-0012 con `deploy/compose.lab.yaml`" in s:
    print("ya aplicado:", p)
else:
    nl = "\r\n" if "\r\n" in s else "\n"
    lines = s.split(nl)
    idx = [i for i, l in enumerate(lines) if l.startswith("| 25/10/2026 | Claude |")]
    assert idx, "No encontré la fila del 25/10 en ia.md"
    lines[idx[-1]] = IA_ROW
    write(p, nl.join(lines))
    print("ok:", p)

print("\nPendientes que el script NO toca a propósito:")
print(" - ADR-0007 `<completar fecha>`: es un ADR aceptado desde el 27/09, editarlo cuenta como reescritura.")
print(" - ADR-0005 `curl <URL>/health`: es una plantilla de comando, no un campo vacío.")
