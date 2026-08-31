# 2. Architecture Constraints

Las restricciones de DinamikUTB se clasifican en tres categorías: **técnicas, organizativas y legales**. Estas restricciones provienen principalmente del alcance del proyecto y condicionan las decisiones de arquitectura y el desarrollo del sistema.

---

## 2.1 Technical Constraints

### Tecnologías permitidas

El curso establece las tecnologías disponibles para el desarrollo de las principales partes de la aplicación.

Para el **backend** se podrá utilizar una de las siguientes tecnologías:

- **NestJS**
- **FastAPI**

Para el **frontend** se podrá utilizar una de las siguientes tecnologías:

- **Flutter**
- **Next.js**


### Base de datos propia

Inicialmente, DinamikUTB utilizará una base de datos propia para almacenar la información necesaria para el funcionamiento del sistema.

La elección entre una base de datos SQL o NoSQL aún no ha sido definida y será determinada posteriormente de acuerdo con las necesidades del sistema. Dado que el escenario de calidad Q-01 (exactitud) exige transacciones consistentes sobre actualizaciones de varios campos (ver `04-solution-strategy.md`, sección 4.8.1), una base de datos relacional es la opción que mejor se alinea con lo ya decidido.

### Sin integración inicial con sistemas institucionales

En la primera versión no se contempla una integración directa con los sistemas académicos internos de la Universidad Tecnológica de Bolívar.

Esto se debe a que el proyecto no dispone actualmente de acceso a dichos sistemas ni de los permisos necesarios para consultar directamente su información.

La arquitectura deberá permitir que una futura integración pueda incorporarse sin reconstruir completamente el sistema.

### Soporte para múltiples programas académicos

La arquitectura no debe quedar limitada a una única carrera.

Aunque el desarrollo inicial pueda realizarse con información de un conjunto limitado de programas, el sistema debe poder incorporar posteriormente nuevos programas académicos y sus respectivos requisitos.

### Autenticación y autorización

El sistema debe contemplar mecanismos de autenticación y autorización debido a la existencia de información académica y diferentes roles de usuario.

Los roles definidos inicialmente son:

- Estudiante.
- Coordinador académico.
- Administrador.

El acceso a la información debe estar controlado de acuerdo con los permisos correspondientes a cada rol. Esta restricción es la que sustenta directamente el escenario Q-02 y su táctica de autenticación centralizada en el módulo `usuarios/` (ver `04-solution-strategy.md`, sección 4.8.1).

---

## 2.2 Organizational Constraints

### Proyecto académico de semestre

DinamikUTB se desarrolla como parte de un proyecto académico con una duración determinada durante el semestre.

Por esta razón, el sistema debe desarrollarse de manera progresiva, priorizando las funcionalidades y decisiones arquitectónicas más importantes dentro del tiempo disponible.

### Alcance inicial

El alcance inicial se concentra en el seguimiento y consulta de los requisitos de graduación.

No se contempla inicialmente una integración completa con los sistemas institucionales ni la automatización de procesos externos.

Las funcionalidades adicionales podrán ser consideradas como evolución futura del sistema.

### Administración de cuentas

Los estudiantes no tendrán un proceso de registro público.

Las cuentas serán creadas previamente por el administrador y los estudiantes accederán mediante el correo y contraseña proporcionados.

### Roles y responsabilidades

Cada tipo de usuario tendrá responsabilidades diferentes:

- **Estudiante:** consulta su información académica y puede enviar solicitudes mediante el centro de ayuda (RF-07). No puede modificar directamente sus datos académicos.
- **Coordinador académico:** consulta estudiantes de su programa, gestiona los requisitos correspondientes y atiende solicitudes relacionadas con posibles inconsistencias.
- **Administrador:** gestiona usuarios, programas académicos, requisitos y permisos generales del sistema.

### Modificación controlada de información

Los estudiantes no podrán modificar directamente su información académica.

Cuando un estudiante detecte un posible error, deberá enviar una solicitud mediante el centro de ayuda de la aplicación.

Las modificaciones serán realizadas por usuarios autorizados, principalmente coordinadores o administradores según el tipo de información y los permisos establecidos.

### Evolución del sistema

Los requisitos de graduación pueden cambiar y pueden existir diferencias entre programas académicos.

Por esta razón, la solución debe permitir incorporar nuevos requisitos y programas sin requerir una reconstrucción completa del sistema.

---

## 2.3 Legal Constraints

### Protección de datos personales y académicos

DinamikUTB manejará información asociada a estudiantes, incluyendo información académica y datos necesarios para su identificación y acceso al sistema.

Una futura implementación institucional deberá cumplir con las normas y políticas aplicables al tratamiento, protección y acceso de datos personales y académicos.

### Acceso autorizado a la información

La información académica no debe estar disponible para usuarios que no tengan autorización para consultarla.

El sistema deberá establecer controles de acceso de acuerdo con los roles definidos y evitar que un estudiante pueda consultar información perteneciente a otro estudiante.

### Alcance legal del proyecto académico

No se ha definido dentro del alcance actual una normativa institucional específica que deba implementarse como requisito legal del prototipo.

Por lo tanto, las consideraciones legales de una eventual implementación real dentro de la Universidad Tecnológica de Bolívar deberán ser revisadas y validadas por las áreas institucionales correspondientes.

---

## 2.4 Constraints Summary

| Tipo | Restricción | Impacto en la arquitectura |
|---|---|---|
| **Técnica** | Backend limitado a NestJS o FastAPI (en la práctica: FastAPI) | Condiciona la tecnología utilizada para los servicios del backend. |
| **Técnica** | Frontend limitado a Flutter o Next.js (en la práctica: Flutter) | Condiciona la tecnología utilizada para la interfaz de usuario. |
| **Técnica** | Base de datos propia, motor aún no definido | La información necesaria para el sistema debe ser administrada por DinamikUTB. |
| **Técnica** | Sin integración inicial con sistemas institucionales | Se requiere una solución independiente y preparada para futuras integraciones. |
| **Técnica** | Soporte para múltiples programas académicos | La arquitectura debe permitir incorporar nuevas carreras y requisitos. |
| **Técnica** | Autenticación y autorización | Se requiere control de acceso según los roles del sistema. |
| **Organizativa** | Proyecto desarrollado durante el semestre | Se debe priorizar un alcance realizable y desarrollar progresivamente la solución. |
| **Organizativa** | Cuentas creadas previamente por el administrador | No se requiere registro público de estudiantes. |
| **Organizativa** | Roles diferenciados | Las responsabilidades y permisos deben estar separados entre estudiantes, coordinadores y administradores. |
| **Organizativa** | Estudiantes no modifican directamente sus datos | Las modificaciones deben realizarse mediante usuarios autorizados. |
| **Organizativa** | Evolución de requisitos y programas | La solución debe poder crecer durante y después del proyecto. |
| **Legal** | Protección de datos personales y académicos | Se debe controlar el acceso y tratamiento de la información. |
| **Legal** | Acceso autorizado a información académica | Los usuarios solo deben acceder a la información que sus permisos permitan. |
| **Legal** | Normativa institucional pendiente de validación | Una futura implementación real deberá ser revisada por las áreas correspondientes. |
