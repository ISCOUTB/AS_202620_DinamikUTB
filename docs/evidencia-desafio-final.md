# Evidencia del desafío final contextualizado

> **Alcance y honestidad:** este documento reconstruye un desafío **real ocurrido
> en el proyecto** —la expiración de la base gratuita de Render y la migración al
> servidor del laboratorio— usando solo evidencia ya versionada. No afirma que el
> docente haya asignado este enunciado: si el aula entrega un desafío distinto,
> esta plantilla debe completarse con ese enunciado y sus criterios. La decisión
> técnica está registrada en [ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md).

## 1. Escenario contextualizado

| Elemento | Descripción |
|---|---|
| **Contexto** | Proyecto académico DinamikUTB con presupuesto $0 y sin tarjeta de crédito; frontend en GitHub Pages, backend FastAPI y base de datos. |
| **Restricción disparadora (incidente real)** | La base gratuita de Render creada el 27/09/2026 expiraba a los 30 días (27/10/2026) con 14 días de gracia. El servicio Free tenía *spin down*: el primer request tras inactividad tardaba ~1 min. |
| **Necesidad** | Mantener datos e historial académico, evitar arranque en frío y conservar el costo en $0, sin acceso a la base de Render una vez retirada. |
| **Criterios de aceptación verificables** | (1) Base sin fecha de expiración y consultable desde red externa; (2) `GET /health` → HTTP 200; (3) sin *spin down*; (4) historial transaccional conservado; (5) costo $0 para el equipo; (6) suite backend en verde con cobertura ≥ 80 %. |

## 2. Línea base cuantificada (antes del cambio)

| Métrica | Línea base (Render, registro histórico) | Fuente |
|---|---|---|
| Persistencia | 1 GB con **expiración a 30 días** (+14 de gracia); fecha límite 27/10/2026 | [docs/costos.md](costos.md) §2, registro histórico |
| Disponibilidad | *Spin down* tras inactividad; primer request ~1 min | [docs/costos.md](costos.md) §2 |
| Costo | $0/mes, pero con migración forzada o plan de pago (~USD 6–7/mes por pieza) | [docs/costos.md](costos.md) §2–3 |
| Respaldo | Sin `pg_dump` programado; la pérdida de la base implicaba perder el historial | [ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md) §5 |
| Cobertura backend | Sin umbral local enforceable en el repositorio | `.coveragerc` antes del cambio; `ci.yml` |

## 3. Cambio aplicado y resultado medido (después)

