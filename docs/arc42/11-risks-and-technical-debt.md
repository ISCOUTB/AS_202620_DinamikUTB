
# 11. Risks and Technical Debt

Esta sección registra los riesgos conocidos de **DinamikUTB** y remite a [docs/deuda-tecnica.md](../deuda-tecnica.md) para la deuda técnica ya documentada allí (lock files, migración a PostgreSQL recomendada por el docente, SonarCloud bloqueado), sin duplicarla. Los riesgos nuevos de esta sección surgen de desplegar el sistema fuera del entorno local, según lo aceptado en [ADR-0005](../adr/0005-plataforma-despliegue-backend.md) y [ADR-0006](../adr/0006-plataforma-despliegue-frontend.md).

---

## 11.1 Riesgos críticos — seguridad

| Riesgo | Detectado en | Descripción | Impacto | Mitigación propuesta |
|---|---|---|---|---|
| **Endpoints sin autenticación expuestos públicamente** | `backend/app/requisitos/router.py`, `backend/app/estudiantes/router.py`; confirmado como pendiente en [06-runtime-view.md](./06-runtime-view.md) | El módulo `usuarios/` todavía no tiene código. `GET /requisitos/{estudiante_id}` y `GET /estudiantes/{codigo_estudiantil}` no verifican identidad: cualquiera con la URL pública puede consultar el avance académico de cualquier estudiante iterando IDs. Al desplegar el backend fuera de la universidad ([ADR-0005](../adr/0005-plataforma-despliegue-backend.md)), este riesgo pasa de teórico a real. | Alto — viola directamente [Q-02](./10-quality-requirements.md#escenario-q-02--seguridad-y-aislamiento-de-la-información) y el aspecto [A-05](../aspectos.md#a-05--protección-y-control-de-acceso-a-la-información-académica). | No exponer datos reales de estudiantes mientras `usuarios/` no tenga autenticación: usar únicamente los datos de ejemplo de `backend/app/seed.py` en el ambiente desplegado hasta que A-05 tenga código. Documentar esta limitación de forma visible en el README del sistema desplegado. |
| **CORS abierto a cualquier origen** | `backend/app/main.py`, `allow_origins=["*"]` | Cualquier sitio web puede invocar la API del backend desde el navegador de un usuario. Es aceptable en desarrollo local, pero no en un backend accesible desde internet. | Medio — amplía la superficie de ataque del riesgo anterior. | Reemplazar `["*"]` por la URL exacta del frontend en GitHub Pages ([ADR-0006](../adr/0006-plataforma-despliegue-frontend.md)), como variable de entorno (ver [07-deployment-view.md](./07-deployment-view.md), sección 7.3), no como valor fijo en el código. |

## 11.2 Riesgos de persistencia y disponibilidad

| Riesgo | Detectado en | Descripción | Impacto | Mitigación propuesta |
|---|---|---|---|---|
| **Expiración de la base de datos gratuita a los 30 días** | Verificación de la capa gratuita de Render, documentada en [ADR-0005](../adr/0005-plataforma-despliegue-backend.md) | El plan gratuito de Render Postgres expira 30 días después de creado, con 14 días de gracia antes de eliminar la base y sus datos. | Alto si no se atiende a tiempo — pérdida total de los datos de demostración. | Registrar en [07-deployment-view.md](./07-deployment-view.md) la fecha de creación de la base (hoy `<pendiente>`) y agendar su recreación/resiembra (`python -m app.seed`) antes del día 25 desde la creación, con margen de seguridad. |
| ***Spin down* del backend tras 15 minutos de inactividad** | Verificación de la capa gratuita de Render, documentada en [ADR-0005](../adr/0005-plataforma-despliegue-backend.md) | El primer request tras un período de inactividad tarda ~1 minuto en responder mientras el servicio se reactiva. | Medio — puede leerse como una caída del sistema si no se comunica, afectando la medida de [Q-05](./10-quality-requirements.md#escenario-q-05--disponibilidad-del-sistema). | Mostrar un estado de "cargando" explícito en el frontend durante ese primer request (coherente con la táctica de Q-03 ya documentada), y mencionarlo explícitamente en cualquier evidencia o demo en vivo. |
| **Diferencia de motor de base de datos entre ambientes** | Consecuencia aceptada de [ADR-0005](../adr/0005-plataforma-despliegue-backend.md) | El desarrollo local sigue usando SQLite ([ADR-0003](../adr/0003-seleccion-motor-de-base-de-datos.md)) mientras el ambiente desplegado usa Postgres, lo que introduce una divergencia que podría ocultar bugs específicos de un motor hasta el despliegue. | Bajo-medio | Ejecutar la suite de `pytest` también contra Postgres antes de cada entrega, o documentar explícitamente esta divergencia como una limitación conocida. |

## 11.3 Deuda técnica relacionada

Ver [docs/deuda-tecnica.md](../deuda-tecnica.md) para los ítems ya reconocidos previamente (lock files sin hashes, migración recomendada por el docente a PostgreSQL, SonarCloud bloqueado por permisos). La fila de PostgreSQL de ese documento queda resuelta operativamente por [ADR-0005](../adr/0005-plataforma-despliegue-backend.md): la migración ya ocurre para el ambiente desplegado, aunque el desarrollo local siga documentado en SQLite ([ADR-0003](../adr/0003-seleccion-motor-de-base-de-datos.md)).

## 11.4 Relación con otros documentos

- El límite de costo y la restricción de "sin tarjeta" que motivaron [ADR-0005](../adr/0005-plataforma-despliegue-backend.md) y [ADR-0006](../adr/0006-plataforma-despliegue-frontend.md) están en [02-architecture-constraints.md](./02-architecture-constraints.md).
- Los aspectos afectados por estos riesgos (A-01, A-04, A-05) están en [docs/aspectos.md](../aspectos.md).
- El índice de decisiones que originan estos riesgos está en [09-architecture-decisions.md](./09-architecture-decisions.md).

