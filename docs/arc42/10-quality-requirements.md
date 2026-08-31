# 10. Quality Requirements

## 10.1 Quality Requirements Overview

Los requisitos de calidad de DinamikUTB se centran principalmente en garantizar que la información académica mostrada al estudiante sea correcta, que los datos estén protegidos y que el sistema sea fácil de utilizar.

La prioridad se establece considerando el impacto que tendría una falla sobre el proceso de graduación del estudiante y el riesgo técnico asociado.

### Priorización de atributos de calidad

| Prioridad | Atributo de calidad | Impacto | Riesgo técnico | Justificación |
|---|---|---|---|---|
| 1 | Exactitud / Consistencia | Alto | Alto | Una información incorrecta podría llevar al estudiante a tomar decisiones equivocadas sobre sus requisitos de graduación. |
| 2 | Seguridad | Alto | Alto | El sistema manejará información académica y datos personales de los estudiantes. |
| 3 | Usabilidad | Medio | Medio | La información debe ser fácil de entender para que el estudiante pueda utilizar el sistema rápidamente. |
| 4 | Rendimiento | Medio | Medio | Las consultas del progreso académico deben responder rápidamente. |
| 5 | Disponibilidad | Medio | Bajo | El sistema debe estar disponible cuando el estudiante necesite consultar su información. |
| 6 | Trazabilidad | Bajo | Bajo | Los cambios realizados sobre la información deben poder ser identificados mediante un historial. |
| 7 | Mantenibilidad | Bajo | Bajo | El sistema debe poder evolucionar para incorporar nuevos requisitos y programas académicos. |

---

## 10.2 Utility Tree

El árbol de utilidad organiza los atributos de calidad de acuerdo con su importancia para DinamikUTB.

```text
DinamikUTB
│
├── Exactitud / Consistencia
│   └── Información académica correcta
│
├── Seguridad
│   └── Protección de información académica y acceso según rol
│
├── Usabilidad
│   └── Información clara y fácil de comprender
│
├── Rendimiento
│   └── Respuesta rápida de las consultas
│
├── Disponibilidad
│   └── Acceso al sistema cuando el estudiante lo necesite
│
├── Trazabilidad
│   └── Historial de cambios sobre la información
│
└── Mantenibilidad
    └── Incorporación de nuevos requisitos y programas académicos
```

---

### Priorización del árbol

Los atributos ubicados en los primeros niveles representan las principales preocupaciones de calidad del sistema.

La exactitud y consistencia tienen la mayor prioridad debido a que un error en la información de requisitos podría afectar directamente las decisiones académicas del estudiante.

La seguridad ocupa el segundo nivel debido a que DinamikUTB manejará información académica asociada a estudiantes y diferentes roles de usuario.

La usabilidad ocupa el tercer nivel porque el sistema debe permitir que los estudiantes comprendan rápidamente su situación académica.

---

## 10.3 Quality Scenarios

### Escenario Q-01 — Exactitud de la información académica

| Elemento | Descripción |
|---|---|
| **Fuente** | Estudiante |
| **Estímulo** | El estudiante consulta su estado de requisitos de graduación. |
| **Artefacto** | Módulo de seguimiento de requisitos de DinamikUTB. |
| **Entorno** | Sistema en funcionamiento con información académica registrada en la base de datos. |
| **Respuesta** | El sistema consulta la información correspondiente al estudiante y muestra el estado de cada requisito de acuerdo con los datos registrados. |
| **Medida** | El **100 % de los datos mostrados** debe corresponder con la información registrada para el estudiante. Cualquier información incorrecta se considera un incidente crítico. |
| **Herramienta** | **Pytest**, mediante pruebas automatizadas de los datos y reglas de cálculo. |
| **Carga** | **20 casos de prueba** con diferentes estados de requisitos académicos. |

**Prioridad:** Alta  
**Atributo:** Exactitud / Consistencia

---

### Escenario Q-02 — Seguridad y aislamiento de la información

