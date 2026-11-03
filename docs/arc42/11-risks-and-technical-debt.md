# 11. Risks and Technical Debt

Esta sección registra los riesgos y modos de fallo conocidos de **DinamikUTB**, así como las amenazas de seguridad aceptadas de forma consciente por el equipo de arquitectura.

---

## 11.1 Amenazas de seguridad aceptadas

Conforme al modelado de amenazas documentado en [`docs/evidencia-s13.md`](../evidencia-s13.md), el equipo acepta los siguientes riesgos residuales para el entorno de desarrollo y laboratorio institucional:

| ID | Amenaza aceptada | Motivo técnico de la aceptación | Condición que obligaría a revisarla |
|---|---|---|---|
| **T-ACC-01** | Almacenamiento de token JWT en cliente web (`token_store`) | En navegadores, `flutter_secure_storage` persiste el token de acceso en web storage. El riesgo de acceso por XSS se mitiga mediante cabeceras CSP estrictas, ausencia de inyecciones HTML en Flutter y tokens de corta vigencia (30 min). | Manejo de transacciones financieras o requerimiento institucional de cookies `HttpOnly` con proxy de backend. |
| **T-ACC-02** | Limitador de tasa en memoria volátil | El componente `LimitadorVentana` corre en la memoria del proceso FastAPI. Si el contenedor se reinicia, los contadores de intentos por IP se reinician. Es suficiente para proteger contra ataques de fuerza bruta comunes en el laboratorio. | Despliegue con múltiples réplicas detrás de balanceador de carga; requeriría Redis. |
| **T-ACC-03** | Servicio SMTP bajo mejor esfuerzo (sin cola persistente) | El envío de correos salientes para recuperación de contraseña responde HTTP 503 si el servidor SMTP falla, sin encolar reintentos en un broker para evitar añadir RabbitMQ o Kafka. | Volúmenes de matrícula masivos donde la pérdida de una notificación requiera reintentos asíncronos garantizados. |
| **T-ACC-04** | Exposición de `/docs` y `/openapi.json` en desarrollo | La documentación interactiva permanece visible únicamente en entornos locales y de pruebas (`APP_ENV=development`). En producción se desactiva explícitamente (`docs_url=None`). | Nunca exponer en producción. |

---

## 11.2 Modos de fallo de la integración principal

| ID | Modo de fallo | Comportamiento | Mitigación asignada | Estado | Prueba |
|---|---|---|---|---|---|
| **F1** | Backend no responde | El cliente recibe error de conexión. | Timeout de 25 s por intento y hasta 3 intentos con retroceso exponencial (2 s, 4 s). Mensaje claro en UI. | **Probada** | `requisitos_service_test.dart` |
| **F2** | Respuesta tardía de red | Consulta supera latencia normal. | Timeout corta llamadas colgadas y reintenta. Indicador de carga en UI. | **Probada** | `requisitos_service_test.dart` |
| **F3** | Base de datos no disponible | `GET /health` responde 503. | `pool_pre_ping=True` descarta conexiones caídas y orquestador monitorea salud. | **Probada** | `test_health.py` |
| **F4** | Petición de escritura duplicada | Red o usuario reenvía `PUT`. | Semántica idempotente de valor absoluto; no genera filas duplicadas en historial. | **Probada** | `test_idempotencia.py` |
| **F5** | Escrituras concurrentes en conflicto | Modificaciones simultáneas sobre la misma fila. | `with_for_update=True` serializa transacciones a nivel de fila en PostgreSQL. | **Mitigada** | `test_idempotencia.py` |
| **F6** | Expiración de base de datos en nube gratuita | Render expiró a los 30 días. | Consolidación definitiva en servidor de laboratorio Dokploy con volumen `pgdata`. | **Resuelta** | [ADR-0012](../adr/0012-despliegue-en-servidor-del-laboratorio.md) |

---

## 11.3 Deuda técnica reconocida

| Ítem | Impacto | Estado | Justificación y plan |
|---|---|---|---|
| Tarea de respaldo automático del volumen `pgdata` | Disponibilidad ante desastre | Pendiente | El volumen Docker persiste entre reinicios, pero se debe programar un cron con `pg_dump` antes del paso a producción institucional. |
| Cobertura concurrente automatizada en CI | Concurrencia | Mitigada | El bloqueo `with_for_update=True` está probado secuencialmente en SQLite; su comportamiento concurrente real se apoya en el motor PostgreSQL en laboratorio. |
