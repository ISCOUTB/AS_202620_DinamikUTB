---
id: ADR-0003
title: Selección del motor de base de datos
status: Aceptado
date: 2026-09-06
deciders: Equipo de arquitectura DinamikUTB
---

# ADR-0003: Selección del motor de base de datos

![Status: Aceptado](https://img.shields.io/badge/Status-Accepted-brightgreen?style=flat-square)
![Date: 2026--09--06](https://img.shields.io/badge/Date-2026--09--06-blue?style=flat-square)
![Scope: Persistence](https://img.shields.io/badge/Scope-Persistence-orange?style=flat-square)

---

## 1. Contexto y descripción del problema

`docs/arc42/02-architecture-constraints.md` (sección 2.1) establece que **DinamikUTB** utilizará una base de datos propia, pero deja abierta la elección entre un motor SQL o NoSQL, indicando únicamente que un motor relacional es la opción que mejor se alinea con el escenario **Q-01** (exactitud), por las transacciones consistentes que exige sobre actualizaciones de varios campos (ver `04-solution-strategy.md`, sección 4.8.1). De forma similar, `03-context-and-scope.md` (sección 3.4) señala que la tecnología específica de la base de datos aún no había sido definida y que sería seleccionada como parte de las decisiones de arquitectura registradas en `09-architecture-decisions.md`.

Sin embargo, el equipo ya había avanzado con la implementación del corte vertical de la semana 4 (ver `06-runtime-view.md` y `README.md`) utilizando **SQLite** a través de **SQLAlchemy** en `backend/app/core/database.py`. Esa elección ya aparecía reflejada en `05-building-block-view.md` (sección 5.1) y en el diagrama de contenedores C4 (`docs/c4/contenedores.puml`, elemento `ContainerDb`), pero nunca se había formalizado como decisión arquitectónica. Este ADR cierra esa brecha entre lo documentado como "pendiente" y lo que ya estaba implementado, y evalúa la elección frente a las alternativas permitidas por el alcance del proyecto.

---

## 2. Factores de decisión

| Factor | Descripción |
| :--- | :--- |
| **Consistencia transaccional** | El motor debe soportar transacciones ACID para sostener la táctica de Q-01 de agrupar actualizaciones múltiples en una sola operación. |
| **Simplicidad operativa** | El proyecto se desarrolla durante un semestre académico (`02-architecture-constraints.md`, sección 2.2); el motor no debe exigir infraestructura adicional para que el equipo y los evaluadores del curso puedan ejecutar el sistema fácilmente (`start.bat`). |
| **Compatibilidad con SQLAlchemy** | El acceso a datos ya se abstrae mediante SQLAlchemy (`backend/app/core/database.py`), por lo que el motor elegido debe integrarse sin fricción con esa capa. |
| **Camino de evolución** | Debe ser posible migrar a un motor con mayor concurrencia si el proyecto continúa más allá del semestre, sin reescribir la lógica de los módulos (`03-context-and-scope.md`, sección 3.6). |
| **Soporte para múltiples programas académicos** | El modelo de datos debe poder representar de forma relacional los programas y requisitos sin duplicar lógica (relacionado con A-06). |

---

## 3. Alternativas consideradas

### 3.1 SQLite

* **Ventajas:** No requiere un servidor de base de datos separado; el archivo `.db` se genera automáticamente al levantar el backend (ver `README.md`, sección "Datos de ejemplo"); soporta transacciones ACID, suficiente para la táctica de Q-01; se integra de forma nativa con SQLAlchemy sin configuración adicional; es la opción de menor fricción para ejecutar el proyecto en el entorno de evaluación del curso.
* **Desventajas:** Un solo escritor a la vez, lo que puede afectar a Q-05 (disponibilidad) si varios coordinadores o administradores escriben simultáneamente; no está pensado para un entorno de producción con múltiples instancias del backend.

### 3.2 PostgreSQL

* **Ventajas:** Motor relacional robusto, con mejor soporte de concurrencia y funciones avanzadas (constraints, tipos de datos, índices parciales); trayectoria clara hacia un eventual entorno productivo real de la UTB.
* **Desventajas:** Exige levantar y mantener un servidor de base de datos independiente, lo que añade una pieza de infraestructura no justificada por el alcance actual (`02-architecture-constraints.md`, sección 2.2); introduce una curva de configuración adicional dentro del tiempo limitado del semestre.

### 3.3 MySQL / MariaDB

* **Ventajas:** Similar a PostgreSQL en cuanto a robustez relacional y soporte de concurrencia.
* **Desventajas:** Comparte las mismas desventajas de infraestructura que PostgreSQL para el alcance actual, sin una ventaja diferencial clara sobre esa alternativa para este proyecto.

### 3.4 Motor NoSQL (por ejemplo, MongoDB)

* **Ventajas:** Esquema flexible, útil si los requisitos por programa variaran de forma muy heterogénea.
* **Desventajas:** No ofrece transacciones multi-documento nativas equivalentes a las de un motor relacional, lo que dificulta directamente la táctica de Q-01 (actualización de varios campos dentro de una sola transacción); obligaría a desnormalizar información que hoy se modela de forma relacional entre `estudiantes/`, `requisitos/` y `programas/`; contradice la recomendación explícita de `02-architecture-constraints.md` de usar un motor relacional.

> [!Note]
> **¿Por qué destaca SQLite para nuestro proyecto?** Es el único motor de la lista que satisface el requisito relacional de Q-01 sin introducir infraestructura adicional incompatible con el alcance de un proyecto de semestre.

---

## 4. Decisión

Se selecciona **SQLite**, accedido mediante **SQLAlchemy**, como motor de base de datos para la primera versión de DinamikUTB.

> **Justificación principal:** SQLite es un motor relacional, por lo que sostiene directamente la táctica de Q-01 (transacciones sobre actualizaciones múltiples, ver `04-solution-strategy.md`, sección 4.8.1), sin exigir infraestructura adicional incompatible con el alcance de un proyecto de semestre. Al acceder a través de SQLAlchemy, una futura migración a un motor con mayor concurrencia (como PostgreSQL) no debería requerir cambios en la lógica de los módulos `requisitos/`, `estudiantes/` o `programas/`, solo en la cadena de conexión y, eventualmente, en detalles específicos del dialecto SQL.

Esta decisión no reemplaza al [ADR-0001](0001-seleccion-monolito-modular.md) ni al [ADR-0002](0002-seleccion-tecnologia-backend-frontend.md): el monolito modular sigue siendo el estilo arquitectónico y FastAPI/Flutter la tecnología de backend/frontend; este ADR únicamente formaliza el motor de persistencia que ya se venía utilizando en `backend/app/core/database.py`.

---

## 5. Consecuencias

### Consecuencias positivas

* **Cero infraestructura adicional:** el equipo y los evaluadores del curso pueden ejecutar el sistema completo con `start.bat`, sin instalar ni configurar un servidor de base de datos separado.
* **Soporte directo a Q-01:** al ser un motor relacional con transacciones ACID, sostiene la táctica ya documentada de agrupar actualizaciones múltiples en una sola operación.
* **Coherencia entre documentación y código:** cierra la brecha entre lo que `02-architecture-constraints.md` y `03-context-and-scope.md` describían como "pendiente" y lo que ya estaba implementado y reflejado en el C4 de contenedores.
* **Camino de migración razonable:** el uso de SQLAlchemy como capa de acceso a datos reduce el costo de una futura migración de motor.

### Consecuencias negativas

* **Concurrencia limitada:** SQLite permite un solo escritor a la vez; si el número de coordinadores o administradores escribiendo simultáneamente crece, esto podría afectar la medida de Q-05 (disponibilidad) y debería revisarse en una futura decisión.
* **No apto para producción institucional:** si el proyecto evoluciona hacia un despliegue real en la UTB, este ADR debería revisarse y probablemente reemplazarse por PostgreSQL u otro motor con mayor concurrencia.
* **Historial de cambios (A-08) solo parcialmente resuelto:** este ADR fija el motor transaccional sobre el que se apoyará el historial de modificaciones, pero no el diseño concreto del mecanismo (estructura de tablas de historial), que sigue requiriendo una decisión adicional.

---

## 6. Relación con atributos de calidad

| Atributo | Relación con la decisión |
| :--- | :--- |
| **Exactitud / Consistencia** | SQLite ofrece transacciones ACID, condición necesaria para la táctica de Q-01 de no dejar un requisito a medio actualizar. |
| **Seguridad** | No incide de forma directa; el control de acceso se resuelve en `usuarios/` (ver ADR-0001), independientemente del motor de base de datos. |
| **Usabilidad** | No incide de forma directa; se resuelve en el frontend Flutter (ver ADR-0002). |
| **Rendimiento** | Para el volumen de datos y usuarios concurrentes esperado durante el proyecto, SQLite responde con la latencia suficiente para el objetivo de 1 minuto definido en `01-introduction-and-goals.md`. |
| **Disponibilidad** | El límite de un solo escritor concurrente es el principal riesgo que este motor introduce sobre Q-05; se documenta como consecuencia negativa a revisar. |
| **Trazabilidad** | El motor relacional permite modelar tablas de historial con claves foráneas hacia el registro modificado, base necesaria para A-08, aunque el diseño específico de esas tablas queda pendiente. |
| **Mantenibilidad** | El acceso a través de SQLAlchemy aísla al resto de los módulos del motor específico, facilitando un cambio futuro sin modificar la lógica de negocio. |

---

## 7. Relación con las restricciones del proyecto

Esta decisión resuelve directamente la restricción técnica pendiente en `docs/arc42/02-architecture-constraints.md` (sección 2.1): la elección entre una base de datos SQL o NoSQL. Con este ADR, el motor queda definido como **SQLite (SQL, relacional)**, consistente con la recomendación ya hecha en esa misma sección a favor de un motor relacional por Q-01.

También responde a `03-context-and-scope.md` (sección 3.4), que remitía explícitamente esta decisión a `09-architecture-decisions.md`.

---

## 8. Estado de la decisión

**Aceptado.**

Esta decisión formaliza un motor que el equipo ya venía utilizando en el desarrollo (`backend/app/core/database.py`, `docs/c4/contenedores.puml`). Cualquier cambio posterior de motor de base de datos deberá registrarse mediante un nuevo ADR, y debería revisar en particular el impacto sobre Q-05 (disponibilidad) señalado en la sección 5.

---

## 9. Trazabilidad

| Elemento | Referencia |
| :--- | :--- |
| **Aspectos que sustenta** | [A-01](../aspectos.md#a-01--seguimiento-del-cumplimiento-de-requisitos) — necesita persistencia relacional confiable; [A-02](../aspectos.md#a-02--cálculo-correcto-del-estado-de-graduación) — el cálculo depende de transacciones consistentes sobre el motor; [A-06](../aspectos.md#a-06--extensibilidad-para-múltiples-programas-académicos) — un motor relacional permite modelar nuevos programas y requisitos sin cambiar la lógica de `requisitos/`; [A-08](../aspectos.md#a-08--historial-de-cambios-sobre-la-información-académica) — **relación parcial**: este ADR provee el motor transaccional sobre el que se apoyará el historial, pero el mecanismo concreto de almacenamiento permanece pendiente de un ADR adicional. |
| **Escenarios de calidad** | [Q-01](../arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica) (principal); [Q-05](../arc42/10-quality-requirements.md#escenario-q-05--disponibilidad-del-sistema) (riesgo documentado en la sección 5); [Q-06](../arc42/10-quality-requirements.md#escenario-q-06--extensibilidad-para-múltiples-programas-académicos) (soporte del modelo relacional) |
| **Elemento C4** | `ContainerDb` "Base de datos" (SQLite) en `docs/c4/contenedores.puml`, ya reflejado en el diagrama antes de esta formalización |
| **Commits que lo implementan** | Implementación ya presente desde los commits iniciales de `backend/app/core/database.py` (previos a esta formalización); este ADR documenta una decisión ya efectiva en el código, no un cambio de código nuevo |
| **Pruebas que lo cubren** | `backend/tests/test_requisitos.py`, que ejercita la persistencia real contra SQLite en los dos casos existentes (consulta con datos, consulta sin datos) |