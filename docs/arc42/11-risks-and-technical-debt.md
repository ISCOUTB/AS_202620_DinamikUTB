# 11. Risks and Technical Debt

Esta sección registra los riesgos conocidos de **DinamikUTB** y remite a [docs/deuda-tecnica.md](../deuda-tecnica.md) para la deuda técnica ya documentada allí (lock files, SonarCloud), sin duplicarla. Los riesgos nuevos surgen de desplegar el sistema fuera del entorno local, según lo aceptado en [ADR-0005](../adr/0005-plataforma-despliegue-backend.md), [ADR-0006](../adr/0006-plataforma-despliegue-frontend.md) y [ADR-0007](../adr/0007-persistencia-render-postgres.md).

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
| **Expiración de la base de datos gratuita a los 30 días** | Capa gratuita de Render, documentada en [ADR-0007](../adr/0007-persistencia-render-postgres.md) | El plan gratuito de Render Postgres expira 30 días después de creado, con 14 días de gracia antes de eliminar la base y sus datos. | Alto si no se atiende a tiempo — pérdida total de los datos de demostración. | Fecha de creación de la base: `<completar>`. Recrear y resembrar antes del día 25 (fecha límite: `<completar>`). |
| ***Spin down* del backend tras 15 minutos de inactividad** | Capa gratuita de Render, documentada en [ADR-0005](../adr/0005-plataforma-despliegue-backend.md) | El primer request tras inactividad tarda ~1 minuto en responder. | Medio — puede leerse como una caída, afectando [Q-05](./10-quality-requirements.md#escenario-q-05--disponibilidad-del-sistema). | La latencia se observa en `GET /metrics` (`dinamikutb_http_request_duration_seconds`). Mostrar un estado de "cargando" explícito en el frontend (táctica de Q-03) y mencionarlo en cualquier demo o evidencia. |
| **Diferencia de motor de base de datos entre ambientes** | Consecuencia aceptada de [ADR-0007](../adr/0007-persistencia-render-postgres.md) | Desarrollo local y CI usan SQLite ([ADR-0003](../adr/0003-seleccion-motor-de-base-de-datos.md)); el ambiente desplegado usa Postgres, lo que podría ocultar bugs específicos de un motor hasta el despliegue. | Bajo-medio | Ejecutar `pytest` también contra Postgres antes de una entrega real, o mantener esta divergencia como limitación conocida. |
| **Métricas en memoria** | `backend/app/core/metrics.py` | Los contadores se reinician con cada reinicio o *spin down* del servicio. | Bajo | Aceptado para el alcance actual; una solución persistente (Prometheus/servicio gestionado) queda como evolución. |

## 11.3 Deuda técnica relacionada

Ver [docs/deuda-tecnica.md](../deuda-tecnica.md) para los ítems ya reconocidos (lock files sin hashes, SonarCloud). La migración a PostgreSQL recomendada por el docente queda **resuelta operativamente** para el ambiente desplegado mediante [ADR-0007](../adr/0007-persistencia-render-postgres.md); el desarrollo local sigue en SQLite ([ADR-0003](../adr/0003-seleccion-motor-de-base-de-datos.md)).

## 11.4 Relación con otros documentos

- El límite de costo y la restricción de "sin tarjeta" que motivaron los ADR de despliegue están en [02-architecture-constraints.md](./02-architecture-constraints.md); la estimación, en [docs/costos.md](../costos.md).
- Los aspectos afectados por estos riesgos (A-01, A-04, A-05) están en [docs/aspectos.md](../aspectos.md).
- El índice de decisiones que originan estos riesgos está en [09-architecture-decisions.md](./09-architecture-decisions.md).
