# Modelo de amenazas y plan de mitigación — DinamikUTB (S13)

> **Commit evaluado:** `<hash>` · **Fecha de cierre:** `<fecha>` (completar al hacer el commit final)
> **Método:** STRIDE aplicado a los elementos y flujos de [C4 Nivel 2](c4/contenedores.puml) (Frontend Flutter, Backend API, Base de datos SQLite, y los flujos `HTTP/JSON` y `SQLAlchemy`), con actores de [C4 Nivel 1](c4/contexto.puml).
> **Estado real del sistema al evaluar:** solo existen los módulos `requisitos/` y `estudiantes/`. `usuarios/` (autenticación) **no tiene código**, y ningún endpoint exige token (ver `docs/arc42/06-runtime-view.md`, nota de estado).

## 1. Escala de priorización

Probabilidad (P) e Impacto (I) en escala 1 (baja) a 3 (alta). **Prioridad = P × I.** El orden de trabajo sigue la prioridad descendente.

## 2. Tabla de amenazas (ordenada por prioridad)

| ID | STRIDE | Elemento C4 afectado | Amenaza (evidencia en el código) | P | I | Prio. | Mitigación asignada | Dueño (propuesto) | Estado |
|---|---|---|---|---|---|---|---|---|---|
| T-01 | Elevación de privilegios / Manipulación | Backend API (`requisitos/router.py`) | `PUT /requisitos/{id}/estado` no exige autenticación ni rol: cualquiera puede marcar un requisito como `cumplido`, lo que viola Q-01 y la regla "el estudiante no modifica su información" (`02-architecture-constraints.md`). | 3 | 3 | **9** | Dependencia de autenticación + autorización por rol (coordinador/administrador) en el endpoint, con pruebas 401/403 ([ADR-0004](adr/0004-autenticacion-y-control-de-acceso.md)). | Luis Daniel Padilla | **Pendiente** |
| T-02 | Divulgación de información | Backend API (`GET /requisitos/{estudiante_id}`, `GET /estudiantes/{codigo}`) | Cualquier cliente puede consultar datos de cualquier estudiante cambiando el código en la URL (IDOR); los códigos tienen formato predecible (`T000123456`). Contradice Q-02. | 3 | 3 | **9** | Comparar `sub` del token con el recurso solicitado (403/404 si no coincide); coordinador limitado a su programa ([ADR-0004](adr/0004-autenticacion-y-control-de-acceso.md)). | Luis Daniel Padilla | **Pendiente** |
| T-03 | Suplantación | Backend API / Frontend (módulo `usuarios/`, sin código) | No hay autenticación: no existe identidad verificable. Al implementarla, un almacenamiento débil de contraseñas permitiría suplantación. | 2 | 3 | **6** | Hash con algoritmo adaptativo (argon2/bcrypt), tokens con expiración corta, secreto de firma en variable de entorno, nunca en el repositorio ([ADR-0004](adr/0004-autenticacion-y-control-de-acceso.md)). | Esteban Ramírez | **Pendiente** |
| T-04 | Divulgación / Manipulación | Flujo Frontend → Backend (`HTTP/JSON`) | El tráfico viaja por HTTP sin cifrar (`http://127.0.0.1:8000` en `main.dart`); en un despliegue real expondría credenciales y datos académicos. | 2 | 3 | **6** | Terminación TLS (HTTPS) en el despliegue; en desarrollo local sin exposición de red se acepta (ver sección 11 de arc42). | Juan José Vargas | **Aceptado en desarrollo** / pendiente al desplegar |
| T-05 | Divulgación de información | Base de datos (SQLite `dinamikutb.db`, `test_dinamikutb.db`) | El archivo `.db` está sin cifrar en disco y podría versionarse por error en el repositorio público. | 2 | 3 | **6** | Verificar `*.db` en `.gitignore`; permisos mínimos del archivo; datos de `seed.py` solo ficticios. | Gillianis Pérez | **Pendiente** (verificar `.gitignore`) |
| T-06 | Repudio | Backend API / Base de datos (A-08) | No existe historial de modificaciones: no se puede demostrar quién cambió un requisito (Q-08). | 2 | 2 | **4** | Tabla de historial transversal; requiere ADR propio (ADR-0005, pendiente). | Gillianis Pérez | **Pendiente** |
| T-07 | Divulgación de información | Backend API (`main.py`, CORS) | `allow_origins=["*"]` permite que cualquier sitio web consuma la API desde el navegador del usuario. | 2 | 2 | **4** | Restringir a los orígenes del frontend mediante variable de entorno. Cambio de una línea. | Juan José Vargas | **Pendiente** |
| T-08 | Manipulación (cadena de suministro) | Backend API (`requirements.txt`) | `certifi==2026.7.22` con vulnerabilidad PYSEC-2026-4320; `httpx2`/`httpcore2` sin metadatos verificables (ver sección 4). | 2 | 2 | **4** | Subir `certifi` a 2026.10.18; revisar y retirar `httpx2`/`httpcore2`; `pip-audit` en CI + Dependabot. | Esteban Ramírez | **En curso** (workflow creado, pin pendiente de merge) |
| T-09 | Denegación de servicio | Backend API / Base de datos | Sin límite de tasa; SQLite admite un solo escritor, por lo que ráfagas de `PUT` degradan la disponibilidad (riesgo ya documentado en ADR-0003 y Q-05). | 2 | 2 | **4** | Límite de tasa en producción; revisar motor si hay despliegue institucional. | Juan José Vargas | **Aceptado** (prototipo académico) |
| T-10 | Manipulación | Backend API → Base de datos (SQLAlchemy) | Inyección SQL y estados inválidos en el endpoint de actualización. | 1 | 3 | **3** | Consultas parametrizadas por el ORM y `Literal["cumplido","pendiente","en_proceso"]` en Pydantic; prueba de 422 existente en `test_requisitos.py`. | Luis Daniel Padilla | **Hecho** |
| T-11 | Divulgación de información | Frontend Flutter (futuro manejo de token) | Al implementar el login, guardar el token en almacenamiento accesible a scripts de la versión web facilitaría su robo por XSS. | 1 | 2 | **2** | Guardar el token en memoria o almacenamiento seguro; no registrarlo en logs. | Esteban Ramírez | **Pendiente** (depende de T-03) |
| T-12 | Divulgación de información | Backend API (`/docs`, `/openapi.json`) | La documentación interactiva expone la estructura completa de la API. | 2 | 1 | **2** | Deshabilitarla en despliegue real; útil en desarrollo. | Juan José Vargas | **Aceptado en desarrollo** |

