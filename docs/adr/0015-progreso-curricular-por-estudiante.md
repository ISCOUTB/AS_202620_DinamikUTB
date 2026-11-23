---
id: ADR-0015
title: Progreso curricular por estudiante y guía de requisitos en el catálogo
status: Aceptado
date: 2026-11-20
deciders: Equipo de arquitectura DinamikUTB
---

# ADR-0015: Progreso curricular por estudiante y guía de requisitos en el catálogo

> Aceptado el 2026-11-22 con la suite del backend en verde (153 pruebas). Un ADR aceptado no se edita.

## 1. Contexto y descripción del problema

El estudiante veía una lista plana de requisitos. La ficha del problema promete más: saber qué materias de su malla ya aprobó (con fecha), cuáles le faltan y cómo cumplir cada requisito de grado. Faltaban tres cosas:

1. Dónde guardar el estado de cada curso **por estudiante** (A-02).
2. Dónde guardar la guía de cumplimiento de cada requisito (A-06).
3. Cómo agregar columnas a tablas existentes: `create_all` no altera tablas, y la base del laboratorio ya tiene datos ([ADR-0012](0012-despliegue-en-servidor-del-laboratorio.md)).

## 2. Factores de decisión

| Factor | Descripción |
| :--- | :--- |
| **Propiedad de datos** | Cada entidad con un solo módulo dueño ([arc42 §8.4](../arc42/08-cross-cutting-concepts.md)). |
| **Historial atómico** | Toda escritura académica deja su fila de historial en la misma transacción ([ADR-0011](0011-historial-de-cambios-transaccional.md)). |
| **Una sola fuente** | La guía de un requisito no debe copiarse a cada estudiante: se desalinearía. |
| **Sin infraestructura nueva** | Costo cero, sin Alembic ni servicios adicionales ([docs/costos.md](../costos.md)). |
| **Contratos existentes** | `RequisitoOut`, `GET /requisitos/{id}` y el frontend actual no deben romperse. |

## 3. Alternativas consideradas

### 3.1 Estado del curso como columna JSON dentro de `Estudiante`
* **Desventajas:** no se consulta por curso, el historial por campo es incómodo y `estudiantes/` pasaría a ser dueño de datos del plan.
* **Descartada.**

### 3.2 Tabla `cursos_estudiante` en `curriculo/`, con `cursos_estudiante_historial`
* **Ventajas:** `curriculo/` ya es dueño de `Curso` y prerrequisitos; unicidad (`estudiante_id`, `curso_id`); mismo patrón que `requisitos_historial`.
* **Desventajas:** `estudiante_id` es un valor, no una FK (convención ya aceptada para `Requisito`).
* **Seleccionada.**

### 3.3 Guía copiada a cada `Requisito` del estudiante
* **Descartada:** N copias del mismo texto; corregir una guía exigiría actualizar a todos los estudiantes.

### 3.4 Guía en `RequisitoPrograma`; el `Requisito` solo guarda lo propio del estudiante (fecha, periodo, evidencia)
* **Seleccionada.** La ruta del estudiante une ambas tablas por `catalogo_id`.

### 3.5 Introducir Alembic
* **Descartada por ahora:** exige disciplina de migraciones y CI que no se justifican para este alcance. Se reemplaza por una función acotada (`core/migraciones.py`) que solo agrega columnas nullable. Revisar si hace falta cambiar tipos, borrar columnas o agregar NOT NULL.

## 4. Decisión

1. `CursoEstudiante` y `CursoEstudianteHistorial` viven en `backend/app/curriculo/`. Un curso sin fila equivale a «pendiente».
2. Reglas de escritura (`curriculo/progreso.py`): `aprobado` exige fecha (no futura) y periodo, y nota ≥ 3.0 si viene; `en_curso` exige periodo; ambos exigen prerrequisitos aprobados (409 si faltan); `pendiente` limpia fecha, periodo y nota. Repetir el mismo `PUT` no escribe nada. Cada campo que cambia genera una fila de historial.
3. Solo `GestorUser` escribe. El estudiante no modifica su avance ([02 §2.2](../arc42/02-architecture-constraints.md)); un simulador «¿y si apruebo esto?» sería estado local del cliente, sin persistir.
4. `RequisitoPrograma` gana `codigo_interno`, `categoria`, `porcentaje_creditos_requerido`, `portal_oficial`, `tiempo_estimado`, `guia_resumen`, `pasos_guia`. `Requisito` gana `fecha_cumplimiento`, `periodo`, `evidencia`. Todas nullable.
5. La elegibilidad (créditos que faltan para el 75 % o el 80 %) se calcula con enteros: `ceil(total × pct / 100)`.
6. `requisitos/` consulta créditos a través de `curriculo.progreso.creditos_del_estudiante`, nunca a sus tablas.
7. `core/migraciones.asegurar_columnas` corre en `seed` y en el arranque de `main.py`.

## 5. Consecuencias

### Positivas
* Una consulta devuelve toda la malla del estudiante con estado, desbloqueo, fechas y promedio ponderado.
* Q-01 se sostiene: el cálculo vive en el backend y es determinista (sin LLM, [ADR-0009](0009-no-incorporacion-componente-generativo.md)).
* El historial cubre también el avance por curso (A-08).

### Negativas
* `requisitos/` depende ahora de un servicio de `curriculo/` (dirección única; `curriculo/` no importa `requisitos/`).
* Las migraciones siguen siendo parciales: lo que no sea «agregar columna nullable» necesita trabajo manual.
* Cualquier coordinador puede escribir el avance de cualquier estudiante (no se acota por programa). Registrado en [deuda-tecnica.md](../deuda-tecnica.md).
* `GET /malla/progreso` carga el plan completo y calcula en memoria: bien para ~55 cursos; habría que medir si un plan crece mucho.
* El plan de Ingeniería de Sistemas tiene catálogo real cargado; otros programas aún no tienen malla (A-06 sigue parcial).

## 6. Relación con atributos de calidad

| Atributo | Relación |
| :--- | :--- |
| **Exactitud / Consistencia** | Validación estricta y cálculo único en servicio. |
| **Trazabilidad** | Historial por campo en la misma transacción. |
| **Seguridad** | `verificar_acceso_estudiante` en lectura; solo gestión escribe. |
| **Mantenibilidad** | Sin dependencia nueva; patrón repetido de ADR-0011. |

## 7. Estado de la decisión

**Aceptado.** No reemplaza ningún ADR: complementa [ADR-0011](0011-historial-de-cambios-transaccional.md) y [ADR-0014](0014-extension-historial-datos-estudiante.md).

## 8. Trazabilidad

| Elemento | Referencia |
| :--- | :--- |
| **Aspectos** | [A-02](../aspectos.md#a-02--cálculo-correcto-del-estado-de-graduación), [A-06](../aspectos.md#a-06--extensibilidad-para-múltiples-programas-académicos), [A-08](../aspectos.md#a-08--historial-de-cambios-sobre-la-información-académica) |
| **Escenarios** | [Q-01](../arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica), [Q-08](../arc42/10-quality-requirements.md#escenario-q-08--historial-de-cambios-sobre-la-información-académica) |
| **C4** | Backend API y bases de datos en `docs/c4/contenedores.puml` (tablas nuevas en la lista) |
| **Código** | `backend/app/curriculo/models.py`, `progreso.py`, `router.py`; `backend/app/requisitos/service.py`; `backend/app/core/migraciones.py` |
| **Pruebas** | `backend/tests/test_progreso.py`, `backend/tests/test_migraciones.py` |
| **Commits** | `f06b09f` |
