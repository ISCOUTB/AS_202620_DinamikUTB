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

## 10.4 Relación entre escenarios y aspectos

Los escenarios de calidad se relacionan con los aspectos definidos en `docs/aspectos.md`.

| Escenario | Atributo | Aspecto relacionado |
|---|---|---|
| Q-01 | Exactitud / Consistencia | A-01 Seguimiento del cumplimiento de requisitos |
| Q-02 | Seguridad | A-05 Protección y control de acceso a la información académica |
| Q-03 | Usabilidad | A-01 Seguimiento del cumplimiento de requisitos |

Estos escenarios podrán ser refinados posteriormente a medida que se implementen los componentes del sistema y se definan las pruebas correspondientes.
