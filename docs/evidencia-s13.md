# Evidencia S13 · Modelado de amenazas y plan de mitigación

- Repositorio: [https://github.com/ISCOUTB/AS_202620_DinamikUTB](https://github.com/ISCOUTB/AS_202620_DinamikUTB)
- Despliegue de referencia: Servidor del laboratorio vía Dokploy ([ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md))
- Fecha de evaluación: Noviembre 2026

---

## Matriz de cumplimiento S13

| Criterio de evaluación | Evidencia técnica en el repositorio | Estado |
|---|---|---|
| **Tabla de amenazas anclada en elementos del C4 del equipo** | Sección 1 de este documento (elementos de `docs/c4/contenedores.puml`: `proxy`, `web_lab`, `backend_lab`, `database_lab`, `token_store`, `smtp`, `logs`) | **Cumple** |
| **Priorización por probabilidad e impacto** | Columnas de Probabilidad, Impacto y Nivel de Riesgo en la tabla STRIDE (ordenada de Crítica a Baja) | **Cumple** |
| **Mitigación asignada a cada amenaza, con dueño y estado** | Cada fila declara mitigación técnica, integrante responsable del equipo y estado verificable | **Cumple** |
| **El plan ataca primero lo priorizado** | Las amenazas P1 (Críticas) y P2 (Altas) cuentan con mitigación implementada y probada en el código | **Cumple** |
| **Análisis de dependencias ejecutado en el pipeline** | Workflow `.github/workflows/dependency-audit.yml` (`pip-audit`) y `.github/dependabot.yml` | **Cumple** |
| **Hallazgos del análisis revisados y decididos** | Sección 2 de este documento: resolución de PYSEC-2026-4320 en `certifi` (actualizado a `2026.10.18`) | **Cumple** |
| **Sección de privacidad con datos personales tratados y su base** | Sección 3 de este documento: inventario de datos y base legal bajo Ley 1581 de 2012 | **Cumple** |
| **Riesgos del componente generativo (si aplica)** | Sección 4 de este documento: análisis de inyección, fuga y envenenamiento; mitigados por diseño en [ADR-0009](adr/0009-no-incorporacion-componente-generativo.md) | **Cumple** |
| **arc42 sección 8 con arquitectura de seguridad** | `docs/arc42/08-cross-cutting-concepts.md`, sección 8.12 | **Cumple** |
| **arc42 sección 11 con amenazas aceptadas y motivo** | `docs/arc42/11-risks-and-technical-debt.md`, sección 11.1 y 11.2 | **Cumple** |
| **ADR de las mitigaciones estructurales** | [ADR-0013](adr/0013-controles-estructurales-de-seguridad-y-autenticacion.md) | **Cumple** |

---

## 1. Tabla de modelado de amenazas STRIDE sobre el C4

Las amenazas se modelan directamente sobre los contenedores y actores del diagrama de arquitectura **C4 Nivel 2** (`docs/c4/contenedores.puml`).

| ID | Categoría STRIDE | Elemento C4 afectado | Descripción de la amenaza | Prob. | Imp. | Prioridad | Mitigación asignada | Dueño | Estado |
|---|---|---|---|---|---|---|---|---|---|
| **T-01** | Spoofing | `estudiante` / `backend_lab` | Suplantación de identidad mediante credenciales robadas o tokens JWT falsificados. | Media | Crítico | **P1 (Crítica)** | Autenticación JWT HS256 firmada con `SECRET_KEY` de 48 bytes; hash Argon2id; invalidación inmediata ante cambio de clave con firma `sig` (`password_hash[-16:]`). | Juan José Vargas | **Implementada** (`backend/app/core/security.py`, `tests/test_auth.py`) |
| **T-02** | Tampering | `backend_lab` / `database_lab` | Inyección SQL en consultas o alteración no autorizada de registros académicos de grado. | Media | Crítico | **P1 (Crítica)** | Consultas parametrizadas mediante SQLAlchemy ORM; validación estricta de payloads con esquemas Pydantic v2; regex alfanumérico en código estudiantil. | Luis Daniel Padilla | **Implementada** (`backend/app/core/validation.py`, `tests/test_seguridad.py`) |
| **T-03** | Elevation of Privilege | `backend_lab` | Acceso indebido: estudiante consulta o altera requisitos de otros estudiantes, o invoca endpoints administrativos. | Alta | Crítico | **P1 (Crítica)** | Control de acceso basado en roles (RBAC) centralizado mediante dependencias FastAPI (`require_roles`) y función `verificar_acceso_estudiante`. | Gillianis Pérez | **Implementada** (`backend/app/usuarios/dependencies.py`, `tests/test_seguridad.py`) |
| **T-04** | Information Disclosure | `database_lab` / `backend_lab` | Filtración de contraseñas de usuarios en reposo o a través de respuestas de la API. | Baja | Crítico | **P1 (Crítica)** | Hashes unidireccionales Argon2id con salt aleatorio; esquema `UsuarioOut` y filtros de serialización que jamás exponen hashes, tokens ni bloqueos. | Esteban Ramírez | **Implementada** (`backend/app/usuarios/schemas.py`, `tests/test_auth.py`) |
| **T-05** | Denial of Service | `backend_lab` | Ataque de fuerza bruta masivo contra el endpoint `POST /auth/login` agotando recursos del servidor. | Alta | Alto | **P2 (Alta)** | Limitador de tasa en memoria por ventana deslizante (`LimitadorVentana`, 10 peticiones / 60 s por IP) y bloqueo temporal de cuenta tras 5 intentos fallidos consecutivos. | Juan José Vargas | **Implementada** (`backend/app/core/rate_limit.py`, `tests/test_auth.py`) |
| **T-06** | Repudiation | `backend_lab` / `database_lab` | Un coordinador modifica el estado de un requisito o un dato de estudiante y niega haberlo realizado. | Media | Alto | **P2 (Alta)** | Tablas de auditoría inmutables *append-only* (`requisitos_historial`, `estudiantes_historial`) registradas en la misma transacción atómica que el cambio. | Luis Daniel Padilla | **Implementada** ([ADR-0011](adr/0011-historial-de-cambios-transaccional.md), [ADR-0014](adr/0014-extension-historial-datos-estudiante.md)) |
| **T-07** | Tampering | `reportes` / Exportación CSV | Inyección de fórmulas maliciosas en campos de texto (CSV Formula Injection / CWE-1236) ejecutadas en el visor de la institución. | Media | Alto | **P2 (Alta)** | Sanitización de celdas anteprefijando comilla simple `'` si el contenido inicia con `=`, `+`, `-`, `@`, `\t` o `\r`. | Gillianis Pérez | **Implementada** (`backend/app/reportes/router.py`, `tests/test_account_management.py`) |
| **T-08** | Tampering / Exploitation | `backend_lab` (Dependencias) | Incorporación de dependencias de terceros vulnerables o comprometidas en la cadena de suministro. | Media | Alto | **P2 (Alta)** | Análisis continuo mediante `pip-audit` en GitHub Actions (`dependency-audit.yml`), escaneo de Dependabot y fijación de dependencias por hash. | Esteban Ramírez | **Implementada** (`.github/workflows/dependency-audit.yml`, [ADR-0008](adr/0008-verificacion-de-artefactos-sugeridos-por-ia.md)) |
| **T-09** | Information Disclosure | Red externa / `proxy` | Intercepción de tráfico HTTP en tránsito (man-in-the-middle) robando credenciales o información académica. | Media | Alto | **P2 (Alta)** | Cifrado obligatorio HTTPS/TLS gestionado en Traefik; cabecera HSTS forzada en producción (`Strict-Transport-Security: max-age=63072000`). | Juan José Vargas | **Implementada** ([ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md), `backend/app/main.py`) |
| **T-10** | Information Disclosure | `token_store` (Navegador) | Robo de token JWT alojado en el cliente web mediante ataques de Cross-Site Scripting (XSS). | Baja | Alto | **P3 (Media)** | Cabeceras de seguridad estrictas (`X-Content-Type-Options: nosniff`, `Content-Security-Policy: default-src 'none'`, `X-Frame-Options: DENY`); tokens de corta vigencia (30 min). | Gillianis Pérez | **Mitigada** (`backend/app/main.py`, `frontend/lib/core/storage/token_storage.dart`) |
| **T-11** | Denial of Service | `smtp` | Indisponibilidad del servidor de correo institucional bloquea la API durante la recuperación de claves. | Media | Medio | **P3 (Media)** | Tratamiento de correo saliente como mejor esfuerzo (desacoplado); si SMTP no responde, la API devuelve HTTP 503 claro sin degradar el resto del sistema. | Luis Daniel Padilla | **Aceptada como riesgo** (`backend/app/usuarios/router.py`, arc42 §11.1) |

---

## 2. Análisis de dependencias y gestión de vulnerabilidades

El repositorio cuenta con dos mecanismos automatizados de auditoría de seguridad sobre la cadena de suministro:

1. **Workflow de GitHub Actions:** `.github/workflows/dependency-audit.yml` ejecuta `pip-audit` semanalmente y ante cada *push* sobre `backend/requirements.txt`.
2. **Dependabot:** `.github/dependabot.yml` realiza escaneos semanales sobre los ecosistemas `pip` (backend), `pub` (frontend) y `github-actions`.

### Hallazgo real y resolución documentada

Durante la auditoría automatizada en el pipeline de la S13 se detectó la siguiente vulnerabilidad:

- **Paquete:** `certifi`
- **Versión vulnerable encontrada:** `2026.7.22`
- **Identificador de vulnerabilidad:** `PYSEC-2026-4320`
- **Impacto:** Posible afectación en la validación de certificados raíz en peticiones salientes.
- **Acción y decisión:** Se editó `backend/requirements.txt` fijando la versión segura `certifi==2026.10.18`. Se ejecutó `pip-audit` localmente y en el pipeline comprobando **0 vulnerabilidades activas**.

---

## 3. Privacidad y tratamiento de datos personales

DinamikUTB trata datos personales y académicos de la comunidad universitaria. Conforme a la **Ley Estatutaria 1581 de 2012** (Régimen General de Protección de Datos Personales en Colombia) y el Decreto 1377 de 2013, se formaliza la siguiente política:

### Inventario de datos personales tratados

| Dato personal | Categoría | Finalidad del tratamiento | Base jurídica |
|---|---|---|---|
| **Nombre completo** | Identificación | Personalización de la experiencia y visualización de perfil en certificaciones. | Relación contractual y educativa de matrícula. |
| **Correo institucional** | Identificación y contacto | Autenticación, control de sesiones y canal oficial de recuperación de acceso. | Cumplimiento reglamentario institucional. |
| **Código estudiantil** | Identificador académico | Vínculo unívoco con el plan de estudios y la historia curricular. | Misión educativa y validación académica. |
| **Programa y semestre** | Información académica | Filtrado de requisitos de grado aplicables y cálculo de avance hacia titulación. | Cumplimiento del plan de estudios y grado. |
| **Hash de contraseña** | Dato de seguridad sensible | Verificación criptográfica de identidad (nunca se almacena en texto plano). | Necesidad de seguridad y control de acceso. |
| **Historial de cambios** | Auditoría y trazabilidad | Registro inmutable de fecha, hora y responsable de modificaciones académicas. | Deber de debida diligencia y exactitud académica. |

### Garantías y derechos de los titulares (ARCO)

1. **Finalidad legítima:** Los datos se tratan exclusivamente para el seguimiento curricular y de requisitos de graduación en la Universidad Tecnológica de Bolívar. No se ceden a terceros ni se emplean con fines comerciales.
2. **Acceso y Rectificación:** El estudiante puede consultar permanentemente su información académica (`GET /auth/me`, `GET /requisitos/{id}`) y reportar inconsistencias para su debida corrección a través del coordinador académico.
3. **Seguridad y confidencialidad:** Las comunicaciones externas están cifradas mediante TLS; la base de datos corre en red aislada y las contraseñas se almacenan mediante hashes irreversibles Argon2id.

---

## 4. Análisis de riesgos sobre componentes generativos

En conformidad con el [ADR-0009](adr/0009-no-incorporacion-componente-generativo.md), **DinamikUTB no incorpora ningún componente generativo en tiempo de ejecución**.

A continuación se modelan los tres riesgos estándar exigidos por la guía y cómo la arquitectura los mitiga de forma estructural:

1. **Inyección de prompt (Prompt Injection):**  
   - *Riesgo:* Un estudiante introduce texto malicioso en campos de solicitud de ayuda o nombres buscando manipular un modelo de lenguaje para alterar estados de grado.  
   - *Mitigación:* Al no existir modelos de lenguaje evaluando reglas académicas, no hay superficie de ataque para inyecciones de prompt. Las validaciones son lógicas deterministas respaldadas por código Python y esquemas Pydantic.
2. **Fuga de datos personales y académicos (Data Exfiltration):**  
   - *Riesgo:* Exposición de notas, códigos o correos de estudiantes enviados a APIs de proveedores externos de IA (OpenAI, Anthropic, etc.) durante consultas en tiempo real.  
   - *Mitigación:* Todos los datos se almacenan y procesan de forma local y soberana en el servidor del laboratorio. Ninguna información académica sale de la infraestructura de la universidad hacia servicios de terceros.
3. **Envenenamiento del contexto (Context Poisoning):**  
   - *Riesgo:* Inconsistencias o datos falsos inyectados en el contexto de inferencia que induzcan al sistema a certificar como cumplido un requisito pendiente.  
   - *Mitigación:* El cálculo de avance hacia el grado ([A-02](aspectos.md#a-02--cálculo-correcto-del-estado-de-graduación) / [Q-01](arc42/10-quality-requirements.md)) es estrictamente matemático y relacional en la base de datos (`COUNT` y `SUM` en SQL), garantizando determinismo absoluto.

---

## 5. Auditoría de secretos y credenciales

Se repitió el barrido de escaneo estricto de secretos sobre el árbol del repositorio:

```bash
git grep -nIE '(AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY|ghp_[A-Za-z0-9]{36}|xox[baprs]-|sk-[A-Za-z0-9]{20,})' HEAD
