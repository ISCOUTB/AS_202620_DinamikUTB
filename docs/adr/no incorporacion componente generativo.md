---
id: ADR-0009
title: No incorporación de un componente generativo al sistema desplegado
status: Aceptado
date: 2026-10-01
deciders: Equipo de arquitectura DinamikUTB
---

# ADR-0009: No incorporación de un componente generativo al sistema desplegado

![Status: Aceptado](https://img.shields.io/badge/Status-Accepted-brightgreen?style=flat-square)
![Date: 2026--10--01](https://img.shields.io/badge/Date-2026--10--01-blue?style=flat-square)
![Scope: Feature](https://img.shields.io/badge/Scope-Feature-orange?style=flat-square)

---

## 1. Contexto y descripción del problema

DinamikUTB usa Claude como herramienta de desarrollo (código, documentación, configuración — ver `docs/ia.md`), pero ningún endpoint ni funcionalidad del sistema **desplegado** invoca un modelo generativo en tiempo de ejecución. Esta semana se evalúa explícitamente si correspondería incorporar uno y, si no, por qué.

El candidato más cercano a una necesidad real es **A-03 (alertas tempranas)**, que desde S1 figura como "mecanismo de disparo sin decidir". Alguien podría proponer que un LLM redacte el texto de la alerta o decida cuáles requisitos son "críticos".

## 2. Factores de decisión

| Factor | Descripción |
| :--- | :--- |
| **Costo dentro del límite de un proyecto de semestre** | `docs/costos.md` mantiene el sistema en USD 0/mes; cualquier componente generativo con costo por operación rompe ese presupuesto. |
| **Determinismo exigido por Q-01** | La medida de Q-01 exige 100% de correspondencia entre lo mostrado y lo registrado; un componente generativo introduce no determinismo que complicaría verificar esa medida. |
| **Alcance real de A-03** | Decidir si un requisito está "próximo a vencer" es una comparación de fechas, no una tarea que necesite comprensión de lenguaje natural ni generación de contenido. |
| **Disponibilidad y degradación del proveedor** | Incorporar un proveedor externo de IA generativa añade un punto de falla y de latencia que hoy el sistema no tiene (ver riesgos ya documentados para Render en `11-risks-and-technical-debt.md`). |

## 3. Alternativas consideradas

### 3.1 Usar un LLM para generar el texto de las alertas de A-03

* **Ventajas:** Texto más natural o personalizado por estudiante.
* **Desventajas:** Costo por operación no presupuestado; latencia adicional; no determinismo en una funcionalidad que depende de una comparación de fechas, no de redacción; introduce un proveedor externo nuevo con su propio riesgo de disponibilidad.
* **Descartada.**

### 3.2 Usar un LLM para decidir qué requisitos son "críticos" a partir de los datos del estudiante

* **Ventajas:** Podría adaptar la prioridad según patrones no explícitos.
* **Desventajas:** La definición de "crítico" en A-03 es una regla de negocio simple (vencimiento próximo según el calendario académico), no un problema de clasificación que justifique un modelo. Añadir un LLM aquí sería resolver con la herramienta equivocada un problema que una condición si/entonces resuelve igual de bien, y sin el costo ni el riesgo.
* **Descartada.**

### 3.3 No incorporar ningún componente generativo al sistema desplegado

* **Ventajas:** Mantiene el costo en $0, mantiene el determinismo que exige Q-01, no agrega un proveedor ni un punto de falla externo, y resuelve A-03 con una regla simple cuando se implemente.
* **Desventajas:** Ninguna identificada para el alcance actual del proyecto.
* **Seleccionada.**

## 4. Decisión

**No se incorpora ningún componente generativo al sistema desplegado de DinamikUTB.** El uso de IA generativa (Claude) queda limitado a herramienta de apoyo durante el desarrollo, documentada en `docs/ia.md`, y no a una funcionalidad del producto en ejecución.

Cuando A-03 tenga código, su mecanismo de disparo se resolverá con una regla determinista (comparación de fecha límite contra la fecha actual), no con un modelo generativo.

## 5. Consecuencias

### Consecuencias positivas

* El costo del sistema se mantiene en $0/mes (`docs/costos.md`).
* Ninguna funcionalidad depende de la disponibilidad de un proveedor de IA externo.
* Q-01 se mantiene verificable de forma determinista.

### Consecuencias negativas

* Si en el futuro el proyecto quisiera personalización real de contenido (por ejemplo, recomendaciones de electivas según el historial del estudiante), esta decisión tendría que revisarse con un ADR nuevo.

## 6. Relación con atributos de calidad

| Atributo | Relación con la decisión |
| :--- | :--- |
| **Exactitud / Consistencia** | Evita introducir no determinismo en un sistema cuya medida principal (Q-01) exige exactitud verificable. |
| **Disponibilidad** | No suma un proveedor externo adicional como punto de falla, más allá de los ya aceptados en ADR-0005/0007. |
| **Mantenibilidad** | Una regla simple para A-03 es más fácil de probar y explicar en sustentación que el comportamiento de un modelo. |

## 7. Relación con las restricciones del proyecto

Sostiene el límite de costo cero de [02-architecture-constraints.md](../arc42/02-architecture-constraints.md) y no contradice ninguna decisión previa.

## 8. Estado de la decisión

**Aceptado.** Se revisará si A-03 u otra funcionalidad futura presenta un caso de uso que realmente requiera generación de contenido, no solo una regla de negocio.

## 9. Trazabilidad

| Elemento | Referencia |
| :--- | :--- |
| **Aspecto relacionado** | [A-03](../aspectos.md#a-03--alertas-tempranas-de-requisitos-pendientes) (candidato más cercano evaluado y descartado) |
| **Escenario de calidad** | [Q-01](../arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica) (determinismo exigido) |
| **Documento de costos** | [docs/costos.md](../costos.md) |
