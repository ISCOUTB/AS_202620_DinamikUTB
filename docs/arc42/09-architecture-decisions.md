# 9. Architecture Decisions

Esta sección funciona como índice de las decisiones arquitectónicas (ADR) de DinamikUTB. Cada ADR completo se documenta en `docs/adr/`.

---

## 9.1 Índice de decisiones

| ID | Título | Estado | Resumen |
|---|---|---|---|
| [ADR-0001](../adr/0001-seleccion-monolito-modular.md) | Selección de monolito modular como modelo arquitectónico | *Aceptado* (2026-08-23) | Define la estrategia base en módulos: core, usuarios, estudiantes, requisitos, programas y ayuda. |
| [ADR-0002](../adr/0002-seleccion-tecnologia-backend-frontend.md) | Selección de tecnologías de backend y frontend | *Aceptado* (2026-08-30) | Formaliza FastAPI y Flutter. |
| [ADR-0003](../adr/0003-seleccion-motor-de-base-de-datos.md) | Selección del motor de base de datos | *Aceptado* (2026-09-06) | Formaliza SQLite para local/CI vía SQLAlchemy. |
| [ADR-0004](../adr/0004-comunicacion-sincrona-frontend-backend.md) | Comunicación síncrona entre frontend y backend | *Aceptado* (2026-09-20) | Formaliza HTTP request-response frente a colas asíncronas para garantizar Q-01. |
| [ADR-0005](../adr/0005-plataforma-despliegue-backend.md) | Selección de plataforma de despliegue del backend | *Aceptado* (2026-09-26) | Despliegue inicial en Render Web Service. |
| [ADR-0006](../adr/0006-plataforma-despliegue-frontend.md) | Selección de plataforma de despliegue del frontend | *Superseded* (2026-10-27) | Publicación estática reemplazada por contenedor web en el laboratorio. |
| [ADR-0007](../adr/0007-persistencia-render-postgres.md) | Estrategia de persistencia en el ambiente desplegado | *Aceptado* (2026-09-27) | Render Postgres gratuito (reconociendo expiración de 30 días). |
| [ADR-0008](../adr/0008-verificacion-de-artefactos-sugeridos-por-ia.md) | Verificación de artefactos de terceros sugeridos por IA | *Aceptado* (2026-10-01) | Política de comprobación externa obligatoria tras incidente de SHA. |
| [ADR-0009](../adr/0009-no-incorporacion-componente-generativo.md) | No incorporación de componente generativo en producción | *Aceptado* (2026-10-01) | Rechazo de LLMs en runtime para preservar costo $0 y determinismo de Q-01. |
| [ADR-0010](../adr/0010-extraccion-de-modulo.md) | Decisión de no extraer módulos del monolito | *Aceptado* (2026-10-18) | Evaluación formal que confirma no fragmentar el monolito. |
| [ADR-0011](../adr/0011-historial-de-cambios-transaccional.md) | Historial de cambios transaccional en la misma base | *Aceptado* (2026-10-25) | Tabla append-only por módulo en la misma transacción; decisión más costosa de revertir. |
| [ADR-0012](../adr/0012-despliegue-en-servidor-del-laboratorio.md) | Despliegue en el servidor del laboratorio | *Aceptado* (2026-10-25) | Migración a Dokploy con volumen persistente `pgdata` sin expiración ni spin down. |
| [ADR-0013](../adr/0013-controles-estructurales-de-seguridad-y-autenticacion.md) | Controles estructurales de seguridad, autenticación y control de acceso | *Aceptado* (2026-11-01) | Formaliza JWT con firma de contraseña, Argon2id, RBAC y rate limiting. |
| [ADR-0014](../adr/0014-extension-historial-datos-estudiante.md) | Extensión del historial a datos académicos del estudiante | *Aceptado* (2026-10-30) | Complementa al ADR-0011: audita nombre, programa y semestre en `estudiantes_historial`. |

---

## 9.2 Relación con los aspectos del sistema

| Aspecto | Decisiones que lo sustentan | Estado |
|---|---|---|
| [A-01](../aspectos.md#a-01--seguimiento-del-cumplimiento-de-requisitos) | ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0007, ADR-0010, ADR-0012 | Aceptado |
| [A-02](../aspectos.md#a-02--cálculo-correcto-del-estado-de-graduación) | ADR-0001, ADR-0002, ADR-0003, ADR-0004 | Aceptado |
| [A-03](../aspectos.md#a-03--alertas-tempranas-de-requisitos-pendientes) | ADR-0009 (regla determinista en evaluación) | Pendiente de código |
| [A-04](../aspectos.md#a-04--disponibilidad-del-sistema) | ADR-0001, ADR-0005, ADR-0007, ADR-0010, ADR-0012 | Aceptado |
| [A-05](../aspectos.md#a-05--protección-y-control-de-acceso-a-la-información-académica) | ADR-0001, ADR-0002, ADR-0013 | Aceptado |
| [A-06](../aspectos.md#a-06--extensibilidad-para-múltiples-programas-académicos) | ADR-0001, ADR-0003, ADR-0014 | Aceptado |
| [A-07](../aspectos.md#a-07--gestión-de-solicitudes-de-estudiantes-en-el-centro-de-ayuda) | ADR-0001 | Pendiente de código |
| [A-08](../aspectos.md#a-08--historial-de-cambios-sobre-la-información-académica) | ADR-0003, ADR-0011, ADR-0014 | Aceptado |
