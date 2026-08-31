# Aspect Driven Development

> Este documento registra los aspectos del sistema que requieren trazabilidad desde el requisito hasta su evidencia de calidad en el proyecto **DinamikUTB**.

---

# Aspectos planteados

| ID | Aspecto | Requisito | Escenario de calidad | C4 | ADR | Código | Pruebas | Evidencia |
|---|---|---|---|---|---|---|---|---|
| A-01 | Seguimiento del cumplimiento de requisitos | RF-01 | [Q-01](arc42/10-quality-requirements.md/#escenario-q-01--exactitud-de-la-informacion-academica), [Q-03](arc42/10-quality-requirements.md/#escenario-q-03--facilidad-de-comprension-de-la-informacion) | Pendiente | [ADR-0001](adr/0001-seleccion-monolito-modular.md) | Pendiente | Pendiente | Pendiente |
| A-02 | Cálculo correcto del estado de graduación | RF-02 | [Q-01](arc42/10-quality-requirements.md/#escenario-q-01--exactitud-de-la-informacion-academica) | Pendiente | [ADR-0001](adr/0001-seleccion-monolito-modular.md) | Pendiente | Pendiente | Pendiente |
| A-03 | Alertas tempranas de requisitos pendientes | RF-03 | [Q-04](arc42/10-quality-requirements.md/#escenario-q-04--alertas-tempranas-de-requisitos-pendientes) | Pendiente | Pendiente (mecanismo de disparo sin decidir) | Pendiente | Pendiente | Pendiente |
| A-04 | Disponibilidad del sistema | RF-04 | [Q-05](arc42/10-quality-requirements.md/#escenario-q-05--disponibilidad-del-sistema) | Pendiente | [ADR-0001](adr/0001-seleccion-monolito-modular.md) | Pendiente | Pendiente | Pendiente |
| A-05 | Protección y control de acceso a la información académica | RF-05 | [Q-02](arc42/10-quality-requirements.md/#escenario-q-02--seguridad-y-aislamiento-de-la-informacion) | Pendiente | [ADR-0001](adr/0001-seleccion-monolito-modular.md) | Pendiente | Pendiente | Pendiente |
| A-06 | Extensibilidad para múltiples programas académicos | RF-06 | [Q-06](arc42/10-quality-requirements.md/#escenario-q-06--extensibilidad-para-multiples-programas-academicos) | Pendiente | [ADR-0001](adr/0001-seleccion-monolito-modular.md) | Pendiente | Pendiente | Pendiente |
| A-07 | Gestión de solicitudes de estudiantes en el centro de ayuda | RF-07 | [Q-07](arc42/10-quality-requirements.md/#escenario-q-07--gestion-de-solicitudes-del-centro-de-ayuda) | Pendiente | [ADR-0001](adr/0001-seleccion-monolito-modular.md) (módulo `ayuda/`) | Pendiente | Pendiente | Pendiente |
| A-08 | Historial de cambios sobre la información académica | RF-08 | [Q-08](arc42/10-quality-requirements.md/#escenario-q-08--historial-de-cambios-sobre-la-informacion-academica) | Pendiente | Pendiente (mecanismo de almacenamiento sin decidir) | Pendiente | Pendiente | Pendiente |
| A-01 | Seguimiento del cumplimiento de requisitos | RF-01 | [Q-01](arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica), [Q-03](arc42/10-quality-requirements.md#escenario-q-03--facilidad-de-comprensión-de-la-información) | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |
| A-02 | Cálculo correcto del estado de graduación | RF-02 | [Q-01](arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica) | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |
| A-03 | Alertas tempranas de requisitos pendientes | RF-03 | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |
| A-04 | Disponibilidad del sistema | RF-04 | Pendiente | Pendiente | [ADR-0001](adr/0001-seleccion-monolito-modular.md) | Pendiente | Pendiente | Pendiente |
| A-05 | Protección y control de acceso a la información académica | RF-05 | [Q-02](arc42/10-quality-requirements.md#escenario-q-02--seguridad-y-aislamiento-de-la-información) | Pendiente | [ADR-0001](adr/0001-seleccion-monolito-modular.md) | Pendiente | Pendiente | Pendiente |
| A-06 | Extensibilidad para múltiples programas académicos | RF-06 | Pendiente | Pendiente | [ADR-0001](adr/0001-seleccion-monolito-modular.md) | Pendiente | Pendiente | Pendiente |


---

# Descripción de aspectos planteados

---


## A-01 - Seguimiento del cumplimiento de requisitos

**Para:** Estudiantes universitarios.

**Cuestión:** El estudiante no cuenta con una forma centralizada de conocer qué requisitos de grado ha cumplido y cuáles tiene pendientes.

**Valor:** Permitir visualizar de forma clara el avance hacia la graduación y conocer los requisitos que todavía debe cumplir.

**Deber:** DinamikUTB debe permitir al estudiante consultar el estado de los requisitos necesarios para su graduación.

**Escenarios relacionados:** [Q-01](arc42/10-quality-requirements.md/#escenario-q-01--exactitud-de-la-informacion-academica), [Q-03](arc42/10-quality-requirements.md/#escenario-q-03--facilidad-de-comprension-de-la-informacion).

**Escenarios relacionados:** [Q-01](arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica), [Q-03](arc42/10-quality-requirements.md#escenario-q-03--facilidad-de-comprensión-de-la-información).


---
---


## A-02 - Calculo correcto del estado de graduacion

**Para:** Estudiantes próximos a completar su programa académico.

**Cuestión:** Un cálculo incorrecto del estado de los requisitos podría llevar al estudiante a creer que ha cumplido condiciones que realmente están pendientes, o al contrario.

**Valor:** Garantizar que el porcentaje de avance y el estado de los requisitos representen correctamente la información registrada.

**Deber:** El sistema debe calcular de forma correcta y consistente el estado de cumplimiento de los requisitos de graduación.


**Escenario relacionado:** [Q-01](arc42/10-quality-requirements.md/#escenario-q-01--exactitud-de-la-informacion-academica).

**Escenario relacionado:** [Q-01](arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica).


---
---

## A-03 - Alertas tempranas de requisitos pendientes

**Para:** Estudiantes que se aproximan a los últimos semestres.

**Cuestión:** Algunos estudiantes pueden descubrir demasiado tarde que tienen un requisito pendiente, provocando posibles retrasos en su graduación.

**Valor:** Permitir que el estudiante identifique con anticipación los requisitos que requieren atención.

**Deber:** DinamikUTB debe identificar los requisitos pendientes que puedan afectar el proceso de graduación y proporcionar información o alertas oportunas.

**Escenario relacionado:** [Q-04](arc42/10-quality-requirements.md/#escenario-q-04--alertas-tempranas-de-requisitos-pendientes).

---
---

## A-04 - Disponibilidad del sistema

**Para:** Estudiantes, coordinadores y administradores.

**Cuestión:** Si la plataforma no está disponible, los usuarios no podrán consultar o gestionar la información necesaria para el seguimiento de los requisitos.

**Valor:** Mantener el sistema accesible cuando los usuarios necesiten consultar la información académica.

**Deber:** DinamikUTB debe mantener disponible el servicio principal y minimizar las interrupciones que impidan consultar la información.

**Escenario relacionado:** [Q-05](arc42/10-quality-requirements.md/#escenario-q-05--disponibilidad-del-sistema).

---
---

## A-05 - Proteccion y control de acceso a la informacion academica

**Para:** Estudiantes, coordinadores y administradores autorizados.

**Cuestión:** La información académica pertenece a cada estudiante y no debe estar disponible para usuarios que no tengan los permisos correspondientes.

**Valor:** Proteger la información académica y garantizar que cada usuario pueda acceder únicamente a la información permitida según su rol.

**Deber:** El sistema debe autenticar a los usuarios y controlar el acceso a la información académica de acuerdo con los permisos de cada rol.


**Escenario relacionado:** [Q-02](arc42/10-quality-requirements.md/#escenario-q-02--seguridad-y-aislamiento-de-la-informacion/).

**Escenario relacionado:** [Q-02](arc42/10-quality-requirements.md#escenario-q-02--seguridad-y-aislamiento-de-la-información).


---
---

## A-06 - Extensibilidad para multiples programas academicos

**Para:** Coordinadores y administradores, y posteriormente estudiantes de diferentes programas académicos.

**Cuestión:** DinamikUTB debe poder manejar los requisitos de diferentes programas académicos de la UTB sin tener que reconstruir el sistema para cada carrera.

**Valor:** Permitir que la solución pueda crecer y adaptarse a diferentes programas académicos.

**Deber:** La arquitectura debe permitir incorporar nuevos programas y sus requisitos sin modificar la lógica principal del sistema.

**Escenario relacionado:** [Q-06](arc42/10-quality-requirements.md/#escenario-q-06--extensibilidad-para-multiples-programas-academicos).

---
---

## A-07 - Gestion de solicitudes de estudiantes en el centro de ayuda

**Para:** Estudiantes que detectan una posible inconsistencia en su información académica, y coordinadores encargados de atenderla.

**Cuestión:** Como el estudiante no puede modificar directamente su información académica (ver `arc42/02-architecture-constraints.md`, sección 2.2), necesita un canal formal para reportar errores y darle seguimiento hasta que se resuelvan; sin ese canal, las correcciones dependerían de gestiones informales y sin trazabilidad.

**Valor:** Permitir que el estudiante reporte inconsistencias de forma centralizada y que el coordinador correspondiente las atienda dentro de su ámbito de responsabilidad, sin exponer la solicitud a coordinadores de otros programas.

**Deber:** DinamikUTB debe registrar las solicitudes enviadas por los estudiantes mediante el centro de ayuda, hacerlas visibles únicamente al coordinador del programa correspondiente y permitir actualizar su estado hasta su resolución.

**Escenario relacionado:** [Q-07](arc42/10-quality-requirements.md/#escenario-q-07--gestion-de-solicitudes-del-centro-de-ayuda).

---
---

## A-08 - Historial de cambios sobre la informacion academica

**Para:** Coordinadores y administradores responsables de modificar información académica, y para la propia institución en caso de auditar una inconsistencia.

**Cuestión:** Si las modificaciones sobre requisitos o datos académicos no quedan registradas, resulta imposible determinar quién hizo un cambio, cuándo lo hizo y qué valor tenía el dato antes de modificarse, lo que dificulta investigar una inconsistencia reportada por un estudiante.

**Valor:** Permitir reconstruir el historial de una modificación específica, dando soporte tanto a la resolución de solicitudes del centro de ayuda (A-07) como a la confianza general en la exactitud de la información (A-01, A-02).

**Deber:** El sistema debe registrar de forma automática cada modificación realizada sobre información académica, incluyendo el usuario responsable, la fecha y los valores anterior y nuevo del dato.

**Escenario relacionado:** [Q-08](arc42/10-quality-requirements.md/#escenario-q-08--historial-de-cambios-sobre-la-informacion-academica).

---
---

# Relación con los escenarios de calidad

| Escenario | Atributo de calidad | Aspecto relacionado |
|---|---|---|
| [Q-01](../docs/arc42/10-quality-requirements.md/#escenario-q-01--exactitud-de-la-informacion-academica) | Exactitud / Consistencia | [A-01](#a-01---seguimiento-del-cumplimiento-de-requisitos), [A-02](#a-02---calculo-correcto-del-estado-de-graduacion) |
| [Q-02](arc42/10-quality-requirements.md/#escenario-q-02--seguridad-y-aislamiento-de-la-información) | Seguridad | [A-05](#a-05---proteccion-y-control-de-acceso-a-la-informacion-academica) |
| [Q-03](arc42/10-quality-requirements.md/#escenario-q-03--facilidad-de-comprension-de-la-informacion) | Usabilidad | [A-01](#a-01---seguimiento-del-cumplimiento-de-requisitos) |
| [Q-04](arc42/10-quality-requirements.md/#escenario-q-04--alertas-tempranas-de-requisitos-pendientes) | Exactitud / Consistencia, Usabilidad | [A-03](#a-03---alertas-tempranas-de-requisitos-pendientes) |
| [Q-05](arc42/10-quality-requirements.md/#escenario-q-05--disponibilidad-del-sistema) | Disponibilidad | [A-04](#a-04---disponibilidad-del-sistema) |
| [Q-06](arc42/10-quality-requirements.md/#escenario-q-06--extensibilidad-para-multiples-programas-academicos) | Mantenibilidad | [A-06](#a-06---extensibilidad-para-multiples-programas-academicos) |
| [Q-07](arc42/10-quality-requirements.md/#escenario-q-07--gestion-de-solicitudes-del-centro-de-ayuda) | Trazabilidad, Seguridad | [A-07](#a-07---gestion-de-solicitudes-de-estudiantes-en-el-centro-de-ayuda) |
| [Q-08](arc42/10-quality-requirements.md/#escenario-q-08--historial-de-cambios-sobre-la-informacion-academica) | Trazabilidad | [A-08](#a-08---historial-de-cambios-sobre-la-informacion-academica) |

