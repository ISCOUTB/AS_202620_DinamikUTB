# 9. Architecture Decisions

Esta sección funciona como índice de las decisiones arquitectónicas (ADR) de DinamikUTB. Cada ADR completo se documenta en `docs/adr/`; aquí se resume su alcance y se deja constancia de las decisiones que todavía no se han formalizado, para que la trazabilidad de `docs/aspectos.md` sea verificable en un solo lugar.

---

## 9.1 Índice de decisiones

| ID | Título | Estado | Resumen |
|---|---|---|---|
| [ADR-0001](../adr/0001-seleccion-monolito-modular.md) | Selección de monolito modular como modelo arquitectónico | *Aceptado* (2026-08-23) | Define la estrategia arquitectónica base: una sola aplicación desplegable, dividida internamente en los módulos core, usuarios, estudiantes, requisitos, programas y ayuda. Sustenta A-01, A-02, A-04, A-05, A-06 y A-07. |
| [ADR-0002](../adr/0002-seleccion-tecnologia-backend-frontend.md) | Selección de tecnologías de backend y frontend | *Aceptado* (2026-08-30) | Formaliza *FastAPI* (backend) y *Flutter* (frontend) como las tecnologías concretas sobre las que se implementa el monolito modular del ADR-0001. Sustenta A-01, A-02 y A-05. |
| [ADR-0003](../adr/0003-seleccion-motor-de-base-de-datos.md) | Selección del motor de base de datos | *Aceptado* (2026-09-06) | Formaliza *SQLite* (vía SQLAlchemy) como motor de persistencia relacional para desarrollo local, cerrando la restricción pendiente sobre el motor de base de datos en 02-architecture-constraints.md. Sustenta A-01, A-02, A-06 y, parcialmente, A-08. |
| [ADR-0004](../adr/0004-comunicacion-sincrona-frontend-backend.md) | Comunicación síncrona entre frontend y backend | *Aceptado* (2026-09-20) | Formaliza la comunicación HTTP request-response entre Flutter y FastAPI, frente a la alternativa de mensajería asíncrona, justificada contra la medida de Q-01. Sustenta A-01 y A-02. |
| [ADR-0005](../adr/0005-plataforma-despliegue-backend.md) | Selección de plataforma de despliegue del backend | *Aceptado* (2026-09-26) | Formaliza Render (Free Web Service), descrito en `render.yaml`, para el proceso del backend, sobre las alternativas servidor del laboratorio, Railway y Fly.io. Sustenta A-01 y A-04. |
| [ADR-0006](../adr/0006-plataforma-despliegue-frontend.md) | Selección de plataforma de despliegue del frontend | *Aceptado* (2026-09-26) | Formaliza GitHub Pages como hosting estático del build web de Flutter, sobre las alternativas Netlify y Vercel. Sustenta A-01. |
| [ADR-0007](../adr/0007-persistencia-render-postgres.md) | Estrategia de persistencia en el ambiente desplegado | *Aceptado* (2026-09-27) | Formaliza Render Postgres (Free) para la persistencia en el ambiente desplegado, sobre SQLite en disco efímero y disco persistente de pago; ajusta la consecuencia operativa de ADR-0003 solo para ese ambiente. Sustenta A-01 y A-04. |
| [ADR-0008](../adr/0008-verificacion-de-artefactos-sugeridos-por-ia.md) | Verificación obligatoria de artefactos de terceros sugeridos por IA antes de incorporarlos | *Aceptado* (2026-10-01) | A partir de un incidente real (un hash inventado por IA para una acción de GitHub que rompió el pipeline en S7), formaliza la práctica del equipo de verificar contra la fuente oficial todo identificador externo que una propuesta de IA incluya, antes de aceptarlo. Decisión de proceso, no de arquitectura del sistema. Sustenta A-01. |
| [ADR-0009](../adr/0009-no-incorporacion-componente-generativo.md) | No incorporación de un componente generativo al sistema desplegado | *Aceptado* (2026-10-01) | Evalúa y descarta usar un LLM para A-03 (alertas tempranas), tanto para redactar el texto como para decidir criticidad, por costo, no determinismo frente a Q-01, y riesgo de disponibilidad de un proveedor externo. El mecanismo de A-03 se resolverá con una regla determinista cuando tenga código. |
| [ADR-0010](../adr/0010-extraccion-de-modulo.md) | Decisión de extraer o no extraer un módulo del monolito | *Aceptado* (2026-10-18) | Evalúa extraer `requisitos/` como servicio y el job de alertas (A-03), frente a no extraer. Decide no extraer: la extracción crearía nuevos modos de fallo, rompería la transacción única de Q-01 y excede el límite de costo. Los fallos se mitigan en el borde cliente-servidor (arc42 §11.5). Sustenta A-01 y A-04. |
| [ADR-0011](../adr/0011-historial-de-cambios-transaccional.md) | Historial de cambios transaccional en la misma base de datos | *Aceptado* (2026-10-25) | Fija el mecanismo de A-08: una tabla de historial append-only por módulo dueño, en la misma base y misma transacción que el cambio, sobre log, triggers, event sourcing o cola. Argumenta por qué es la decisión de datos más costosa de revertir (el pasado no se reconstruye). Sustenta A-08 y A-01. |
| [ADR-0012](../adr/0012-despliegue-en-servidor-del-laboratorio.md) | Despliegue en el servidor del laboratorio | *Aceptado* (2026-10-25) | Registra el despliegue con Dokploy (`deploy/compose.lab.yaml`): API y Postgres en contenedores con volumen persistente. Complementa ADR-0005 y ADR-0007 sin reemplazarlos. Sustenta A-04 y A-01. |

