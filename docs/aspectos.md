# Aspect Driven Development

> Este documento registra los atributos de calidad considerados para el desarrollo del proyecto **DinamikUTB**

--- 

# Aspectos Planteados

| **ID**   | **Aspecto** | **Requisito**   | **C4**    | **ADR**   | **Código**   | **Pruebas**   | **Evidencia**   |
| -------- | ----------- | --------------- | --------- | --------- | ------------ | ------------- | --------------- |
|A-01      | Seguimiento del cumplimiento de requisitos |RF-01  | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | 
|A-02      | Cálculo correcto del estado de graduación  |RF-02  | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | 
|A-03      | Alertas tempranas de requisitos pendientes |RF-03  | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | 
|A-04      | Disponibilidad del sistema                 |RF-04  | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |                  
|A-05      | Protección y control de acceso a la información académica |RF-05 | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | 
|A-06      | Extensibilidad para múltiples programas académicos |RF-06 | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | 

---

# Descripción de Aspectos Planteados

## Aspecto A-01
**Para:** Estudiantes universitarios.

**Cuestión:** El estudiante no cuenta actualmente con una forma centralizada de conocer qué requisitos de grado ha cumplido y cuáles tiene pendientes.

**Valor:** Permitir visualizar el avance real hacia la graduación desde un único lugar.

**Deber:** El sistema debe permitir al estudiante consultar el estado de cumplimiento de los requisitos necesarios para su graduación.


## Aspecto A-02
**Para:** Estudiantes próximos a graduarse.

**Cuestión:** Un error en el cálculo de los requisitos podría llevar al estudiante a creer que puede graduarse cuando todavía tiene requisitos pendientes.

**Valor:** Garantizar que el estado mostrado por la plataforma corresponda realmente al cumplimiento académico.

**Deber:** El sistema debe calcular de forma correcta y consistente el cumplimiento de los requisitos de grado.


## Aspecto A-03
**Para:** Estudiantes que se aproximan a los últimos semestres.

**Cuestión:** Algunos estudiantes descubren demasiado tarde que tienen un requisito pendiente, provocando posibles retrasos en su graduación.

**Valor:** Advertir anticipadamente sobre requisitos que podrían poner en riesgo la graduación.

**Deber:** El sistema debe generar alertas cuando un requisito crítico permanezca pendiente y exista riesgo de retraso


## Aspecto A-04
**Para:** Estudiantes que necesitan consultar su progreso.

**Cuestión:** Si la plataforma no está disponible, el estudiante no podrá consultar información importante relacionada con su proceso de graduación.

**Valor:** Mantener el sistema operativo y accesible ante fallos parciales o períodos de alta demanda.

**Deber:** DinamikUTB debe mantener disponible el servicio principal incluso ante fallos parciales.


## Aspecto A-05
**Para:** Estudiantes y personal autorizado.

**Cuestión:** La información académica corresponde a cada estudiante y no debería estar disponible para usuarios no autorizados.

**Valor:** Garantizar que cada usuario pueda consultar únicamente la información que le corresponde.

**Deber:** El sistema debe controlar el acceso a la información académica mediante autenticación y autorización.


## Aspecto A-06
**Para:** Institución y futuros estudiantes de otros programas.

**Cuestión:** El alcance inicial se limita a un programa académico, pero la solución debería poder crecer posteriormente.

**Valor:** Permitir que **DinamikUTB** pueda crecer sin tener que reconstruir completamente el sistema.

**Deber:** La arquitectura debe permitir incorporar nuevos programas académicos sin modificar la lógica principal de evaluación de requisitos.

---
