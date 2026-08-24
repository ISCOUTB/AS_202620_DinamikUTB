# Aspect Driven Development

> Este documento registra los aspectos del sistema que requieren trazabilidad desde el requisito hasta su evidencia de calidad en el proyecto **DinamikUTB**.

---

# Aspectos planteados

| ID | Aspecto | Requisito | Escenario de calidad | C4 | ADR | Código | Pruebas | Evidencia |
|---|---|---|---|---|---|---|---|---|
| A-01 | Seguimiento del cumplimiento de requisitos | RF-01 | [Q-01](arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica), [Q-03](arc42/10-quality-requirements.md#escenario-q-03--facilidad-de-comprensión-de-la-información) | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |
| A-02 | Cálculo correcto del estado de graduación | RF-02 | [Q-01](arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica) | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |
| A-03 | Alertas tempranas de requisitos pendientes | RF-03 | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |
| A-04 | Disponibilidad del sistema | RF-04 | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |
| A-05 | Protección y control de acceso a la información académica | RF-05 | [Q-02](arc42/10-quality-requirements.md#escenario-q-02--seguridad-y-aislamiento-de-la-información) | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |
| A-06 | Extensibilidad para múltiples programas académicos | RF-06 | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |

---

# Descripción de aspectos planteados

## A-01 — Seguimiento del cumplimiento de requisitos

**Para:** Estudiantes universitarios.

**Cuestión:** El estudiante no cuenta con una forma centralizada de conocer qué requisitos de grado ha cumplido y cuáles tiene pendientes.

**Valor:** Permitir visualizar de forma clara el avance hacia la graduación y conocer los requisitos que todavía debe cumplir.

**Deber:** DinamikUTB debe permitir al estudiante consultar el estado de los requisitos necesarios para su graduación.

**Escenarios relacionados:** [Q-01](arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica), [Q-03](arc42/10-quality-requirements.md#escenario-q-03--facilidad-de-comprensión-de-la-información).

---

## A-02 — Cálculo correcto del estado de graduación

**Para:** Estudiantes próximos a completar su programa académico.

**Cuestión:** Un cálculo incorrecto del estado de los requisitos podría llevar al estudiante a creer que ha cumplido condiciones que realmente están pendientes, o al contrario.

**Valor:** Garantizar que el porcentaje de avance y el estado de los requisitos representen correctamente la información registrada.

**Deber:** El sistema debe calcular de forma correcta y consistente el estado de cumplimiento de los requisitos de graduación.

**Escenario relacionado:** [Q-01](arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica).

---

## A-03 — Alertas tempranas de requisitos pendientes

**Para:** Estudiantes que se aproximan a los últimos semestres.

**Cuestión:** Algunos estudiantes pueden descubrir demasiado tarde que tienen un requisito pendiente, provocando posibles retrasos en su graduación.

**Valor:** Permitir que el estudiante identifique con anticipación los requisitos que requieren atención.

**Deber:** DinamikUTB debe identificar los requisitos pendientes que puedan afectar el proceso de graduación y proporcionar información o alertas oportunas.

**Escenario relacionado:** Pendiente de definir.

---

## A-04 — Disponibilidad del sistema

**Para:** Estudiantes, coordinadores y administradores.

**Cuestión:** Si la plataforma no está disponible, los usuarios no podrán consultar o gestionar la información necesaria para el seguimiento de los requisitos.

**Valor:** Mantener el sistema accesible cuando los usuarios necesiten consultar la información académica.

**Deber:** DinamikUTB debe mantener disponible el servicio principal y minimizar las interrupciones que impidan consultar la información.

**Escenario relacionado:** Pendiente de definir.

---

## A-05 — Protección y control de acceso a la información académica

**Para:** Estudiantes, coordinadores y administradores autorizados.

**Cuestión:** La información académica pertenece a cada estudiante y no debe estar disponible para usuarios que no tengan los permisos correspondientes.

**Valor:** Proteger la información académica y garantizar que cada usuario pueda acceder únicamente a la información permitida según su rol.

**Deber:** El sistema debe autenticar a los usuarios y controlar el acceso a la información académica de acuerdo con los permisos de cada rol.

**Escenario relacionado:** [Q-02](arc42/10-quality-requirements.md#escenario-q-02--seguridad-y-aislamiento-de-la-información).

---

## A-06 — Extensibilidad para múltiples programas académicos

**Para:** Coordinadores y administradores, y posteriormente estudiantes de diferentes programas académicos.

**Cuestión:** DinamikUTB debe poder manejar los requisitos de diferentes programas académicos de la UTB sin tener que reconstruir el sistema para cada carrera.

**Valor:** Permitir que la solución pueda crecer y adaptarse a diferentes programas académicos.

**Deber:** La arquitectura debe permitir incorporar nuevos programas y sus requisitos sin modificar la lógica principal del sistema.

**Escenario relacionado:** Pendiente de definir.

---

# Relación con los escenarios de calidad

| Escenario | Atributo de calidad | Aspecto relacionado |
|---|---|---|
| [Q-01](arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica) | Exactitud / Consistencia | A-01, A-02 |
| [Q-02](arc42/10-quality-requirements.md#escenario-q-02--seguridad-y-aislamiento-de-la-información) | Seguridad | A-05 |
| [Q-03](arc42/10-quality-requirements.md#escenario-q-03--facilidad-de-comprensión-de-la-información) | Usabilidad | A-01 |

> Los campos C4, ADR, código, pruebas y evidencia se encuentran pendientes porque todavía no existen los elementos correspondientes. Se actualizarán a medida que avance la implementación del sistema.