---

## 9.2 Relación con los aspectos del sistema

| Aspecto | Decisión de la que depende | Estado de la decisión |
|---|---|---|
| [A-01](../aspectos.md#a-01--seguimiento-del-cumplimiento-de-requisitos) — Seguimiento del cumplimiento de requisitos | ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0008, ADR-0010 | Aceptado |
| [A-02](../aspectos.md#a-02--cálculo-correcto-del-estado-de-graduación) — Cálculo correcto del estado de graduación | ADR-0001, ADR-0002, ADR-0003, ADR-0004 | Aceptado |
| [A-03](../aspectos.md#a-03--alertas-tempranas-de-requisitos-pendientes) — Alertas tempranas | Pendiente de código; ADR-0009 descarta explícitamente un componente generativo para su mecanismo | Pendiente |
| [A-04](../aspectos.md#a-04--disponibilidad-del-sistema) — Disponibilidad del sistema | ADR-0001, ADR-0005, ADR-0007, ADR-0010 | Aceptado |
| [A-05](../aspectos.md#a-05--protección-y-control-de-acceso-a-la-información-académica) — Protección y control de acceso | ADR-0001, ADR-0002 | Aceptado (la implementación de `usuarios/` sigue pendiente; ver el riesgo correspondiente en `11-risks-and-technical-debt.md`) |
| [A-06](../aspectos.md#a-06--extensibilidad-para-múltiples-programas-académicos) — Extensibilidad para múltiples programas | ADR-0001, ADR-0003 | Aceptado |
| [A-07](../aspectos.md#a-07--gestión-de-solicitudes-de-estudiantes-en-el-centro-de-ayuda) — Gestión de solicitudes del centro de ayuda | ADR-0001 (módulo ayuda/) | Pendiente 
| [A-08](../aspectos.md#a-08--historial-de-cambios-sobre-la-información-académica) — Historial de cambios | ADR-0003 (motor transaccional), ADR-0011 (mecanismo) | Aceptado — implementado en `requisitos/`; falta el endpoint de consulta y extenderlo a otros módulos |

---

## 9.3 Criterio para futuras decisiones

Toda decisión que module la estructura del monolito, cambie una tecnología permitida por 02-architecture-constraints.md, afecte la forma de cumplir un escenario de calidad de 10-quality-requirements.md, cambie dónde corre una pieza del sistema desplegado, o modifique la práctica de verificación de artefactos de IA fijada en ADR-0008, será registrada como un nuevo ADR en `docs/adr/`.

Esto incluye, en particular, cualquier cambio futuro de motor de base de datos respecto a lo fijado en ADR-0003 (incluyendo su ajuste operativo en ADR-0007), el endpoint de consulta del historial y su extensión a otros módulos (mecanismo base fijado en ADR-0011), cualquier cambio del modelo síncrono de comunicación fijado en ADR-0004, un eventual ADR para el job programado que sostendría A-03 cuando ese aspecto tenga código (con una regla determinista, según ADR-0009), cualquier decisión futura de incorporar un componente generativo que revise lo descartado en ADR-0009, y la revisión de la decisión de no extraer módulos de ADR-0010 cuando se cumpla alguna de las condiciones de su sección 6.
