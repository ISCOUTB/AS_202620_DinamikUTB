---
id: ADR-0007
title: Estrategia de persistencia en el ambiente desplegado
status: Aceptado
date: 2026-09-27
deciders: Equipo de arquitectura DinamikUTB
---

# ADR-0007: Estrategia de persistencia en el ambiente desplegado

Separa de [ADR-0005](0005-plataforma-despliegue-backend.md) (dónde corre el proceso del backend)
la decisión de **dónde y cómo persisten los datos**.

## 1. Contexto
Los servicios gratuitos de Render tienen filesystem efímero: un archivo SQLite se pierde en cada
redeploy, reinicio o spin down. Eso viola la medida de Q-01 sin que el código tenga error.

## 2. Alternativas
| Alternativa | Ventajas | Desventajas | Resultado |
|---|---|---|---|
| SQLite en disco del web service gratuito | Cero cambios (ADR-0003) | Pierde los datos en cada reinicio | Descartada |
| Disco persistente de Render + SQLite | Conserva SQLite | Requiere plan de pago (implica tarjeta), fuera de la restricción de costo cero | Descartada |
| **Render Postgres (Free)** | Persiste, sin tarjeta, encaja con SQLAlchemy (ADR-0003) | 1 GB; **expira a los 30 días** (+14 de gracia) | **Seleccionada** |

Capa gratuita verificada en la documentación de Render el `<completar fecha>`.

## 3. Decisión
Render Postgres (Free) en el ambiente desplegado; SQLite sigue en desarrollo local. La conexión se
toma de la variable `DATABASE_URL` (`backend/app/core/database.py`, `render.yaml`).

## 4. Consecuencias
- Positivas: datos persistentes; migración aislada por SQLAlchemy.
- Negativas: recreación/resiembra antes del día 25 (ver `arc42/11`); divergencia SQLite/Postgres entre ambientes.

## 5. Trazabilidad
| Elemento | Referencia |
|---|---|
| Aspectos | A-01, A-04 |
| Escenarios | Q-01 (principal), Q-05 |
| Código | `backend/app/core/database.py`, `render.yaml` |
| Pruebas | `backend/tests/test_health.py` (`/health` hace `SELECT 1`) |