| Elemento | Descripción |
|---|---|
| **Fuente** | Usuario autenticado |
| **Estímulo** | El usuario intenta consultar información académica mediante DinamikUTB. |
| **Artefacto** | Módulo de autenticación y control de acceso. |
| **Entorno** | Sistema en funcionamiento con múltiples estudiantes y usuarios con diferentes roles. |
| **Respuesta** | El sistema autentica al usuario y permite acceder únicamente a la información correspondiente a sus permisos. |
| **Medida** | El **100 % de los intentos no autorizados** debe ser rechazado y ningún estudiante debe poder consultar información académica perteneciente a otro estudiante. |
| **Herramienta** | **Pytest + FastAPI TestClient**, mediante pruebas de acceso autorizado y no autorizado. |
| **Carga** | **20 intentos de acceso**, combinando solicitudes autorizadas y no autorizadas. |

**Prioridad:** Alta  
**Atributo:** Seguridad

---

### Escenario Q-03 — Facilidad de comprensión de la información

| Elemento | Descripción |
|---|---|
| **Fuente** | Estudiante |
| **Estímulo** | El estudiante ingresa a su pantalla principal para consultar su progreso. |
| **Artefacto** | Interfaz principal de DinamikUTB. |
| **Entorno** | Usuario autenticado utilizando la aplicación. |
| **Respuesta** | El sistema presenta el porcentaje de avance, los requisitos cumplidos y los requisitos pendientes de forma clara y organizada. |
| **Medida** | Al menos el **80 % de los usuarios evaluados** debe poder identificar correctamente sus requisitos pendientes y su porcentaje de avance en una prueba de uso sin asistencia. |
| **Herramienta** | **Prueba de usabilidad**, mediante una tarea guiada y observación de resultados. |
| **Carga** | **5 usuarios evaluados** realizando la tarea de consultar su progreso sin asistencia. |

**Prioridad:** Alta  
**Atributo:** Usabilidad

---

### Escenario Q-04 — Alertas tempranas de requisitos pendientes

| Elemento | Descripción |
|---|---|
| **Fuente** | Estudiante (mediante su consulta) / Sistema (evaluación automática al momento de la consulta) |
| **Estímulo** | El estudiante se encuentra en un semestre avanzado de su programa y tiene al menos un requisito crítico (idioma, práctica, opción de grado) sin cumplir. |
| **Artefacto** | Módulo `requisitos/`, que ya concentra el cálculo de estado (ver `05-building-block-view.md`). |
| **Entorno** | Sistema en funcionamiento, con el semestre actual del estudiante registrado en `estudiantes/`. |
| **Respuesta** | El sistema identifica los requisitos críticos pendientes según el semestre del estudiante y los presenta de forma destacada, diferenciándolos de los requisitos pendientes sin urgencia. |
| **Medida** | El **100 % de los requisitos marcados como críticos y pendientes** debe aparecer señalado como alerta la primera vez que el estudiante consulta su progreso después de cumplirse la condición de urgencia. |
| **Herramienta** | **Pytest**, con casos que combinan distintos semestres y estados de requisitos críticos. |
| **Carga** | **15 casos de prueba**, cubriendo estudiantes en diferentes semestres y con distintos requisitos críticos pendientes. |

**Prioridad:** Media  
**Atributo:** Exactitud / Consistencia (la alerta depende de que el cálculo de "pendiente" sea correcto), con relación directa a Usabilidad por la oportunidad de la información.


---

### Escenario Q-05 — Disponibilidad del sistema

| Elemento | Descripción |
|---|---|
| **Fuente** | Estudiante, coordinador o administrador |
| **Estímulo** | El usuario intenta acceder al sistema para consultar o gestionar información, incluyendo momentos de mayor demanda (por ejemplo, cierre de semestre). |
| **Artefacto** | Backend de DinamikUTB desplegado como monolito modular. |
| **Entorno** | Ambiente de pruebas del proyecto (no existe todavía un ambiente productivo institucional). |
| **Respuesta** | El sistema responde a las solicitudes sin interrupciones prolongadas; si ocurre un fallo, no debe dejar el sistema completo inaccesible más allá de un tiempo acotado. |
| **Medida** | El sistema debe mantenerse disponible durante la ventana de prueba definida por el equipo, con una recuperación ante fallos en menos de **5 minutos**. Esta medida es un objetivo inicial y deberá ajustarse una vez exista un ambiente de despliegue real. |
| **Herramienta** | Prueba de carga o monitoreo simple sobre el ambiente de pruebas (por ejemplo, un script que reintenta solicitudes y registra tiempos de caída). |
| **Carga** | Ventana de prueba definida por el equipo (por ejemplo, 100 solicitudes concurrentes sostenidas durante 10 minutos). |