| Métrica | Resultado | Evidencia |
|---|---|---|
| Persistencia | PostgreSQL 16 en volumen `pgdata`, sin expiración por tiempo | [ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md) §4, [deploy/compose.lab.yaml](../deploy/compose.lab.yaml) |
| Disponibilidad | `https://api-dinamikutb.iscoutb.dev/health` → `200 {"status":"ok"}` desde red externa; contenedor `restart: unless-stopped` + healthcheck cada 30 s | [ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md) §8, [README](../README.md#entorno-desplegado) |
| *Spin down* | Eliminado: el contenedor `api` corre siempre en el laboratorio | [arc42 §7.2](arc42/07-deployment-view.md) |
| Costo | $0/mes para el equipo | [docs/costos.md](costos.md) §3 |
| Calidad | 153 pruebas backend en verde; 92,56 % de líneas cubiertas; umbral `fail_under=80` aplicado en `.coveragerc` y CI | `pytest -q`, `coverage.xml`, `.coveragerc`, [.github/workflows/ci.yml](../.github/workflows/ci.yml) |
| Contrato | OpenAPI 3.1.0, v0.2.0, comparado por igualdad estricta con `app.openapi()` | [docs/api/evidencia-prueba-contrato.md](api/evidencia-prueba-contrato.md) |

**Resultado frente a la línea base:** se eliminó la fecha de expiración (27/10/2026 → sin vencimiento) y el arranque en frío (~1 min → sin *spin down*), manteniendo el costo en $0 y conservando el historial en la misma transacción. Los seis criterios de aceptación quedan verificables en el repositorio.

## 4. Degradación, recuperación y adaptación controlada

| Modo de fallo | Comportamiento medido | Criterio de aceptación | Evidencia |
|---|---|---|---|
| Error transitorio 5xx del API | El cliente reintenta hasta 3 veces con backoff 2 s y 4 s; una respuesta 503 seguida de 200 se recupera sin error para el usuario | `503 → 200` en el segundo intento | `frontend/test/requisitos_service_test.dart`, `frontend/lib/requisitos/requisitos_service.dart` |
| Caída de red / timeout | Timeout de 15 s por intento; mensaje claro y reintento; tras agotar intentos, error controlado | Sin excepción no manejada; 3 intentos como máximo | `frontend/lib/core/network/api_client.dart`, `requisitos_service_test.dart` |
| Base de datos no disponible | `GET /health` responde 503; `pool_pre_ping=True` descarta conexiones muertas | `503` explícito, no `500` | `backend/tests/test_health.py`, `backend/app/core/database.py` |
| Carga duplicada / concurrencia | `PUT` idempotente y `with_for_update()`; una sola fila de historial | Sin duplicados | `backend/tests/test_idempotencia.py` |
|fallo SMTP | Respuesta `503` explícita y ámbito limitado a la recuperación; el resto del sistema sigue operativo | Fallo aislado, sin broker | [evidencia-s13](evidencia-s13.md) T-11, `backend/app/usuarios/router.py` |

**Adaptación controlada:** la interfaz muestra un botón de reintento en pantallas administrativas (`AdminLoadError`) y el frontend no reintenta errores 404, evitando amplificar fallos permanentes.

## 5. Contrafactuales (qué habría ocurrido sin el cambio)

| Alternativa descartada | Consecuencia contrafactual | Evidencia |
|---|---|---|
| No migrar de Render | La base expiraba el 27/10/2026: pérdida de datos e historial; servicio con *spin down* | [ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md) §3–5 |
| Mantener SQLite en producción | Al recrear el contenedor se pierde el archivo de base; hipótesis ya descartada en S2 | [ADR-0003](adr/0003-seleccion-motor-de-base-de-datos.md), [ADR-0007](adr/0007-persistencia-render-postgres.md) |
| Añadir broker de mensajes para correo | Costo y memoria adicionales en un laboratorio con límite de 512 MB; se prefiere 503 explícito | [arc42 §8.10](arc42/08-cross-cutting-concepts.md), [deuda-tecnica.md](deuda-tecnica.md) |
| Circuit breaker / saga | Complejidad sin beneficio: un solo cliente, un solo servidor y una sola fila por transacción | [ADR-0010](adr/0010-extraccion-de-modulo.md), [ia.md](ia.md) fila 18/10/2026 |
| Generar mallas inventadas para otros programas | Datos académicos no verificables; se rechaza explícitamente | [ia.md](ia.md) fila 20/11/2026, [deuda-tecnica.md](deuda-tecnica.md) |

## 6. Responsables y rotación de este desafío

| Responsable | Responsabilidad asumida | Evidencia |
|---|---|---|
| Juan José Vargas | Decisión de plataforma y comprobación externa del despliegue | [ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md) §8 |
| Luis Daniel Padilla | Salud, métricas y mitigación del fallo SMTP | [evidencia-s13](evidencia-s13.md) T-05, T-11 |
| Gillianis Pérez | Control de acceso y aislamiento por programa | [evidencia-s13](evidencia-s13.md) T-03, T-07; [ADR-0016](adr/0016-modulo-ayuda-y-aislamiento-por-programa.md) |
| Esteban Ramírez | Auditoría de dependencias y resolución de `PYSEC-2026-4320` | [evidencia-s13](evidencia-s13.md) T-08 y §2 |

> Los cuatro integrantes aparecen como dueños de mitigaciones verificables. La
> distribución global de commits sigue siendo desigual y se reconoce en
> `correcciones.md`; no se afirma una rotación perfecta, sino responsabilidades
> técnicas distribuidas en este desafío.

## 7. Deuda y límites reconocidos

- Sin copia automática del volumen `pgdata`: riesgo pendiente antes de datos reales ([ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md) §5).
- Coordinador no atado a programa fuera de `ayuda/` ([deuda-tecnica.md](deuda-tecnica.md)).
- Lock de Python con hashes pendiente; actions fijadas por SHA y dependencias con `==` ([deuda-tecnica.md](deuda-tecnica.md), [evidencia-s13](evidencia-s13.md) T-08).
- Recuperación por correo expuesta en la UI pero no operativa: responde 503 por diseño documentado (`backend/app/usuarios/router.py`).
- Branch coverage no medido; se reporta cobertura de líneas con umbral 80 %.
