---
id: ADR-0010
title: Decisión de extraer o no extraer un módulo del monolito
status: Aceptado
date: 2026-10-18
deciders: Equipo de arquitectura DinamikUTB
---

# ADR-0010: Decisión de extraer o no extraer un módulo del monolito

![Status: Aceptado](https://img.shields.io/badge/Status-Accepted-brightgreen?style=flat-square)
![Date: 2026--10--18](https://img.shields.io/badge/Date-2026--10--18-blue?style=flat-square)
![Scope: Architecture](https://img.shields.io/badge/Scope-Architecture-orange?style=flat-square)

---

## 1. Contexto y descripción del problema

La integración principal de DinamikUTB es Flutter → FastAPI (`GET /requisitos/{id}`, `PUT /requisitos/{id}/estado`) y FastAPI → base de datos. El análisis de modos de fallo de esa integración está en [11-risks-and-technical-debt.md](../arc42/11-risks-and-technical-debt.md), sección 11.5.

Al analizar qué pasa si el otro lado no responde, responde tarde o responde dos veces, surge una pregunta de arquitectura: ¿conviene extraer algún módulo (por ejemplo `requisitos/`) del monolito modular ([ADR-0001](0001-seleccion-monolito-modular.md)) para aislar fallos? Este ADR evalúa esa pregunta y deja la alternativa **no extraer** como opción evaluada, con criterios, y no como ausencia de decisión.

## 2. Criterios de decisión

| Criterio | Pregunta que responde |
| :--- | :--- |
| **C1. Consistencia (Q-01)** | ¿La extracción mantiene las actualizaciones de requisitos en una sola transacción? |
| **C2. Fallos parciales** | ¿Extraer reduce el radio de impacto de un fallo, o agrega nuevos modos de fallo? |
| **C3. Costo (límite de $0)** | ¿Cabe en la capa gratuita? (`docs/costos.md`: 750 h/mes de Render solo alcanzan para un servicio siempre activo). |
| **C4. Carga y escalado independiente** | ¿Algún módulo tiene un perfil de carga distinto al resto? |
| **C5. Propiedad de datos** | ¿Los datos del módulo tienen un dueño único que se pueda separar sin compartir tablas? ([08](../arc42/08-cross-cutting-concepts.md), 8.4–8.5) |
| **C6. Capacidad del equipo** | ¿Se puede operar y probar el resultado dentro del semestre? |

## 3. Alternativas consideradas

### 3.1 Extraer `requisitos/` como servicio independiente

* **C1:** empeora. Hoy `requisitos/` y `estudiantes/` comparten base y proceso; separarlos obliga a una llamada de red entre ellos para el cálculo de A-02 y a resolver consistencia entre dos almacenes.
* **C2:** empeora. Convierte una llamada de función en una llamada de red, con los tres modos de fallo (no responde, responde tarde, responde dos veces) en un punto donde hoy no existen.
* **C3:** no cabe. Un segundo servicio gratuito supera las 750 h/mes (`docs/costos.md`); exigiría plan de pago y tarjeta, fuera de la restricción de [02](../arc42/02-architecture-constraints.md).
* **C4:** sin ventaja. El volumen esperado es de ~2 000 cargas/mes (`docs/costos.md`).
* **C5:** sin ventaja. `Requisito` ya tiene dueño único y ninguna escritura cruzada (auditoría de S6 y S9).
* **C6:** no viable. Exige operar dos despliegues, contratos entre ellos y pruebas de integración, sin autenticación implementada aún.
* **Descartada.**

### 3.2 Extraer solo el trabajo periódico de alertas (A-03) como job independiente

* Es el único candidato con perfil de ejecución distinto (periódico, no interactivo), y ya está contemplado en la vista de despliegue (GitHub Actions `schedule:`).
* **Hoy no tiene código** y su mecanismo de disparo no está decidido ([ADR-0009](0009-no-incorporacion-componente-generativo.md) solo fija que será una regla determinista). Decidir su extracción ahora sería diseñar sin requisito concreto.
* **Pospuesta**: se reevalúa cuando A-03 tenga código (ver sección 6).

### 3.3 No extraer: mantener el monolito modular y mitigar los fallos en los bordes

* **C1:** se conserva la transacción única.
* **C2:** la única frontera de red es Flutter ↔ FastAPI, y se mitiga ahí (timeout y reintento con espera creciente para consultas; operación de escritura idempotente). No se agregan fronteras nuevas.
* **C3:** cabe en $0.
* **C4/C5:** no hay evidencia de necesidad.
* **C6:** viable, con las mitigaciones ya implementadas y probadas.
* **Seleccionada.**

## 4. Decisión

**No se extrae ningún módulo del monolito.** Los fallos de la integración principal se mitigan en el borde cliente-servidor (sección 11.5 de arc42), no separando módulos.

> **Justificación principal:** extraer `requisitos/` **crearía** una integración con los mismos tres modos de fallo que hoy se están tratando de mitigar, rompería la transacción única que sostiene Q-01, y no cabe en el límite de costo. La decisión no es "no dio tiempo": es que ningún criterio de la sección 2 favorece la extracción con la evidencia actual.

## 5. Consecuencias

### Positivas

* Los fallos parciales se concentran en una sola frontera, ya cubierta con pruebas.
* Se mantiene la consistencia transaccional de Q-01 y el costo de $0.

### Negativas

* **Punto único de fallo:** si el backend cae, todo cae (ya reconocido en ADR-0001 y ADR-0004). La mitigación reduce el impacto de fallos transitorios, no de una caída prolongada.
* **Sin aislamiento de carga:** un módulo lento afecta a los demás. Hoy no hay evidencia de que ocurra.

## 6. Cuándo se revisa esta decisión

Se abre un nuevo ADR si ocurre alguna de estas condiciones:

| Condición | Módulo candidato |
| :--- | :--- |
| A-03 tiene código y su ejecución periódica compite con las consultas interactivas | Job de alertas |
| La carga de un módulo exige escalado independiente medido (no supuesto) | El módulo medido |
| Se obtiene presupuesto que levanta la restricción de $0 y un equipo que opere dos despliegues | Cualquiera, con evidencia de C2 y C4 |
| Se integra un sistema institucional externo (capa anticorrupción, ver 08) | Módulo de integración |

## 7. Relación con atributos de calidad

| Atributo | Relación con la decisión |
| :--- | :--- |
| **Exactitud / Consistencia** | Se preserva la transacción única de `requisitos/` (Q-01). |
| **Disponibilidad** | No mejora el aislamiento de fallos; se compensa con mitigación en el cliente (Q-05). |
| **Mantenibilidad** | Una sola unidad desplegable, probada con las suites existentes. |

## 8. Estado de la decisión

**Aceptado.** No reemplaza ADR-0001 ni ADR-0004; los confirma con evidencia del análisis de fallos.

## 9. Trazabilidad

| Elemento | Referencia |
| :--- | :--- |
| **Aspectos relacionados** | [A-01](../aspectos.md#a-01--seguimiento-del-cumplimiento-de-requisitos), [A-04](../aspectos.md#a-04--disponibilidad-del-sistema) |
| **Escenarios de calidad** | [Q-01](../arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica), [Q-05](../arc42/10-quality-requirements.md#escenario-q-05--disponibilidad-del-sistema) |
| **Análisis de fallos** | [11-risks-and-technical-debt.md](../arc42/11-risks-and-technical-debt.md), sección 11.5 |
| **Código de la mitigación** | `frontend/lib/requisitos/requisitos_service.dart` |
| **Pruebas** | `frontend/test/requisitos_service_test.dart`, `backend/tests/test_idempotencia.py`, `backend/tests/test_health.py` |