> Los dueños son una propuesta del agente: el equipo debe confirmarlos o cambiarlos antes de la entrega.

## 3. Correspondencia entre prioridad y plan de trabajo

| Orden de ataque | Amenazas | Justificación |
|---|---|---|
| 1.º | T-01, T-02 (prio. 9) | Rompen Q-01 y Q-02, las dos metas de calidad de mayor prioridad. Ambas se cierran con la misma pieza: ADR-0004. |
| 2.º | T-03 (prio. 6) | Base del punto anterior; se implementa junto con él. |
| 3.º | T-04, T-05 (prio. 6) | T-05 es barata (revisión de `.gitignore`); T-04 depende del despliegue. |
| 4.º | T-06 a T-09 (prio. 4) | T-07 y T-08 son cambios mínimos y se pueden hacer en paralelo por costo bajo. |
| 5.º | T-10 a T-12 | Ya resueltas o aceptadas. |

Hasta que T-01 y T-02 estén fusionados con pruebas, el plan **no puede declararse cumplido**.

## 4. Análisis de dependencias

**Herramienta:** `pip-audit` (backend), ejecutado en [`.github/workflows/dependency-audit.yml`](../.github/workflows/dependency-audit.yml) en cada push, pull request y semanalmente. Dependabot cubre `pip`, `pub` (Flutter) y `github-actions` ([`.github/dependabot.yml`](../.github/dependabot.yml)). El análisis estático del código (pipeline del segundo corte) es independiente de este.

**URL del run en verde/rojo:** `<completar tras el primer run>`

| Hallazgo | Fuente | Decisión |
|---|---|---|
| `certifi 2026.7.22` — PYSEC-2026-4320 (corrección: 2026.10.18) | `pip-audit -r backend/requirements.txt` | **Actualizar** a `certifi==2026.10.18`. Hacerlo antes de activar el workflow para que el primer run quede en verde. |
| `httpx2==2.12.0` y `httpcore2==2.12.0` presentes junto a `httpx` y `httpcore` | Revisión manual de `requirements.txt` y PyPI | Existen en PyPI (última 2.16.0), pero sin autor ni sitio en sus metadatos y duplican funciones de `httpx`/`httpcore`. **Revisar:** confirmar con `pytest` si son necesarios y retirarlos si no. Si se conservan, justificar en este documento. |
| `truststore`, `colorama` | Revisión manual | Sin hallazgos; `colorama` es solo para Windows (`start.bat`). |
| Dependencias de Flutter (`pubspec.lock`) | `pip-audit` no cubre `pub` | Cubiertas por Dependabot (`pub`); revisar sus PRs. Sin hallazgos conocidos al momento de redactar. |

