
# 9. Architecture Decisions

Esta sección funciona como índice de las decisiones arquitectónicas (ADR) de DinamikUTB. Cada ADR completo se documenta en `docs/adr/`; aquí se resume su alcance y se deja constancia de las decisiones que todavía no se han formalizado, para que la trazabilidad de `docs/aspectos.md` sea verificable en un solo lugar.

---

## 9.1 Índice de decisiones

| ID | Título | Estado | Resumen |
|---|---|---|---|
| [ADR-0001](../adr/0001-seleccion-monolito-modular.md) | Selección de monolito modular como modelo arquitectónico | **Aceptado** (2026-08-23) | Define la estrategia arquitectónica base: una sola aplicación desplegable, dividida internamente en los módulos `core`, `usuarios`, `estudiantes`, `requisitos`, `programas` y `ayuda`. Sustenta A-01, A-02, A-04, A-05, A-06 y A-07. |

---

## 9.2 Relación con los aspectos del sistema

| Aspecto | Decisión de la que depende | Estado de la decisión |
|---|---|---|
| [A-01](../aspectos.md/#a-01---seguimiento-del-cumplimiento-de-requisitos) — Seguimiento del cumplimiento de requisitos | ADR-0001 | Aceptado |
| [A-02](../aspectos.md/#a-02---calculo-correcto-del-estado-de-graduacion) — Cálculo correcto del estado de graduación | ADR-0001 | Aceptado |
| [A-03](../aspectos.md/#a-03---alertas-tempranas-de-requisitos-pendientes) — Alertas tempranas | Pendiente | Pendiente |
| [A-04](../aspectos.md/#a-04---disponibilidad-del-sistema) — Disponibilidad del sistema | ADR-0001 | Aceptado |
| [A-05](../aspectos.md/#a-05---proteccion-y-control-de-acceso-a-la-informacion-academica) — Protección y control de acceso | ADR-0001 | Aceptado |
| [A-06](../aspectos.md/#a-06---extensibilidad-para-multiples-programas-academicos) — Extensibilidad para múltiples programas | ADR-0001 | Aceptado |
| [A-07](../aspectos.md/#a-07---gestion-de-solicitudes-de-estudiantes-en-el-centro-de-ayuda) — Gestión de solicitudes del centro de ayuda | ADR-0001 (módulo `ayuda/`) | Pendiente |
| [A-08](../aspectos.md/#a-08---historial-de-cambios-sobre-la-informacion-academica) — Historial de cambios | Pendiente | Pendiente |

---

## 9.3 Criterio para futuras decisiones

Toda decisión que module la estructura del monolito, cambie una tecnología permitida por `02-architecture-constraints.md`, o afecte la forma de cumplir un escenario de calidad de `10-quality-requirements.md`, será registrada como un nuevo ADR en `docs/adr/`.

---