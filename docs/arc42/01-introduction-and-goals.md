# 1. Introduction and Goals

## 1.1 Requirements Overview

**DinamikUTB** es una plataforma orientada al seguimiento de los requisitos necesarios para la graduación de los estudiantes de la **Universidad Tecnológica de Bolívar**.

El sistema busca centralizar en un solo lugar la información relacionada con el cumplimiento de los requisitos de graduación, permitiendo que el estudiante conozca de manera clara su estado académico y pueda identificar con anticipación aquellos requisitos que aún tiene pendientes.

Actualmente, los requisitos necesarios para completar el proceso de graduación pueden involucrar diferentes aspectos, como:

- Créditos académicos.
- Requisito de idioma.
- Prácticas o pasantías.
- Opción de grado.
- Electivas u otros requisitos establecidos por el programa académico.

DinamikUTB permitirá consultar el estado de estos requisitos y calcular automáticamente un porcentaje de avance hacia la graduación a partir de la información registrada.

El sistema estará diseñado para manejar diferentes programas académicos, permitiendo que los requisitos puedan ser configurados de acuerdo con cada carrera.

### Funcionalidades principales
 
| ID | Funcionalidad | Aspecto relacionado | Escenario de calidad |
|---|---|---|---|
| RF-01 | Consultar el estado de los requisitos de graduación (cumplidos, pendientes o en proceso). | [A-01](../aspectos.md#a-01--seguimiento-del-cumplimiento-de-requisitos) | [Q-01](./10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica), [Q-03](./10-quality-requirements.md#escenario-q-03--facilidad-de-comprensión-de-la-información) |
| RF-02 | Calcular y mostrar un porcentaje de avance hacia la graduación. | [A-02](../aspectos.md#a-02--cálculo-correcto-del-estado-de-graduación) | [Q-01](./10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica) |
| RF-03 | Identificar y mostrar los requisitos que requieren atención (alertas tempranas). | [A-03](../aspectos.md#a-03--alertas-tempranas-de-requisitos-pendientes) | Q-04 *(pendiente de redactar)* |
| RF-04 | Mantener el sistema disponible para la consulta de información. | [A-04](../aspectos.md#a-04--disponibilidad-del-sistema) | Q-05 *(pendiente de redactar)* |
| RF-05 | Consultar información académica de acuerdo con los permisos de cada usuario. | [A-05](../aspectos.md#a-05--protección-y-control-de-acceso-a-la-información-académica) | [Q-02](./10-quality-requirements.md#escenario-q-02--seguridad-y-aislamiento-de-la-información) |
| RF-06 | Permitir la incorporación de nuevos programas académicos y sus requisitos. | [A-06](../aspectos.md#a-06--extensibilidad-para-múltiples-programas-académicos) | Q-06 *(pendiente de redactar)* |
| RF-07 | Gestionar solicitudes relacionadas con posibles errores en la información, mediante el centro de ayuda. | [A-07](../aspectos.md#a-07--gestión-de-solicitudes-de-estudiantes-en-el-centro-de-ayuda) | Q-07 *(pendiente de redactar)* |
| RF-08 | Mantener un historial de cambios sobre la información académica y los requisitos. | [A-08](../aspectos.md#a-08--historial-de-cambios-sobre-la-información-académica) | Q-08 *(pendiente de redactar)* |
 
En el alcance inicial, DinamikUTB se enfocará principalmente en la **consulta y seguimiento de la información**, evitando que los estudiantes puedan modificar directamente sus datos académicos.

---

## 1.2 Quality Goals

Los principales objetivos de calidad de DinamikUTB se establecen considerando el impacto que una falla tendría sobre el proceso de graduación del estudiante.

### 1. Exactitud y consistencia

**Prioridad: Muy alta**

La información mostrada por el sistema debe corresponder con los datos académicos registrados para cada estudiante.

Un error en el estado de un requisito podría llevar a un estudiante a creer que está listo para graduarse cuando todavía tiene requisitos pendientes, o a considerar que debe cumplir un requisito que ya había completado.

Por esta razón, la exactitud y consistencia de la información constituyen el principal objetivo de calidad del sistema.

---

### 2. Seguridad

**Prioridad: Alta**

DinamikUTB manejará información académica asociada a estudiantes, por lo que el acceso debe estar controlado de acuerdo con el rol del usuario.

El sistema deberá garantizar que un estudiante no pueda consultar información académica perteneciente a otro estudiante y que coordinadores y administradores solamente puedan realizar las acciones correspondientes a sus permisos.

---

### 3. Usabilidad

**Prioridad: Alta**

La información relacionada con el proceso de graduación debe presentarse de forma clara y sencilla.

El estudiante debe poder comprender rápidamente:

- Su porcentaje de avance.
- Los requisitos que ya cumplió.
- Los requisitos que tiene pendientes.
- Los requisitos que requieren atención.

El objetivo es que el usuario pueda adaptarse rápidamente al sistema sin necesitar asistencia constante para utilizarlo.

---

### 4. Rendimiento

**Prioridad: Media**

Las consultas principales relacionadas con el progreso académico deben responder rápidamente.

Como objetivo inicial, el sistema deberá responder las consultas principales en un tiempo máximo de **1 minuto**, sujeto a validación mediante pruebas durante la implementación.

---

### 5. Disponibilidad

**Prioridad: Media**

DinamikUTB debe permanecer disponible para que los usuarios puedan consultar su información cuando la necesiten.

La arquitectura deberá considerar mecanismos que permitan reducir el impacto de fallos parciales y evitar interrupciones innecesarias del servicio.

---

### 6. Trazabilidad

**Prioridad: Baja**

Los cambios realizados sobre información académica o requisitos deben poder ser identificados mediante un historial.

Esto permitirá conocer qué información fue modificada y facilitará la investigación de posibles inconsistencias.

---

### 7. Mantenibilidad

**Prioridad: Baja**

La solución debe poder evolucionar para incorporar nuevos requisitos y programas académicos.

La arquitectura deberá evitar que la incorporación de una nueva carrera implique reconstruir la lógica principal del sistema.

---

## 1.3 Stakeholders

Los principales interesados identificados para DinamikUTB son:

| Interesado | Interés principal | Necesidad |
|---|---|---|
| **Estudiante** | Conocer su progreso hacia la graduación | Consultar requisitos cumplidos, pendientes y porcentaje de avance de forma clara y segura. |
| **Coordinador académico** | Supervisar y gestionar la información de los estudiantes de su programa | Consultar estudiantes de su carrera, gestionar requisitos y atender solicitudes relacionadas con inconsistencias. |
| **Administrador** | Gestionar el funcionamiento general del sistema | Administrar usuarios, programas académicos, requisitos y permisos del sistema. |

---

## 1.4 Goals

Los principales objetivos funcionales del proyecto son:

- Centralizar la información relacionada con los requisitos de graduación.
- Facilitar al estudiante la consulta de su progreso académico.
- Calcular automáticamente el porcentaje de avance hacia la graduación.
- Identificar los requisitos pendientes.
- Facilitar la detección y atención de posibles errores en la información.
- Permitir la gestión de requisitos por programa académico.
- Mantener control de acceso de acuerdo con los diferentes roles.
- Diseñar una solución que pueda extenderse a diferentes programas académicos.

---

## 1.5 Scope

El proyecto se desarrollará inicialmente como una solución académica para demostrar la arquitectura y las funcionalidades principales de DinamikUTB.

El sistema utilizará una **base de datos propia**, debido a que inicialmente no se contempla una integración directa con los sistemas académicos internos de la Universidad Tecnológica de Bolívar.

Las cuentas de los estudiantes serán creadas previamente por el administrador. Los estudiantes no realizarán un proceso de registro público, sino que accederán mediante correo y contraseña proporcionados por la institución.

La solución deberá estar preparada para manejar diferentes programas académicos y permitir la incorporación progresiva de sus requisitos.

La implementación inicial se concentrará en la consulta y seguimiento de los requisitos, dejando para futuras versiones posibles integraciones con sistemas institucionales u otras funcionalidades adicionales.