## 5. Privacidad: datos personales y base de tratamiento

**Contraste con el modelo de datos** (`backend/app/estudiantes/models.py`, `backend/app/requisitos/models.py`):

| Dato | Dónde | ¿Personal? | Estado |
|---|---|---|---|
| `codigo_estudiantil` | `Estudiante`, `Requisito.estudiante_id` | Sí: identifica a una persona | Implementado |
| `nombre` | `Estudiante` | Sí | Implementado |
| `programa` | `Estudiante` | Sí, combinado con el nombre | Implementado |
| Estado de cada requisito | `Requisito` | Sí: información académica asociada a un identificable | Implementado |
| Correo y contraseña (hash) | Cuentas del sistema (`01-introduction-and-goals.md` §1.5) | Sí | Planificado (`usuarios/`) |
| Autor y fecha de cada cambio | Historial (A-08) | Sí (coordinadores/administradores) | Planificado |
| Texto de solicitudes | `ayuda/` | Puede contener datos personales | Planificado |

**No se tratan:** documento de identidad, teléfono, dirección ni datos sensibles (salud, origen, etc.). Verificar con:

```bash
git grep -nIE '(email|correo|telefono|teléfono|cedula|cédula|documento|direccion|dirección|nombre_completo)' HEAD -- . ':!docs' | head -20
```

**Marco y base de tratamiento (propuesta a validar):** Ley 1581 de 2012 y Decreto 1377 de 2013 (compilado en el Decreto 1074 de 2015). Base propuesta: **autorización previa, expresa e informada del titular** para el tratamiento de sus datos académicos, con finalidad limitada al seguimiento de requisitos de grado. Principios aplicados: finalidad (solo seguimiento de graduación), minimización (sin datos de contacto ni sensibles), seguridad (T-01 a T-05) y acceso restringido (Q-02). Como el sistema es un prototipo académico sin integración institucional (`02-architecture-constraints.md` §2.3), la base legal definitiva de una implementación real debe validarla la UTB. Este documento no es asesoría jurídica.

**Datos del repositorio:** `seed.py` usa únicamente el código ficticio `T000123456`. No deben cargarse datos reales de estudiantes en el repositorio público.

## 6. Riesgos del componente generativo

DinamikUTB **no incorpora ningún componente generativo** (ni LLM, ni asistente en el centro de ayuda). Por tanto, la inyección de aviso, la fuga de datos y el envenenamiento del contexto no aplican. Si en el futuro se añade un asistente, deberá modelarse antes con un nuevo ADR.

## 7. Secretos

Se revisaron los archivos del repositorio disponibles para este análisis (código, configuración y documentación): **no se encontró ninguna credencial**. La URL de base de datos (`sqlite:///./dinamikutb.db`) y los datos de `seed.py` no contienen secretos. No se pudo examinar el historial de Git ni los archivos del `.github/workflows/ci.yml` actual desde aquí: **el equipo debe repetir el barrido del contrato sobre el historial completo** (por ejemplo, con `gitleaks detect`) antes de cerrar.

## 8. Matriz de cumplimiento (autoevaluación honesta)

| Criterio | Evidencia | Estado esperado tras el commit |
|---|---|---|
| Tabla anclada en el C4 | Sección 2 | Cumple |
| Priorización P × I | Secciones 1 y 2 | Cumple |
| Mitigación con dueño y estado | Sección 2 (dueños por confirmar) | Cumple |
| El plan ataca primero lo priorizado | Sección 3; T-01/T-02 siguen pendientes en código | **No cumple hasta fusionar ADR-0004 con pruebas** |
| Análisis de dependencias en el pipeline | Workflow creado | **No cumple hasta que exista un run con su URL** |
| Hallazgos revisados y decididos | Sección 4 | Cumple |
| Privacidad | Sección 5 | Cumple |
| Componente generativo | Sección 6 (no aplica) | Cumple |
| arc42 §8 | `docs/arc42/08-cross-cutting-concepts.md` §8.8 | Cumple |
| arc42 §11 | `docs/arc42/11-risks-and-technical-debt.md` | Cumple |
| ADR de mitigaciones estructurales | ADR-0004 (marcar **Aceptado** tras revisión del equipo) | Cumple |

Recuento proyectado: **9 de 11** hoy; **11 de 11** si se fusionan T-01/T-02 y se obtiene un run del workflow.