**Prioridad:** Media  
**Atributo:** Disponibilidad

---

### Escenario Q-06 — Extensibilidad para múltiples programas académicos

| Elemento | Descripción |
|---|---|
| **Fuente** | Administrador |
| **Estímulo** | Se necesita incorporar un nuevo programa académico con sus propios requisitos de grado. |
| **Artefacto** | Módulo `programas/` y su relación con `requisitos/` (ver `05-building-block-view.md`). |
| **Entorno** | Sistema en funcionamiento con al menos un programa académico ya configurado. |
| **Respuesta** | El administrador registra el nuevo programa y sus requisitos desde `programas/`, sin que sea necesario modificar el código del módulo `requisitos/`. |
| **Medida** | Incorporar un programa académico nuevo y completo no debe requerir **ningún cambio de código** en `requisitos/`; se verifica registrando un programa de prueba y ejecutando la suite existente de `requisitos/` sin modificarla. |
| **Herramienta** | Prueba manual o script de verificación, apoyado en la suite de **Pytest** ya existente para `requisitos/`. |
| **Carga** | **1 programa académico de prueba**, con al menos **5 requisitos** distintos configurados. |

**Prioridad:** Baja  
**Atributo:** Mantenibilidad (relacionado directamente con la extensibilidad exigida en `02-architecture-constraints.md`, sección 2.1).



---

### Escenario Q-07 — Gestión de solicitudes del centro de ayuda

| Elemento | Descripción |
|---|---|
| **Fuente** | Estudiante |
| **Estímulo** | El estudiante detecta una posible inconsistencia en su información académica y envía una solicitud mediante el centro de ayuda. |
| **Artefacto** | Módulo `ayuda/`. |
| **Entorno** | Estudiante autenticado, sistema en funcionamiento con coordinadores asignados a cada programa. |
| **Respuesta** | El sistema registra la solicitud asociada al estudiante con un estado inicial `pendiente`, la hace visible únicamente al coordinador del programa correspondiente, y permite actualizar su estado cuando es atendida. |
| **Medida** | El **100 % de las solicitudes enviadas** quedan registradas con estudiante, fecha y estado; y el **100 % de los intentos de un coordinador de otro programa** de ver una solicitud ajena debe ser rechazado. |
| **Herramienta** | **Pytest + FastAPI TestClient**. |
| **Carga** | **15 solicitudes de prueba**, distribuidas entre al menos dos programas académicos distintos, para verificar el aislamiento por programa. |

**Prioridad:** Media  
**Atributo:** Trazabilidad (registro completo de la solicitud), con relación directa a Seguridad (visibilidad limitada al coordinador del programa correspondiente, en línea con Q-02).


---

### Escenario Q-08 — Historial de cambios sobre la información académica

| Elemento | Descripción |
|---|---|
| **Fuente** | Coordinador o administrador (quien realiza la modificación) |
| **Estímulo** | Un usuario autorizado modifica un requisito o un dato académico de un estudiante. |
| **Artefacto** | Mecanismo de historial, transversal a `requisitos/` y `estudiantes/` (ver `03-context-and-scope.md`, sección 3.5). |
| **Entorno** | Sistema en funcionamiento, con modificaciones realizadas por coordinadores o administradores. |
| **Respuesta** | El sistema registra quién realizó el cambio, cuándo, y los valores anterior y nuevo del dato modificado. |
| **Medida** | El **100 % de las modificaciones** sobre datos académicos deben quedar registradas en el historial, sin excepciones, y deben poder consultarse por un usuario autorizado. |
| **Herramienta** | **Pytest**, verificando que cada operación de escritura sobre `requisitos/` o `estudiantes/` genere su entrada correspondiente de historial. |
| **Carga** | **20 operaciones de modificación de prueba**, sobre distintos campos y estudiantes. |

**Prioridad:** Baja  
**Atributo:** Trazabilidad


---

## 10.4 Relación entre escenarios y aspectos

