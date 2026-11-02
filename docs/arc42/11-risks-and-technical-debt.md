# 11. Risks and Technical Debt

Esta sección registra los riesgos de seguridad que el equipo **acepta de forma explícita** y la deuda técnica relevante. Las amenazas completas y su priorización están en [`docs/modelado-de-amenazas.md`](../modelado-de-amenazas.md).

## 11.1 Amenazas aceptadas

| ID | Amenaza | Motivo de la aceptación | Condición que obliga a revisarla |
|---|---|---|---|
| T-04 | Tráfico HTTP sin TLS entre Frontend y Backend | El sistema se ejecuta solo en local (`127.0.0.1`, `start.bat`) sin exposición de red; no hay entorno productivo (Q-05). | Cualquier despliegue accesible desde una red: se vuelve obligatorio HTTPS. |
| T-09 | Denegación de servicio por ausencia de límite de tasa y escritor único en SQLite | Prototipo académico con pocos usuarios; el riesgo ya se documentó en [ADR-0003](../adr/0003-seleccion-motor-de-base-de-datos.md) y Q-05. | Despliegue institucional o más de un coordinador escribiendo en simultáneo. |
| T-12 | Documentación `/docs` y `/openapi.json` expuesta | Facilita la verificación del equipo y de los evaluadores. | Despliegue real: deshabilitarla. |

Estas aceptaciones aplican **solo al entorno de desarrollo del curso**. No se aceptan T-01, T-02 ni T-03: siguen abiertas y tienen mitigación asignada en [ADR-0004](../adr/0004-autenticacion-y-control-de-acceso.md).

## 11.2 Deuda técnica

| Deuda | Impacto | Estado |
|---|---|---|
| Endpoints sin autenticación ni autorización (`usuarios/` sin código) | Alto: T-01, T-02 | Pendiente (ADR-0004) |
| CORS abierto (`allow_origins=["*"]`) | Medio: T-07 | Pendiente |
| Dependencia `certifi` con vulnerabilidad conocida; `httpx2`/`httpcore2` sin justificar | Medio: T-08 | En curso |
| Historial de cambios (A-08) sin mecanismo decidido | Medio: T-06 | Pendiente (ADR-0005 por redactar) |
| `*.db` sin verificar en `.gitignore` | Medio: T-05 | Pendiente de verificar |
| Cálculo de avance (A-02) y alertas (A-03) sin implementar | Funcional, no de seguridad | Pendiente |

