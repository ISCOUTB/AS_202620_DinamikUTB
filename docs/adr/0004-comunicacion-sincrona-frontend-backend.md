---
id: ADR-0004
title: Comunicación síncrona entre frontend y backend
status: Aceptado
date: 2026-09-20
deciders: Equipo de arquitectura DinamikUTB
---

# ADR-0004: Comunicación síncrona entre frontend y backend

![Status: Aceptado](https://img.shields.io/badge/Status-Accepted-brightgreen?style=flat-square)
![Date: 2026--09--20](https://img.shields.io/badge/Date-2026--09--20-blue?style=flat-square)
![Scope: Integration](https://img.shields.io/badge/Scope-Integration-orange?style=flat-square)

---

## 1. Contexto y descripción del problema

Desde el corte vertical de la semana 4, el frontend Flutter se comunica con el backend FastAPI mediante peticiones HTTP directas (`RequisitosService`, `EstudiantesService`), esperando la respuesta antes de continuar. Esta decisión nunca se formalizó explícitamente como una elección entre comunicación **síncrona** (petición-respuesta, el cliente espera) y **asíncrona** (mensajería, el cliente no espera una respuesta inmediata).

Este ADR cierra esa brecha, evaluando la elección ya implementada contra la alternativa de introducir un mecanismo de mensajería (cola de eventos, publicación/suscripción) para desacoplar frontend y backend.

---

## 2. Factores de decisión

| Factor | Descripción |
| :--- | :--- |
| **Consistencia inmediata** | El estudiante que actualiza el estado de un requisito necesita saber, en la misma interacción, si la operación tuvo éxito — no puede quedar en duda mientras un mensaje se procesa en segundo plano. |
| **Simplicidad operativa** | El proyecto es un monolito modular (ADR-0001) de alcance semestral; introducir un broker de mensajería (RabbitMQ, Kafka) agrega una pieza de infraestructura sin un caso de uso que la justifique todavía. |
| **Acoplamiento temporal aceptable** | El sistema no tiene hoy ningún flujo que necesite continuar funcionando si el backend está caído (no hay colas de trabajo, notificaciones diferidas, ni procesamiento en lote). |
| **Alcance de A-03 (alertas tempranas)** | Es el único aspecto que, a futuro, podría beneficiarse de procesamiento asíncrono (por ejemplo, un job periódico que revise requisitos vencidos). Hoy sigue sin mecanismo de disparo decidido (`docs/aspectos.md`), por lo que no es una necesidad actual. |

---

## 3. Alternativas consideradas

### 3.1 Comunicación síncrona (HTTP request-response)

* **Ventajas:** El cliente conoce el resultado de la operación de inmediato — crítico para Q-01 (exactitud), donde una actualización de estado de requisito debe confirmarse o rechazarse en el momento. Es el patrón que FastAPI y el cliente HTTP de Flutter (`package:http`) ya soportan sin dependencias adicionales. Más simple de razonar, probar (como ya lo demuestran `test_requisitos.py` y `test_contrato.py`) y depurar.
* **Desventajas:** Introduce acoplamiento temporal — frontend y backend deben estar disponibles al mismo tiempo para que una operación se complete. Si el backend está caído, el estudiante no puede consultar ni actualizar nada, sin ninguna forma de trabajo desconectado.

### 3.2 Comunicación asíncrona (mensajería)

* **Ventajas:** Desacopla temporalmente a los servicios — el emisor no depende de que el receptor esté disponible en el instante del envío. Facilitaría escenarios futuros como notificaciones o alertas tempranas (A-03) sin bloquear la interacción del usuario.
* **Desventajas:** Introduce consistencia eventual: el estudiante no tendría confirmación inmediata de que su actualización se aplicó, lo cual entra en conflicto directo con la medida de Q-01 ("100% de los datos mostrados debe corresponder con la información registrada", verificado de forma síncrona en los 20 casos de Pytest). Requiere infraestructura adicional (broker de mensajería) no justificada por el alcance actual, mismo argumento ya usado en el ADR-0003 para descartar un motor de base de datos con mayor complejidad operativa.

> [!Note]
> **¿Por qué no se consideró un híbrido?** Podría pensarse en mantener consultas síncronas y mover solo A-03 (alertas) a un mecanismo asíncrono. Se descarta por ahora porque A-03 no tiene ni siquiera su mecanismo de disparo decidido — introducir mensajería para un aspecto sin diseño concreto sería sobre-ingeniería prematura.

---

## 4. Decisión

Se mantiene **comunicación síncrona (HTTP request-response)** entre frontend y backend como estrategia de integración para DinamikUTB.

> **Justificación principal:** la medida de Q-01 exige que la información mostrada corresponda de forma inmediata y verificable con lo registrado; un modelo asíncrono introduciría una ventana de inconsistencia eventual incompatible con esa medida. El costo de acoplamiento temporal (frontend y backend deben estar activos simultáneamente) se considera aceptable dado el alcance actual: un sistema de consulta académica sin procesos de larga duración ni necesidad de desacoplar productores y consumidores.

Esta decisión no reemplaza al ADR-0001 (monolito modular) ni al ADR-0002 (FastAPI/Flutter): es compatible con ambos, y describe el patrón de comunicación entre los contenedores ya definidos en el C4 de nivel 2.

---

## 5. Consecuencias

### Consecuencias positivas

* **Trazabilidad simple:** cada operación tiene una respuesta directa que se puede probar de forma determinística, como ya lo hacen `test_requisitos.py`, `test_estudiantes.py` y `test_contrato.py`.
* **Sin infraestructura adicional:** no se requiere desplegar ni mantener un broker de mensajería durante el desarrollo del proyecto.

### Consecuencias negativas

* **Acoplamiento temporal:** si el backend no está disponible, el frontend no tiene ninguna función utilizable — no hay caché local ni modo sin conexión. Esto es un riesgo directo sobre Q-05 (disponibilidad) que ya se había anotado como debilidad de SQLite en el ADR-0003, y se reafirma aquí desde el ángulo de integración.
* **No escalable a flujos de alta latencia:** si en el futuro se agregan operaciones que tarden varios segundos (por ejemplo, un cálculo masivo de avance para todos los estudiantes de un programa), el modelo síncrono obligaría al cliente a esperar esa duración completa, degradando la experiencia. Revisar si A-06 (extensibilidad) llega a ese punto.

---

## 6. Relación con atributos de calidad

| Atributo | Relación con la decisión |
| :--- | :--- |
| **Exactitud / Consistencia** | La comunicación síncrona es la que permite que Q-01 se verifique con una medida inmediata (100% de correspondencia), sin ventana de inconsistencia eventual. |
| **Seguridad** | No incide directamente; la autenticación (cuando se implemente en `usuarios/`) funciona igual en ambos modelos. |
| **Usabilidad** | Los tres estados manejados en Flutter (cargando, error, listo — táctica de Q-03) dependen de que exista una respuesta única y determinística por petición, propia del modelo síncrono. |
| **Disponibilidad** | Principal atributo afectado negativamente: el acoplamiento temporal significa que la caída del backend inhabilita el frontend por completo. Documentado como consecuencia negativa. |
| **Mantenibilidad** | Un modelo síncrono es más simple de depurar y probar con las herramientas ya usadas en el proyecto (Pytest, FastAPI TestClient). |

---

## 7. Relación con las restricciones del proyecto

Esta decisión es coherente con `02-architecture-constraints.md` (simplicidad operativa para un proyecto de alcance semestral) y con el ADR-0001 (monolito modular): ninguna restricción del curso exige mensajería, y el alcance actual no la necesita.

---

## 8. Estado de la decisión

**Aceptado.**

Esta decisión formaliza un patrón que el equipo ya venía utilizando desde el corte vertical de S4. Si en una semana posterior (por ejemplo, al implementar A-03 con un mecanismo de disparo real) surge una necesidad concreta de desacoplamiento, deberá evaluarse mediante un nuevo ADR, sin reemplazar este mientras el resto del sistema siga siendo síncrono.

---

## 9. Trazabilidad

| Elemento | Referencia |
| :--- | :--- |
| **Aspectos que sustenta** | [A-01](../aspectos.md#a-01--seguimiento-del-cumplimiento-de-requisitos), [A-02](../aspectos.md#a-02--cálculo-correcto-del-estado-de-graduación) |
| **Escenario de calidad principal** | [Q-01](../arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica) |
| **Elemento C4** | Relación `frontend → backend` ("Consume la API", HTTP/JSON) en `docs/c4/contenedores.puml` |
| **Commits que lo implementan** | Commits del corte vertical de S4 (`frontend/lib/requisitos/requisitos_service.dart`, `backend/app/requisitos/router.py`) |
| **Pruebas que lo cubren** | `backend/tests/test_requisitos.py`, `backend/tests/test_estudiantes.py`, `backend/tests/test_contrato.py`, `frontend/test/widget_test.dart` |
