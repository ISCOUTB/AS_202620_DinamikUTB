# 7. Deployment View

Esta sección describe dónde se ejecuta cada pieza de **DinamikUTB** en el ambiente desplegado, siguiendo las decisiones aceptadas en [ADR-0005](../adr/0005-plataforma-despliegue-backend.md) (backend), [ADR-0006](../adr/0006-plataforma-despliegue-frontend.md) (frontend) y [ADR-0007](../adr/0007-persistencia-render-postgres.md) (persistencia).

> **Estado de implementación:** la infraestructura vigente está descrita como código (`deploy/compose.lab.yaml` y `.github/workflows/deploy-pages.yml`); `render.yaml` se conserva como registro del ambiente experimental retirado. La URL vigente y su comprobación externa están documentadas en [ADR-0012](../adr/0012-despliegue-en-servidor-del-laboratorio.md#comprobación-del-despliegue) y en el [README](../../README.md#entorno-desplegado).

> **Topología vigente:** el entorno de referencia es el servidor del laboratorio
> (Dokploy + Traefik, PostgreSQL 16 en volumen `pgdata`), según
> [ADR-0012](../adr/0012-despliegue-en-servidor-del-laboratorio.md). El despliegue
> en Render descrito abajo se conserva como registro histórico del ambiente
> experimental retirado el 25/10/2026.

---

## 7.1 Infrastructure Level 1 — Vista general

Cada pieza se despliega y opera de forma independiente; ninguna comparte proceso ni sistema de archivos con otra.

```mermaid
flowchart TD
    A[Internet<br>fuera de la universidad]
    B[GitHub Pages<br>Frontend Flutter web<br>Estático, siempre activo]
    C[Traefik/Dockploy<br>Proxy inverso del laboratorio]
    D[Servidor del laboratorio<br>Backend FastAPI en Docker<br>Siempre activo, sin spin down]
    E[PostgreSQL 16 en Docker<br>Volumen pgdata, sin expiración]

    A --> B
    A --> C
    B <-->|"HTTP/JSON fetch"| C
    C --> D
    D <-->|"SQL vía SQLAlchemy"| E
```

| Pieza | Dónde corre | URL pública | Siempre activo | Costo mensual | ADR |
|---|---|---|---|---|---|
| Frontend (Flutter web) | GitHub Pages | `https://iscoutb.github.io/AS_202620_DinamikUTB/` | Sí (contenido estático) | $0 | [ADR-0006](../adr/0006-plataforma-despliegue-frontend.md) |
| Backend (FastAPI) | Render — Free Web Service (**retirado**) | `https://dinamikutb-api.onrender.com` — verificada el 27/09/2026 (HTTP 200); dada de baja tras la migración | No aplica — servicio retirado | $0 | [ADR-0005](../adr/0005-plataforma-despliegue-backend.md), [ADR-0012](../adr/0012-despliegue-en-servidor-del-laboratorio.md) |
| Base de datos | Render Postgres (Free) | interna, no pública | Sí, mientras no expire | $0, expira a los 30 días de creada (14 días de gracia). Creada el 27/09/2026; expira el 27/10/2026; recrear y resembrar antes del 25/10/2026. (**expirada el 27/10/2026**, ver F6 en §11) | [ADR-0007](../adr/0007-persistencia-render-postgres.md) |
| Ficheros | No aplica | — | — | — | Ningún módulo sube archivos hoy |
| Trabajos programados | GitHub Actions (`schedule:`) | — | Se ejecuta según el cron configurado | $0 | Pendiente de un ADR propio cuando A-03 tenga código (ver [09-architecture-decisions.md](./09-architecture-decisions.md)) |
| Pipeline de CI | GitHub Actions | — | Se ejecuta en cada push/PR | $0 | Cubierto por `ci.yml` |
| Análisis estático | SonarCloud | `https://sonarcloud.io/project/overview?id=ISCOUTB_AS_202620_DinamikUTB` | Sí | $0 | — |
| Backend + base (laboratorio) | Servidor del laboratorio, Dokploy + Traefik; `api` y `db` (Postgres 16, volumen `pgdata`) | `https://api-dinamikutb.iscoutb.dev` (`/health`) | Sí, sin *spin down* | $0, límite del equipo 512 MB | [ADR-0012](../adr/0012-despliegue-en-servidor-del-laboratorio.md) |

El costo detallado, sus supuestos y el punto de ruptura de cada capa gratuita están en [docs/costos.md](../costos.md).

---

## 7.2 Justificación por escenario de calidad

| Escenario | Elemento de infraestructura | Cómo lo sostiene | ADR |
|---|---|---|---|
| [Q-01](./10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica) | PostgreSQL 16 del laboratorio (volumen `pgdata`) | Persiste datos e historial sin la expiración de 30 días de Render; SQLite en un filesystem efímero no sobreviviría a la recreación del contenedor. | [ADR-0012](../adr/0012-despliegue-en-servidor-del-laboratorio.md) (histórico: [ADR-0007](../adr/0007-persistencia-render-postgres.md)) |
| [Q-03](./10-quality-requirements.md#escenario-q-03--facilidad-de-comprensión-de-la-información) | GitHub Pages | El frontend está siempre disponible sin latencia de arranque, para no confundir un *spin down* del backend con un error de la interfaz. | [ADR-0006](../adr/0006-plataforma-despliegue-frontend.md) |
| [Q-05](./10-quality-requirements.md#escenario-q-05--disponibilidad-del-sistema) | Backend en Dokploy (laboratorio), `GET /health` y `GET /metrics` | Sin *spin down*: el contenedor `api` corre siempre con `restart: unless-stopped` y healthcheck cada 30 s (`deploy/compose.lab.yaml`). El riesgo vigente es la disponibilidad del propio laboratorio, fuera del control del equipo ([ADR-0012](../adr/0012-despliegue-en-servidor-del-laboratorio.md) §5). La métrica `dinamikutb_http_request_duration_seconds` y el contador `dinamikutb_http_requests_total` (por estado) permiten observar latencia y errores 5xx. | [ADR-0012](../adr/0012-despliegue-en-servidor-del-laboratorio.md) |
| [Q-04](./10-quality-requirements.md#escenario-q-04--alertas-tempranas-de-requisitos-pendientes) | GitHub Actions (`schedule:`) | Es la pieza donde correría, a futuro, el disparo periódico de alertas tempranas una vez A-03 tenga código. | Pendiente |

---

## 7.3 Secretos y configuración

| Variable | Propósito | Dónde vive | Valor |
|---|---|---|---|
| `DATABASE_URL` | Cadena de conexión a PostgreSQL. Sin definir, el backend usa SQLite local. | Inyectada por Dokploy en `deploy/compose.lab.yaml` desde `POSTGRES_*`. Nunca se guarda en el repositorio. | Secreto del proveedor |
| `CORS_ORIGINS` | Orígenes permitidos por CORS (lista separada por comas). | Configurada en `deploy/compose.lab.yaml` de Dokploy. No es un secreto porque contiene un origen público. | `https://iscoutb.github.io` |
| `API_BASE_URL` | URL del backend que el frontend utiliza al compilar (`--dart-define`). | Variable de repositorio de GitHub Actions (opcional; tiene un valor por defecto en `deploy-pages.yml`). | `https://api-dinamikutb.iscoutb.dev` |
| `METRICS_TOKEN` | Protege `GET /metrics`; sin él, el endpoint responde 404 en producción. | Variable obligatoria en `deploy/compose.lab.yaml`, definida en Dokploy. | Secreto del proveedor |
| `SONAR_TOKEN` | Autenticación del análisis de SonarCloud. | Secreto de GitHub Actions | Secreto del proveedor |

`.env.example` declara las variables del backend; `.env` está en `.gitignore`. Ninguna credencial se escribe en el código ni en `docs/`.

## 7.4 Relación con otras vistas y documentos

- Los contenedores lógicos que aquí se ubican en infraestructura concreta están definidos en [05-building-block-view.md](./05-building-block-view.md) y en `docs/c4/contenedores.puml`.
- Las decisiones de plataforma están en [ADR-0005](../adr/0005-plataforma-despliegue-backend.md), [ADR-0006](../adr/0006-plataforma-despliegue-frontend.md) y [ADR-0007](../adr/0007-persistencia-render-postgres.md), indexadas en [09-architecture-decisions.md](./09-architecture-decisions.md).
- El límite de costo y la restricción de "sin tarjeta" están en [02-architecture-constraints.md](./02-architecture-constraints.md); la estimación, en [docs/costos.md](../costos.md).
- Los riesgos que esta topología introduce están en [11-risks-and-technical-debt.md](./11-risks-and-technical-debt.md).
- Los aspectos sustentados (A-01, A-04) están en [docs/aspectos.md](../aspectos.md).