Los escenarios de calidad se relacionan con los aspectos definidos en `docs/aspectos.md` y con la decisión arquitectónica que los sustenta.

| Escenario | Atributo | Aspecto relacionado | ADR |
|---|---|---|---|
| Q-01 | Exactitud / Consistencia | [A-01](../aspectos.md/#a-01---seguimiento-del-cumplimiento-de-requisitos) Seguimiento del cumplimiento de requisitos | [ADR-0001](../adr/0001-seleccion-monolito-modular.md) |
| Q-02 | Seguridad | [A-05](../aspectos.md/#a-05---proteccion-y-control-de-acceso-a-la-informacion-academica) Protección y control de acceso a la información académica | [ADR-0001](../adr/0001-seleccion-monolito-modular.md) |
| Q-03 | Usabilidad | [A-01](../aspectos.md/#a-01---seguimiento-del-cumplimiento-de-requisitos) Seguimiento del cumplimiento de requisitos | No aplica: se resuelve en la interfaz, no en la arquitectura del backend (ver `04-solution-strategy.md`, sección 4.4). |
| Q-04 | Exactitud / Consistencia, Usabilidad | [A-03](../aspectos.md/#a-03---alertas-tempranas-de-requisitos-pendientes) Alertas tempranas de requisitos pendientes | Pendiente: mecanismo de disparo de la alerta sin ADR (ver `09-architecture-decisions.md`). |
| Q-05 | Disponibilidad | [A-04](../aspectos.md/#a-04---disponibilidad-del-sistema) Disponibilidad del sistema | [ADR-0001](../adr/0001-seleccion-monolito-modular.md) (despliegue como aplicación única). |
| Q-06 | Mantenibilidad | [A-06](../aspectos.md/#a-06---extensibilidad-para-multiples-programas-academicos) Extensibilidad para múltiples programas académicos | [ADR-0001](../adr/0001-seleccion-monolito-modular.md) |
| Q-07 | Trazabilidad, Seguridad | [A-07](../aspectos.md/#a-07---gestion-de-solicitudes-de-estudiantes-en-el-centro-de-ayuda) Gestión de solicitudes de estudiantes en el centro de ayuda | [ADR-0001](../adr/0001-seleccion-monolito-modular.md) (módulo `ayuda/`). |
| Q-08 | Trazabilidad | [A-08](../aspectos.md/#a-08---historial-de-cambios-sobre-la-informacion-academica) Historial de cambios sobre la información académica | Pendiente: mecanismo de almacenamiento del historial sin ADR (ver `09-architecture-decisions.md`). |

> Estos escenarios podrán ser refinados posteriormente a medida que se implementen los componentes del sistema y se definan las pruebas correspondientes.

---

## 10.5 Trazabilidad hacia bloques y runtime scenarios

Con la incorporación de `05-building-block-view.md` y `06-runtime-view.md`, cada escenario de calidad puede verificarse contra un bloque y un flujo de ejecución concretos, y no solo contra una tabla de tácticas:

| Escenario | Módulo(s) responsable(s) (sección 5) | Runtime scenario (sección 6) |
|---|---|---|
| Q-01 | `requisitos/`, `estudiantes/`, `programas/` | 6.1 Estudiante consulta su progreso; 6.3 Coordinador corrige un requisito |
| Q-02 | `usuarios/` | 6.1 (paso de autenticación); 6.2 Control de acceso a información académica |
| Q-03 | `estudiantes/`, `requisitos/` (frontend) | 6.1 Estudiante consulta su progreso |
| Q-04 | `requisitos/`, `estudiantes/` | 6.1 Estudiante consulta su progreso (paso de cálculo de alertas, a incorporar) |
| Q-05 | Backend completo (todos los módulos) | No aplica a un flujo puntual; es una propiedad transversal del despliegue. |
| Q-06 | `programas/`, `requisitos/` | No requiere un runtime scenario de usuario final; se verifica en tiempo de configuración/administración. |
| Q-07 | `ayuda/`, `usuarios/` | 6.3 Coordinador corrige un requisito reportado por un estudiante |
| Q-08 | `requisitos/`, `estudiantes/` (transversal) | 6.3 Coordinador corrige un requisito reportado por un estudiante (paso de registro en historial) |



---
