
# Aspect Driven Development

> Este documento registra los aspectos del sistema que requieren trazabilidad desde el requisito hasta su evidencia de calidad en el proyecto **DinamikUTB**.

---

# Aspectos planteados

| ID | Aspecto | Requisito | Escenario de calidad | C4 | ADR | Código | Pruebas | Evidencia |
|---|---|---|---|---|---|---|---|---|
| A-01 | Seguimiento del cumplimiento de requisitos | RF-01 | [Q-01](arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica), [Q-03](arc42/10-quality-requirements.md#escenario-q-03--facilidad-de-comprensión-de-la-información) | [C4 Nivel 2](c4/contenedores.puml) (contenedores Backend API y Base de datos) | [ADR-0001](adr/0001-seleccion-monolito-modular.md), [ADR-0002](adr/0002-seleccion-tecnologia-backend-frontend.md), [ADR-0003](adr/0003-seleccion-motor-de-base-de-datos.md), [ADR-0005](adr/0005-plataforma-despliegue-backend.md), [ADR-0006](adr/0006-plataforma-despliegue-frontend.md), [ADR-0007](adr/0007-persistencia-render-postgres.md), [ADR-0008](adr/0008-verificacion-de-artefactos-sugeridos-por-ia.md), [ADR-0010](adr/0010-extraccion-de-modulo.md), [ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md) | [router.py](../backend/app/requisitos/router.py), [service.py](../backend/app/requisitos/service.py), [models.py](../backend/app/requisitos/models.py), [schemas.py](../backend/app/requisitos/schemas.py), [requisitos_service.dart](../frontend/lib/requisitos/requisitos_service.dart) | [test_requisitos.py](../backend/tests/test_requisitos.py), [test_contrato.py](../backend/tests/test_contrato.py), [test_idempotencia.py](../backend/tests/test_idempotencia.py), [widget_test.dart](../frontend/test/widget_test.dart), [requisitos_service_test.dart](../frontend/test/requisitos_service_test.dart) — [run en verde](https://github.com/ISCOUTB/AS_202620_DinamikUTB/actions/runs/33475979818) | [docs/evidencia-s9.md](evidencia-s9.md): generación verificada con apoyo de IA, incidente de hash corregido (ADR-0008), medición contra Q-01 |
| A-02 | Cálculo correcto del estado de graduación | RF-02 | [Q-01](arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica) | [C4 Nivel 2](c4/contenedores.puml) | [ADR-0001](adr/0001-seleccion-monolito-modular.md), [ADR-0002](adr/0002-seleccion-tecnologia-backend-frontend.md), [ADR-0003](adr/0003-seleccion-motor-de-base-de-datos.md), [ADR-0015](adr/0015-progreso-curricular-por-estudiante.md) | [progreso.py](../backend/app/curriculo/progreso.py), [service.py](../backend/app/requisitos/service.py) | [test_progreso.py](../backend/tests/test_progreso.py) | Cálculo de créditos, promedio y elegibilidad en backend; `GET /malla/progreso` y `/requisitos/{id}/resumen` |
| A-03 | Alertas tempranas de requisitos pendientes | RF-03 | [Q-04](arc42/10-quality-requirements.md#escenario-q-04--alertas-tempranas-de-requisitos-pendientes) | Pendiente | [ADR-0009](adr/0009-no-incorporacion-componente-generativo.md) (descarta un componente generativo; el mecanismo de disparo sigue sin decidir) | Pendiente | Pendiente | Pendiente |
| A-04 | Disponibilidad del sistema | RF-04 | [Q-05](arc42/10-quality-requirements.md#escenario-q-05--disponibilidad-del-sistema) | [C4 Nivel 2](c4/contenedores.puml) y [vista de despliegue](arc42/07-deployment-view.md) | [ADR-0001](adr/0001-seleccion-monolito-modular.md), [ADR-0005](adr/0005-plataforma-despliegue-backend.md), [ADR-0007](adr/0007-persistencia-render-postgres.md), [ADR-0010](adr/0010-extraccion-de-modulo.md), [ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md) | [main.py](../backend/app/main.py) (`/health`, `/metrics`, logging JSON), [metrics.py](../backend/app/core/metrics.py), [compose.lab.yaml](../deploy/compose.lab.yaml), [requisitos_service.dart](../frontend/lib/requisitos/requisitos_service.dart) (timeout y reintento) | [test_health.py](../backend/tests/test_health.py), [test_idempotencia.py](../backend/tests/test_idempotencia.py), [requisitos_service_test.dart](../frontend/test/requisitos_service_test.dart) | [README, sección «Entorno desplegado»](../README.md#entorno-desplegado) (comprobación externa con `/health` en HTTP 200), [docs/costos.md](costos.md), [modos de fallo y riesgos](arc42/11-risks-and-technical-debt.md) |
| A-05 | Protección y control de acceso a la información académica | RF-05 | [Q-02](arc42/10-quality-requirements.md#escenario-q-02--seguridad-y-aislamiento-de-la-información) | [C4 Nivel 2](c4/contenedores.puml) | [ADR-0001](adr/0001-seleccion-monolito-modular.md), [ADR-0002](adr/0002-seleccion-tecnologia-backend-frontend.md), [ADR-0013](adr/0013-controles-estructurales-de-seguridad-y-autenticacion.md) | [security.py](../backend/app/core/security.py), [dependencies.py](../backend/app/usuarios/dependencies.py), [rate_limit.py](../backend/app/core/rate_limit.py) | [test_auth.py](../backend/tests/test_auth.py), [test_seguridad.py](../backend/tests/test_seguridad.py) | [docs/evidencia-s13.md](evidencia-s13.md): modelado de amenazas STRIDE sobre C4, RBAC y análisis de dependencias sin vulnerabilidades |
| A-06 | Extensibilidad para múltiples programas académicos | RF-06 | [Q-06](arc42/10-quality-requirements.md#escenario-q-06--extensibilidad-para-múltiples-programas-académicos) | Pendiente | [ADR-0001](adr/0001-seleccion-monolito-modular.md), [ADR-0003](adr/0003-seleccion-motor-de-base-de-datos.md), [ADR-0015](adr/0015-progreso-curricular-por-estudiante.md) | [catalogo_utb.py](../backend/app/requisitos/catalogo_utb.py), [models.py](../backend/app/requisitos/models.py) | [test_progreso.py](../backend/tests/test_progreso.py) | Parcial: catálogo y malla reales solo para Sistemas |
| A-07 | Gestión de solicitudes de estudiantes en el centro de ayuda | RF-07 | [Q-07](arc42/10-quality-requirements.md#escenario-q-07--gestión-de-solicitudes-del-centro-de-ayuda) | Pendiente | [ADR-0001](adr/0001-seleccion-monolito-modular.md), [ADR-0016](adr/0016-modulo-ayuda-y-aislamiento-por-programa.md) | [ayuda/](../backend/app/ayuda/) | [test_ayuda.py](../backend/tests/test_ayuda.py) | Aislamiento por programa con 15 solicitudes en dos programas |
| A-08 | Historial de cambios sobre la información académica | RF-08 | [Q-08](arc42/10-quality-requirements.md#escenario-q-08--historial-de-cambios-sobre-la-información-académica) | [C4 Nivel 2](c4/contenedores.puml) (la tabla de historial vive en los contenedores de base de datos) | [ADR-0003](adr/0003-seleccion-motor-de-base-de-datos.md) (motor transaccional), [ADR-0011](adr/0011-historial-de-cambios-transaccional.md) (mecanismo) | [models.py](../backend/app/requisitos/models.py) (`RequisitoHistorial`), [service.py](../backend/app/requisitos/service.py), `estudiantes/models.py (EstudianteHistorial)` | [test_historial.py](../backend/tests/test_historial.py), [test_progreso.py](../backend/tests/test_progreso.py) | [docs/evidencia-s12.md](evidencia-s12.md) — parcial: historial transaccional de requisitos y avance curricular; sin endpoint general de consulta |

---

# Descripción de aspectos planteados

---

## A-01 — Seguimiento del cumplimiento de requisitos

**Para:** Estudiantes universitarios.

**Cuestión:** El estudiante no cuenta con una forma centralizada de conocer qué requisitos de grado ha cumplido y cuáles tiene pendientes.

**Valor:** Permitir visualizar de forma clara el avance hacia la graduación y conocer los requisitos que todavía debe cumplir.

**Deber:** DinamikUTB debe permitir al estudiante consultar el estado de los requisitos necesarios para su graduación.

**Escenarios relacionados:** [Q-01](arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica), [Q-03](arc42/10-quality-requirements.md#escenario-q-03--facilidad-de-comprensión-de-la-información).

**Estado de implementación:** el endpoint `GET /requisitos/{estudiante_id}` ya consulta el estado real desde la base de datos (SQLite en local y CI, PostgreSQL 16 en el ambiente desplegado), con pantalla en Flutter que lo muestra (`frontend/lib/requisitos/`). El cálculo del porcentaje de avance (A-02) se implementa mediante el módulo curricular y sus servicios asociados. Desde [ADR-0006](adr/0006-plataforma-despliegue-frontend.md) y [ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md), el aspecto también depende de que el backend y la base PostgreSQL (servidor del laboratorio, Dokploy) y el frontend (GitHub Pages) estén desplegados y accesibles fuera de la universidad. El despliegue inicial en Render ([ADR-0005](adr/0005-plataforma-despliegue-backend.md), [ADR-0007](adr/0007-persistencia-render-postgres.md)) quedó retirado.

**Modos de fallo:** la integración Flutter → FastAPI → base de datos que sostiene este aspecto está analizada en [arc42/11, sección 11.5](arc42/11-risks-and-technical-debt.md) (no responde, responde tarde, responde dos veces), con timeout y reintento en el cliente y `PUT` idempotente; la decisión de no extraer módulos está en [ADR-0010](adr/0010-extraccion-de-modulo.md).

---

## A-02 — Cálculo correcto del estado de graduación

**Para:** Estudiantes próximos a completar su programa académico.

**Cuestión:** Un cálculo incorrecto del estado de los requisitos podría llevar al estudiante a creer que ha cumplido condiciones que realmente están pendientes, o al contrario.

**Valor:** Garantizar que el porcentaje de avance y el estado de los requisitos representen correctamente la información registrada.

**Deber:** El sistema debe calcular de forma correcta y consistente el estado de cumplimiento de los requisitos de graduación, considerando los créditos aprobados, el promedio académico y las condiciones de elegibilidad correspondientes al programa del estudiante.

**Escenario relacionado:** [Q-01](arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica).

**Estado de implementación:** el backend incorpora el cálculo del progreso curricular en `backend/app/curriculo/progreso.py` y su integración con el módulo `requisitos/`. La información se consulta mediante `GET /malla/progreso` y `/requisitos/{id}/resumen`. El cálculo contempla créditos, promedio y elegibilidad. La decisión arquitectónica correspondiente se registra en [ADR-0015](adr/0015-progreso-curricular-por-estudiante.md).

---

## A-03 — Alertas tempranas de requisitos pendientes

**Para:** Estudiantes que se aproximan a los últimos semestres.

**Cuestión:** Algunos estudiantes pueden descubrir demasiado tarde que tienen un requisito pendiente, provocando posibles retrasos en su graduación.

**Valor:** Permitir que el estudiante identifique con anticipación los requisitos que requieren atención.

**Deber:** DinamikUTB debe identificar los requisitos pendientes que puedan afectar el proceso de graduación y proporcionar información o alertas oportunas.

**Escenario relacionado:** [Q-04](arc42/10-quality-requirements.md#escenario-q-04--alertas-tempranas-de-requisitos-pendientes).

---

## A-04 — Disponibilidad del sistema

**Para:** Estudiantes, coordinadores y administradores.

**Cuestión:** Si la plataforma no está disponible, los usuarios no podrán consultar o gestionar la información necesaria para el seguimiento de los requisitos.

**Valor:** Mantener el sistema accesible cuando los usuarios necesiten consultar la información académica.

**Deber:** DinamikUTB debe mantener disponible el servicio principal y minimizar las interrupciones que impidan consultar la información.

**Escenario relacionado:** [Q-05](arc42/10-quality-requirements.md#escenario-q-05--disponibilidad-del-sistema).

**Estado de la decisión:** [ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md) fija el servidor del laboratorio (Dokploy, PostgreSQL 16 con volumen `pgdata`) como plataforma vigente del backend y la base, sin *spin down* ni expiración. Reemplaza el despliegue inicial en Render ([ADR-0005](adr/0005-plataforma-despliegue-backend.md), [ADR-0007](adr/0007-persistencia-render-postgres.md)), retirado por la expiración de su base gratuita a los 30 días (arc42 §11, F6). El aspecto se observa mediante `GET /health` y la métrica `GET /metrics`.

**Modos de fallo:** analizados en [arc42/11, sección 11.5](arc42/11-risks-and-technical-debt.md); decisión de no extraer módulos en [ADR-0010](adr/0010-extraccion-de-modulo.md).

---

## A-05 — Protección y control de acceso a la información académica

**Para:** Estudiantes, coordinadores y administradores autorizados.

**Cuestión:** La información académica pertenece a cada estudiante y no debe estar disponible para usuarios que no tengan los permisos correspondientes.

**Valor:** Proteger la información académica y garantizar que cada usuario pueda acceder únicamente a la información permitida según su rol.

**Deber:** El sistema debe autenticar a los usuarios y controlar el acceso a la información académica de acuerdo con los permisos de cada rol.

**Escenario relacionado:** [Q-02](arc42/10-quality-requirements.md#escenario-q-02--seguridad-y-aislamiento-de-la-información).

**Nota de riesgo (histórica, resuelta):** entre el despliegue inicial en Render ([ADR-0005](adr/0005-plataforma-despliegue-backend.md)) y la implementación de `usuarios/` el backend quedó expuesto sin autenticación. Desde [ADR-0013](adr/0013-controles-estructurales-de-seguridad-y-autenticacion.md) todos los endpoints exigen JWT y RBAC; verificado con HTTP 401 en `docs/evidencia-s12.md`.

---

## A-06 — Extensibilidad para múltiples programas académicos

**Para:** Coordinadores y administradores, y posteriormente estudiantes de diferentes programas académicos.

**Cuestión:** DinamikUTB debe poder manejar los requisitos de diferentes programas académicos de la UTB sin tener que reconstruir el sistema para cada carrera.

**Valor:** Permitir que la solución pueda crecer y adaptarse a diferentes programas académicos.

**Deber:** La arquitectura debe permitir incorporar nuevos programas y sus requisitos sin modificar la lógica principal del sistema.

**Escenario relacionado:** [Q-06](arc42/10-quality-requirements.md#escenario-q-06--extensibilidad-para-múltiples-programas-académicos).

**Estado de implementación:** se dispone de un catálogo de requisitos y una malla curricular real para Ingeniería de Sistemas, mediante `backend/app/requisitos/catalogo_utb.py` y `backend/app/requisitos/models.py`. La implementación es parcial, ya que todavía no se han incorporado las mallas de Ingeniería Industrial y Administración por no contar con pensums oficiales verificables. La decisión relacionada con el progreso curricular por estudiante se documenta en [ADR-0015](adr/0015-progreso-curricular-por-estudiante.md).

---

## A-07 — Gestión de solicitudes de estudiantes en el centro de ayuda

**Para:** Estudiantes que detectan una posible inconsistencia en su información académica, y coordinadores encargados de atenderla.

**Cuestión:** Como el estudiante no puede modificar directamente su información académica (ver `arc42/02-architecture-constraints.md`, sección 2.2), necesita un canal formal para reportar errores y darle seguimiento hasta que se resuelvan; sin ese canal, las correcciones dependerían de gestiones informales y sin trazabilidad.

**Valor:** Permitir que el estudiante reporte inconsistencias de forma centralizada y que el coordinador correspondiente las atienda dentro de su ámbito de responsabilidad, sin exponer la solicitud a coordinadores de otros programas.

**Deber:** DinamikUTB debe registrar las solicitudes enviadas por los estudiantes mediante el centro de ayuda, hacerlas visibles únicamente al coordinador del programa correspondiente y permitir actualizar su estado hasta su resolución.

**Escenario relacionado:** [Q-07](arc42/10-quality-requirements.md#escenario-q-07--gestión-de-solicitudes-del-centro-de-ayuda).

**Estado de implementación:** el módulo `backend/app/ayuda/` incorpora los modelos `SolicitudDiscrepancia` y `CoordinadorPrograma`, junto con el servicio, router y pruebas correspondientes. El aislamiento por programa se verifica con 15 solicitudes distribuidas en dos programas. La decisión arquitectónica se documenta en [ADR-0016](adr/0016-modulo-ayuda-y-aislamiento-por-programa.md).

---

## A-08 — Historial de cambios sobre la información académica

**Para:** Coordinadores y administradores responsables de modificar información académica, y para la propia institución en caso de auditar una inconsistencia.

**Cuestión:** Si las modificaciones sobre requisitos o datos académicos no quedan registradas, resulta imposible determinar quién hizo un cambio, cuándo lo hizo y qué valor tenía el dato antes de modificarse, lo que dificulta investigar una inconsistencia reportada por un estudiante.

**Valor:** Permitir reconstruir el historial de una modificación específica, dando soporte tanto a la resolución de solicitudes del centro de ayuda (A-07) como a la confianza general en la exactitud de la información (A-01, A-02).

**Deber:** El sistema debe registrar de forma automática cada modificación realizada sobre información académica, incluyendo el usuario responsable, la fecha y los valores anterior y nuevo del dato.

**Escenario relacionado:** [Q-08](arc42/10-quality-requirements.md#escenario-q-08--historial-de-cambios-sobre-la-información-académica).

**Estado de la decisión:** [ADR-0011](adr/0011-historial-de-cambios-transaccional.md) fija una tabla de historial append-only por módulo dueño, escrita en la misma transacción que el cambio. Implementada en `requisitos/` (cambios de estado) y en `estudiantes/` (`EstudianteHistorial`, [ADR-0014](adr/0014-extension-historial-datos-estudiante.md)). **Pendiente:** endpoint de consulta para coordinador/administrador (existe `service.obtener_historial` sin ruta, ver ADR-0011 §6) y tarea cron de respaldo del volumen `pgdata` (ver `arc42/11`).

---

# Relación con los escenarios de calidad

| Escenario | Atributo de calidad | Aspecto relacionado |
|---|---|---|
| [Q-01](arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica) | Exactitud / Consistencia | [A-01](#a-01--seguimiento-del-cumplimiento-de-requisitos), [A-02](#a-02--cálculo-correcto-del-estado-de-graduación) |
| [Q-02](arc42/10-quality-requirements.md#escenario-q-02--seguridad-y-aislamiento-de-la-información) | Seguridad | [A-05](#a-05--protección-y-control-de-acceso-a-la-información-académica) |
| [Q-03](arc42/10-quality-requirements.md#escenario-q-03--facilidad-de-comprensión-de-la-información) | Usabilidad | [A-01](#a-01--seguimiento-del-cumplimiento-de-requisitos) |
| [Q-04](arc42/10-quality-requirements.md#escenario-q-04--alertas-tempranas-de-requisitos-pendientes) | Exactitud / Consistencia, Usabilidad | [A-03](#a-03--alertas-tempranas-de-requisitos-pendientes) |
| [Q-05](arc42/10-quality-requirements.md#escenario-q-05--disponibilidad-del-sistema) | Disponibilidad | [A-04](#a-04--disponibilidad-del-sistema) |
| [Q-06](arc42/10-quality-requirements.md#escenario-q-06--extensibilidad-para-múltiples-programas-académicos) | Mantenibilidad | [A-06](#a-06--extensibilidad-para-múltiples-programas-académicos) |
| [Q-07](arc42/10-quality-requirements.md#escenario-q-07--gestión-de-solicitudes-del-centro-de-ayuda) | Trazabilidad, Seguridad | [A-07](#a-07--gestión-de-solicitudes-de-estudiantes-en-el-centro-de-ayuda) |
| [Q-08](arc42/10-quality-requirements.md#escenario-q-08--historial-de-cambios-sobre-la-información-académica) | Trazabilidad | [A-08](#a-08--historial-de-cambios-sobre-la-información-académica) |
