---
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
| **Commits** | `8dad793` |

### Comprobación del despliegue

<!-- verif:start -->
Comprobación del 26/10/2026 con `curl`, desde una red externa:

| Petición | Resultado |
| :--- | :--- |
| `GET /health` | HTTP 200 (`{"status":"ok"}`) |
| `GET /requisitos/T000123456` | HTTP 401 (credenciales inválidas o sesión expirada) |
| `GET /docs` | HTTP 404 (esperado en producción, `docs_url=None`) |

**Estado esperado:** Despliegue verificado. El dominio público dirige las peticiones a la API desplegada en el servidor del laboratorio.
<!-- verif:end -->
