# 11. Risks and Technical Debt

Esta sección registra los riesgos conocidos de **DinamikUTB** y remite a [docs/deuda-tecnica.md](../deuda-tecnica.md) para la deuda técnica ya documentada allí (lock files, SonarCloud), sin duplicarla. Los riesgos nuevos surgen de desplegar el sistema fuera del entorno local, según lo aceptado en [ADR-0005](../adr/0005-plataforma-despliegue-backend.md), [ADR-0006](../adr/0006-plataforma-despliegue-frontend.md) y [ADR-0007](../adr/0007-persistencia-render-postgres.md). La sección 11.5 agrega los modos de fallo de la integración principal.

---

## 11.1 Riesgos críticos — seguridad

| Riesgo | Detectado en | Descripción | Impacto | Mitigación |
|---|---|---|---|---|
| **Endpoints sin autenticación expuestos públicamente** | `backend/app/requisitos/router.py`, `backend/app/estudiantes/router.py`; ver [06-runtime-view.md](./06-runtime-view.md) | El módulo `usuarios/` todavía no tiene código. `GET /requisitos/{estudiante_id}` y `GET /estudiantes/{codigo_estudiantil}` no verifican identidad: cualquiera con la URL pública puede consultar el avance de cualquier estudiante iterando IDs. | Alto — viola [Q-02](./10-quality-requirements.md#escenario-q-02--seguridad-y-aislamiento-de-la-información) y el aspecto [A-05](../aspectos.md#a-05--protección-y-control-de-acceso-a-la-información-académica). | El ambiente desplegado contiene **únicamente los datos de ejemplo de `backend/app/seed.py`** (estudiante ficticio `T000123456`); no se cargan datos reales hasta que A-05 tenga código. Limitación documentada en el README del sistema desplegado. |
| **Endpoint de escritura sin autenticación** | `PUT /requisitos/{requisito_id}/estado` en `backend/app/requisitos/router.py` | Cualquier persona con la URL pública puede **modificar** el estado de un requisito, no solo leerlo. Es peor que el riesgo de lectura porque compromete la integridad ([Q-01](./10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica)). | Alto en integridad; acotado en la práctica porque solo existen datos de ejemplo. | Los datos de ejemplo se restauran reiniciando y resembrando (`python -m app.seed` corre en cada arranque solo si las tablas están vacías; recrear la base los restablece). La corrección definitiva es exigir autenticación y rol coordinador/administrador (A-05, A-08). |
| **CORS restringido por variable de entorno** | `backend/app/main.py` (`CORS_ORIGINS`), `render.yaml` | Antes: `allow_origins=["*"]`. Ahora se permite solo el origen de GitHub Pages (`https://iscoutb.github.io`), más `localhost` para desarrollo. | Reducido. Residual: `localhost` sigue permitido por regex. | Resuelto en código. Al pasar a producción real, eliminar el regex de `localhost` y fijar solo el origen institucional. |

## 11.2 Riesgos de persistencia y disponibilidad

| Riesgo | Detectado en | Descripción | Impacto | Mitigación |
|---|---|---|---|---|
| **Expiración de la base de datos gratuita a los 30 días** | Capa gratuita de Render, documentada en [ADR-0007](../adr/0007-persistencia-render-postgres.md) | El plan gratuito de Render Postgres expira 30 días después de creado, con 14 días de gracia antes de eliminar la base y sus datos. | Alto si no se atiende a tiempo — pérdida total de los datos de demostración. | Base creada el **27/09/2026**; expira el **27/10/2026**. Recrear y resembrar (`python -m app.seed`) antes del **25/10/2026**. Los únicos datos son los de ejemplo, por lo que la pérdida no afecta información real. |
| ***Spin down* del backend tras 15 minutos de inactividad** | Capa gratuita de Render, documentada en [ADR-0005](../adr/0005-plataforma-despliegue-backend.md) | El primer request tras inactividad tarda ~1 minuto en responder. | Medio — puede leerse como una caída, afectando [Q-05](./10-quality-requirements.md#escenario-q-05--disponibilidad-del-sistema). | Ver modo de fallo F2 en 11.5: el cliente espera y reintenta. La latencia se observa en `GET /metrics`. |
| **Diferencia de motor de base de datos entre ambientes** | Consecuencia aceptada de [ADR-0007](../adr/0007-persistencia-render-postgres.md) | Desarrollo local y CI usan SQLite ([ADR-0003](../adr/0003-seleccion-motor-de-base-de-datos.md)); el ambiente desplegado usa Postgres, lo que podría ocultar bugs específicos de un motor hasta el despliegue. | Bajo-medio | Ejecutar `pytest` también contra Postgres antes de una entrega real, o mantener esta divergencia como limitación conocida. |
| **Métricas en memoria** | `backend/app/core/metrics.py` | Los contadores se reinician con cada reinicio o *spin down* del servicio. | Bajo | Aceptado para el alcance actual; una solución persistente (Prometheus/servicio gestionado) queda como evolución. |

## 11.3 Deuda técnica relacionada

Ver [docs/deuda-tecnica.md](../deuda-tecnica.md) para los ítems ya reconocidos (lock files sin hashes, SonarCloud). La migración a PostgreSQL recomendada por el docente queda **resuelta operativamente** para el ambiente desplegado mediante [ADR-0007](../adr/0007-persistencia-render-postgres.md); el desarrollo local sigue en SQLite ([ADR-0003](../adr/0003-seleccion-motor-de-base-de-datos.md)).

## 11.4 Relación con otros documentos

- El límite de costo y la restricción de "sin tarjeta" que motivaron los ADR de despliegue están en [02-architecture-constraints.md](./02-architecture-constraints.md); la estimación, en [docs/costos.md](../costos.md).
- Los aspectos afectados por estos riesgos (A-01, A-04, A-05) están en [docs/aspectos.md](../aspectos.md).
- El índice de decisiones que originan estos riesgos está en [09-architecture-decisions.md](./09-architecture-decisions.md).

---

## 11.5 Modos de fallo de la integración principal

**Integración analizada:** Flutter → FastAPI por HTTP/JSON (`GET /requisitos/{estudiante_id}`, `PUT /requisitos/{requisito_id}/estado`), y FastAPI → base de datos. Es la única frontera de red del sistema ([ADR-0004](../adr/0004-comunicacion-sincrona-frontend-backend.md), [ADR-0010](../adr/0010-extraccion-de-modulo.md)).

Estado de cada mitigación: **Probada** (hay una prueba automatizada que la ejerce), **Implementada** (existe en el código, sin prueba específica), **Pendiente** (descrita, sin código).

| ID | Modo de fallo | Qué pasa hoy | Mitigación asignada | Estado | Prueba |
|---|---|---|---|---|---|
| F1 | **No responde** (backend caído o sin conexión) | El cliente recibe un error de conexión. Antes de esta mitigación, la pantalla quedaba en error al primer fallo. | Timeout de 25 s por intento y hasta 3 intentos, con espera creciente (2 s, 4 s). Si se agotan, la pantalla muestra «No se pudo cargar la información. Intenta de nuevo.» (`requisitos_screen.dart`). | **Probada** | `requisitos_service_test.dart`: reintento tras falla de conexión, tras 503 y agotamiento de intentos |
| F2 | **Responde tarde** (arranque en frío de Render, ~1 min) | La primera consulta tras 15 min de inactividad tarda cerca de un minuto. | El timeout por intento corta la espera indefinida y los reintentos cubren el arranque en frío (3 × 25 s). La pantalla muestra el indicador de carga durante la espera (táctica de Q-03). La latencia se observa en `GET /metrics`. | **Probada** (timeout y recuperación); la duración real del arranque en frío es una medición del ambiente desplegado, no de las pruebas | `requisitos_service_test.dart`: corte por timeout y recuperación tras un primer intento lento |
| F3 | **Base de datos no disponible** | `GET /health` responde 503 y las consultas fallan con 5xx. `pool_pre_ping` descarta conexiones muertas. | `/health` con `SELECT 1` y `healthCheckPath` en `render.yaml` para detectarlo; el cliente reintenta los 5xx. | **Probada** (detección) / **Implementada** (reintento ante 5xx probado en cliente con 503) | `test_health.py`: 503 con base caída |
| F4 | **Responde dos veces / petición duplicada** (reintento del cliente, doble clic, red que repite) | `PUT` fija un valor absoluto, por lo que repetirlo deja el mismo estado y no crea registros. | La operación es idempotente por diseño (sección 11.6). Las consultas `GET` son idempotentes por definición. | **Probada** | `test_idempotencia.py`: PUT repetido, sin duplicados; `requisitos_service_test.dart`: consulta repetida |
| F5 | **Respuesta perdida tras aplicar el cambio** (el `PUT` hizo commit pero el cliente no recibió el 200) | El cliente no sabe si se aplicó. | Reintentar es seguro porque el `PUT` es idempotente: el segundo intento confirma el mismo estado. | **Probada** (por la prueba de F4) | `test_idempotencia.py` |
| F6 | **Escrituras concurrentes en conflicto** (dos usuarios cambian el mismo requisito) | Gana la última escritura. SQLite admite un solo escritor a la vez (ADR-0003). | Ninguna todavía. Se documenta el comportamiento actual. Se resolverá con control de versión (concurrencia optimista) junto con A-05 y A-08, cuando existan usuarios con rol que escriban. | **Pendiente** (comportamiento actual documentado en una prueba) | `test_idempotencia.py`: `test_ultima_escritura_gana...` |
| F7 | **Expiración de la base gratuita** | A los 30 días Render deja de ofrecer la base; a los 44 se elimina. | Recrear y resembrar antes del 25/10/2026 (11.2). | **Pendiente** (acción operativa con fecha) | No automatizable; verificar `/health` tras recrearla |

**Mitigaciones que no se implementan, con su razón:**

| Mitigación | Decisión |
|---|---|
| **Circuit breaker** | No aplica. Hay un único cliente y un único servidor: un breaker evita saturar un servicio compartido entre muchos consumidores, y aquí el reintento acotado (3 intentos) ya limita la carga. Se reevalúa si aparecen más consumidores o dependencias externas. |
| **Reintento de escrituras en el cliente** | El frontend no tiene aún ninguna pantalla que llame al `PUT` (los coordinadores no tienen interfaz). El `PUT` ya es seguro de repetir; el reintento en el cliente se agrega cuando exista esa pantalla. |
| **Saga / compensación** | No aplica (ver 11.6). |

**Modos de fallo con prueba y solo descritos** (para el criterio de calidad y resiliencia del proyecto final): F1, F2, F4 y F5 tienen prueba; F3 tiene prueba de detección; F6 y F7 están solo descritos, con el plan indicado arriba.

## 11.6 Diseño de idempotencia y por qué no hay saga

**Operaciones que pueden repetirse:**

| Operación | ¿Idempotente? | Razón |
|---|---|---|
| `GET /requisitos/{id}`, `GET /estudiantes/{codigo}` | Sí | Solo leen. |
| `PUT /requisitos/{id}/estado` | Sí | Recibe el estado final deseado (`cumplido`, `pendiente`, `en_proceso`), no una instrucción relativa como «avanzar». Aplicarlo N veces deja el mismo estado. |

**Límite del diseño actual:** la idempotencia del `PUT` se debe a su semántica de «fijar valor», no a un mecanismo de deduplicación. Cuando exista historial de cambios (A-08, Q-08), cada repetición generaría una entrada nueva en el historial aunque el valor no cambie. En ese momento se debe registrar el cambio solo si el valor anterior difiere del nuevo, o exigir una `Idempotency-Key` en el encabezado. Se decide en el ADR del historial.

**Por qué no aplica una saga:** una saga coordina operaciones que tocan varios servicios o almacenes y exigen compensación si una falla a mitad de camino. Aquí cada operación de escritura modifica **una sola fila de una sola base de datos** dentro de una única transacción de SQLAlchemy (`service.py`, `commit()`), de modo que la propia base garantiza que no queda a medio actualizar. No hay llamadas a servicios externos ni otro almacén que compensar. Si en el futuro se extrae un módulo o se integra un sistema institucional, esta decisión se reabre ([ADR-0010](../adr/0010-extraccion-de-modulo.md), sección 6).
