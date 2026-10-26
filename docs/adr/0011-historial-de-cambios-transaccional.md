---
id: ADR-0011
title: Historial de cambios transaccional en la misma base de datos
status: Aceptado
date: 2026-10-25
deciders: Equipo de arquitectura DinamikUTB
---

# ADR-0011: Historial de cambios transaccional en la misma base de datos

![Status: Aceptado](https://img.shields.io/badge/Status-Accepted-brightgreen?style=flat-square)
![Date: 2026--10--25](https://img.shields.io/badge/Date-2026--10--25-blue?style=flat-square)
![Scope: Data](https://img.shields.io/badge/Scope-Data-orange?style=flat-square)

---

## 1. Contexto y descripción del problema

El aspecto [A-08](../aspectos.md#a-08--historial-de-cambios-sobre-la-información-académica) y el escenario [Q-08](../arc42/10-quality-requirements.md#escenario-q-08--historial-de-cambios-sobre-la-información-académica) exigen que el **100 % de las modificaciones** académicas queden registradas (quién, cuándo, valor anterior y nuevo) y sean consultables. Desde el [ADR-0003](0003-seleccion-motor-de-base-de-datos.md) el mecanismo quedó marcado como pendiente de un ADR propio, y [arc42 §11.6](../arc42/11-risks-and-technical-debt.md) dejó para este ADR la interacción entre historial e idempotencia.

Estado antes de este ADR: `actualizar_estado_requisito` escribía una línea de log JSON (`auditoria_cambio_estado`) **después** del `commit`. Ese registro:

* sale por `stdout` hacia los logs del proveedor, que la aplicación no puede consultar y cuya retención no depende del equipo;
* se emite fuera de la transacción: si el proceso muere entre el `commit` y el log, el cambio existe sin registro (como máximo una vez);
* no puede mostrarse a un usuario autorizado, como pide Q-08.

Esta semana (S12) se pide además identificar y argumentar la decisión de datos más costosa de revertir. Este ADR argumenta que es esta.

---

## 2. Por qué es la decisión de datos más costosa de revertir

Se compararon las decisiones de datos que el sistema ya tomó o debe tomar, con cuatro criterios: si se puede reconstruir después con la información existente, cuántos puntos del sistema acopla, si su forma se vuelve contrato, y la evidencia de costo observada en este repositorio.

| Decisión de datos | ¿Se reconstruye después? | Puntos acoplados | ¿Es contrato? | Costo de reversión |
|---|---|---|---|---|
| Motor relacional (SQLite → Postgres, [ADR-0003](0003-seleccion-motor-de-base-de-datos.md), [ADR-0007](0007-persistencia-render-postgres.md)) | Sí, mecánicamente | `database.py`, `render.yaml`, dependencia `psycopg` | No | **Bajo y ya medido:** el cambio SQLite → Postgres se hizo sin tocar los módulos (SQLAlchemy lo aísla). |
| Estado actual mutable en una fila, sin columna de versión | Sí (se agrega columna) | `Requisito`, `service.py` | No | Bajo. |
| `codigo_estudiantil` como identificador natural entre módulos, sin claves foráneas | Sí: se agrega una clave sustituta y se rellena con un join | 3 tablas, rutas `/requisitos/{id}` y `/estudiantes/{codigo}`, `openapi.json`, validadores del frontend | Sí (API) | Medio: rompe el contrato versionado, pero el dato se migra sin pérdida. |
| `Requisito` como una fila por estudiante con nombre en texto libre (sin catálogo por programa, A-06) | Parcial: las variantes de nombre se unifican a mano (~8 requisitos por programa) | `Requisito`, `programas/` futuro, Q-06 | Sí (API) | Alto, pero finito: una persona puede curar el mapeo. |
| **Mecanismo del historial de cambios (esta decisión)** | **No: el valor anterior, el actor y la fecha de un cambio pasado solo existen si se capturaron en ese instante** | Toda ruta de escritura de cada módulo que modifique datos académicos | Sí (auditoría) | **Muy alto**, ver abajo. |

**Argumento.** Las demás decisiones se equivocan "hacia adelante": se pueden corregir migrando datos que existen. El historial se equivoca "hacia atrás": cada cambio hecho antes de tener el mecanismo correcto es información perdida, y nadie puede reconstruirla. Además:

1. **Sus filas son evidencia inmutable.** Cambiar la estructura o el almacén una vez existen filas reales significa reescribir evidencia de auditoría, no migrar datos operativos.
2. **Su forma se vuelve contrato** para quien consulte el historial (RF-08) y para cualquier investigación de inconsistencias (A-07).
3. **Se acopla a todas las escrituras.** Cada módulo que modifique información académica (`requisitos/` hoy; `estudiantes/` y `programas/` mañana) debe escribir su historial con la misma garantía.
4. **El momento más barato para decidir es ahora:** el ambiente desplegado solo tiene datos de ejemplo (README, "Entorno desplegado"), así que la brecha de información perdida es cero. Con la primera carga de datos reales deja de serlo.

Este ranking es cualitativo (no se midió): se apoya en la evidencia de costo del motor (ADR-0007) y en el inventario de acoplamientos del repositorio.

---

## 3. Factores de decisión

| Factor | Descripción |
| :--- | :--- |
| **Completitud (Q-08)** | 100 % de las modificaciones registradas, sin excepción. |
| **Atomicidad dato-historial** | No debe existir un cambio sin su registro ni un registro sin su cambio. |
| **Costo cero** | Sin infraestructura nueva ([02-architecture-constraints.md](../arc42/02-architecture-constraints.md), [docs/costos.md](../costos.md)). |
| **Propiedad de datos** | Cada entidad tiene un solo módulo dueño ([08-cross-cutting-concepts.md](../arc42/08-cross-cutting-concepts.md), 8.4). |
| **Idempotencia** | Repetir un `PUT` con el mismo valor no debe ensuciar el historial ([11-risks-and-technical-debt.md](../arc42/11-risks-and-technical-debt.md), 11.6). |
| **Consistencia inmediata** | Coherente con [ADR-0004](0004-comunicacion-sincrona-frontend-backend.md): el cliente sabe de inmediato si el cambio y su registro se aplicaron. |

---

## 4. Alternativas consideradas

### 4.1 Mantener el log JSON como registro (estado anterior)

* **Ventajas:** ya existe, sin cambios.
* **Desventajas:** no es consultable por la aplicación, se emite tras el `commit` (puede perderse), y su retención depende del proveedor (no verificada). No cumple Q-08.
* **Descartada como mecanismo de auditoría.** Se conserva como telemetría operativa.

### 4.2 Triggers en la base de datos

* **Ventajas:** atómicos con el cambio, sin tocar el código de la aplicación.
* **Desventajas:** distinta sintaxis entre SQLite (local/CI) y Postgres (desplegado), lo que agrava la divergencia ya documentada en 11.2; la base no conoce al usuario de la aplicación (`actor_id`); la lógica queda fuera del código y de las pruebas de Pytest.
* **Descartada.**

### 4.3 Tabla de historial append-only, misma base y misma transacción

* **Ventajas:** atomicidad real (un solo `commit`), consultable, sin infraestructura nueva, probable con Pytest, el actor viene de la aplicación, extensible por módulo dueño.
* **Desventajas:** una escritura extra por cambio; la inmutabilidad se sostiene por convención de la aplicación, no por permisos de la base.
* **Seleccionada.**

### 4.4 Event sourcing (los eventos como fuente de verdad)

* **Ventajas:** historial completo por construcción.
* **Desventajas:** reescribe el modelo de `requisitos/`, exige proyecciones y excede el alcance del semestre.
* **Descartada.**

### 4.5 Historial asíncrono mediante cola o broker

* **Ventajas:** desacopla la escritura del registro.
* **Desventajas:** consistencia eventual: habría una ventana donde el cambio existe sin su historial, incompatible con Q-08 (100 %) y con [ADR-0004](0004-comunicacion-sincrona-frontend-backend.md); además, un broker no cabe en el límite de costo.
* **Descartada.**

### 4.6 Biblioteca de versionado de modelos para SQLAlchemy

* **Ventajas:** menos código propio.
* **Desventajas:** dependencia nueva que debe verificarse según [ADR-0008](0008-verificacion-de-artefactos-sugeridos-por-ia.md), con comportamiento opaco, para una necesidad de una sola tabla.
* **Descartada.**

---

## 5. Decisión

Se adopta la alternativa **4.3**. Cada módulo dueño de datos que modifique información académica registra sus cambios en **su propia tabla de historial, en la misma base y en la misma transacción que la modificación**.

Reglas:

1. `requisitos/` es dueño de `requisitos_historial` (`id`, `requisito_id`, `estudiante_id`, `campo`, `valor_anterior`, `valor_nuevo`, `actor_id`, `creado_en`). Un solo `commit` confirma el cambio y su fila.
2. **No se registra nada si el valor no cambia** (resuelve lo dejado pendiente en 11.6: un `PUT` repetido no genera filas).
3. Las filas **nunca se actualizan ni se borran** desde la aplicación.
4. `actor_id` y `estudiante_id` son valores, no claves foráneas hacia otros módulos (propiedad de datos); `requisito_id` sí es clave foránea porque es el mismo módulo.
5. El log JSON `auditoria_cambio_estado` se mantiene como telemetría, no como registro de auditoría.
6. `estudiantes/` y `programas/` aplicarán el mismo patrón cuando tengan escrituras.
7. **Alcance actual y extensión.** Hoy el único dato académico modificable es el estado de un requisito, por lo que es lo único que se registra. Cuando el sistema incorpore otros datos (créditos acumulados, cursos aprobados, resultados de exámenes), cada uno se registrará con el mismo patrón en el módulo dueño, usando la columna `campo` para identificar qué cambió. Esos datos no existen hoy como entidades; no se registran cambios sobre datos que el sistema no almacena.

---

## 6. Consecuencias

### Consecuencias positivas

* **Atomicidad dato-historial:** si el registro falla, el cambio no se aplica (`test_si_falla_el_historial_el_cambio_no_queda_aplicado`).
* **Idempotencia sin deduplicación artificial:** el `PUT` repetido no crea filas.
* **Sin infraestructura nueva:** cabe en $0 y no agrega un contenedor al C4 (la tabla vive en la base existente).
* **Salida posible:** al ser filas estructuradas, se pueden exportar a otro almacén más adelante, cosa imposible con logs.

### Consecuencias negativas

* **La durabilidad del historial es la de la base.** En Render, la base gratuita expira a los 30 días y recrearla borra el historial (F7). En el laboratorio persiste en el volumen `pgdata`, pero no hay respaldo declarado ([ADR-0012](0012-despliegue-en-servidor-del-laboratorio.md)). Hoy solo hay datos de ejemplo.
* **Inmutabilidad por convención:** quien tenga acceso SQL a la base puede alterar la tabla. Riesgo aceptado para el alcance académico.
* **Consulta incompleta:** existe `service.obtener_historial`, pero **no hay endpoint** todavía; RF-08 y Q-08 quedan cubiertos solo en el registro, no en la consulta por un usuario autorizado.
* **Cobertura parcial:** solo `requisitos/` registra historial; `estudiantes/` es de solo lectura hoy.
* **Una escritura adicional por cambio:** impacto despreciable al volumen de [docs/costos.md](../costos.md).

### Costo de revertir esta decisión

* **Pasar a otro almacén (auditoría externa, event sourcing):** viable mientras la tabla exista: se exportan las filas y se mantiene la tabla como respaldo. Es la razón para preferir una tabla estructurada a logs.
* **Eliminar el historial o cambiar su estructura con filas reales:** equivale a reescribir evidencia; exigiría un ADR nuevo y una migración con trazabilidad de lo transformado.

---

## 7. Relación con atributos de calidad

| Atributo | Relación con la decisión |
| :--- | :--- |
| **Trazabilidad** | Principal: quién, cuándo, valor anterior y nuevo, de forma persistente. |
| **Exactitud / Consistencia** | Cambio e historial son atómicos; el repetido no ensucia el registro. |
| **Seguridad** | `actor_id` queda registrado; la consulta futura se limitará a gestión. |
| **Disponibilidad** | Sin dependencia nueva; hereda los riesgos de la base (F7). |
| **Mantenibilidad** | Patrón único por módulo dueño, sin librerías ni triggers. |

---

## 8. Estado de la decisión

**Aceptado.** No reemplaza ningún ADR anterior: completa a [ADR-0003](0003-seleccion-motor-de-base-de-datos.md) (motor transaccional) y a [ADR-0004](0004-comunicacion-sincrona-frontend-backend.md) (consistencia inmediata). Se revisa si: se agrega un endpoint de consulta con permisos por programa, se migra a una base persistente, `estudiantes/` o `programas/` empiezan a escribir, o se exige inmutabilidad garantizada por la base.

---

## 9. Trazabilidad

| Elemento | Referencia |
| :--- | :--- |
| **Aspecto principal** | [A-08](../aspectos.md#a-08--historial-de-cambios-sobre-la-información-académica) |
| **Escenarios de calidad** | [Q-08](../arc42/10-quality-requirements.md#escenario-q-08--historial-de-cambios-sobre-la-información-académica) (principal), [Q-01](../arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica) |
| **Elemento C4** | Contenedores de base de datos en `docs/c4/contenedores.puml` (la tabla vive en ellos) |
| **Código** | `backend/app/requisitos/models.py` (`RequisitoHistorial`), `backend/app/requisitos/service.py` |
| **Pruebas** | `backend/tests/test_historial.py` |
| **Commits que lo implementan** | `<completar con el hash tras el commit>` |
| **Estrategia de datos** | [arc42 §8.8–8.10](../arc42/08-cross-cutting-concepts.md), [docs/evidencia-s12.md](../evidencia-s12.md) |
