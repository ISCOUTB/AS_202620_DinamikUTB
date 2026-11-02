# 11. Risks and Technical Debt

Esta sección registra los riesgos y modos de fallo conocidos de **DinamikUTB**.

---

## 11.1 Modos de fallo de la integración principal

| ID | Modo de fallo | Qué pasa hoy | Mitigación asignada | Estado | Prueba |
|---|---|---|---|---|---|
| F1 | **No responde** (backend caído o sin conexión) | El cliente recibe un error de conexión. | Timeout de 25 s por intento y hasta 3 intentos con espera creciente (2 s, 4 s). Si se agotan, la UI muestra mensaje claro. | **Probada** | `requisitos_service_test.dart` |
| F2 | **Responde tarde** (latencia de red) | La consulta tarda más de lo previsto. | Timeout por intento corta esperas colgadas y reintenta. UI muestra indicador de carga. | **Probada** | `requisitos_service_test.dart` |
| F3 | **Base de datos no disponible** | `GET /health` responde 503. `pool_pre_ping` descarta conexiones caídas. | Endpoint `/health` con `SELECT 1` para orquestadores y reintento en el cliente ante 5xx. | **Probada** | `test_health.py` |
| F4 | **Petición duplicada** (reintento del cliente, doble clic) | `PUT` fija valor absoluto idempotente. | Semántica de asignación fija. Repetir la solicitud deja exactamente el mismo estado y no duplica filas de historial. | **Probada** | `test_idempotencia.py` |
| F5 | **Respuesta perdida tras aplicar cambio** | El cliente no sabe si se aplicó. | Reintentar es seguro por idempotencia. | **Probada** | `test_idempotencia.py` |
| F6 | **Escrituras concurrentes en conflicto** | Dos peticiones simultáneas modifican la misma fila en PostgreSQL. | `with_for_update=True` serializa las consultas a nivel de fila antes de leer el valor anterior. | **Mitigado para el historial; sin prueba concurrente automatizada** | `test_idempotencia.py` (secuencial) |
| F7 | **Expiración de la base de datos de Render** | La base de datos gratuita de Render expiró a los 30 días (27/10/2026). | **Ocurrido:** Según lo planificado en ADR-0012, el ambiente de Render fue retirado y el despliegue principal se consolidó definitivamente en el servidor del laboratorio con volumen Docker persistente `pgdata` sin expiración. | **Resuelto operativamente** | Verificación en `https://dinamikutb.iscoutb.dev/health` |

---

## 11.2 Diseño de idempotencia

- `PUT /requisitos/{id}/estado` fija un valor absoluto (`cumplido`, `pendiente`, `en_proceso`).
- La función `actualizar_estado_requisito` comprueba si `anterior == nuevo_estado`; si son iguales, no genera ninguna fila en `requisitos_historial`.
- Por qué no hay saga: cada mutación opera sobre una única base de datos relacional dentro de un bloque `db.commit()` atómico; no hay servicios distribuidos externos que requieran compensación.
