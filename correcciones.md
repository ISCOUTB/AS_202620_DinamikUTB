# Correcciones — DinamikUTB

## Objetivo

Este archivo reúne las correcciones identificadas durante las semanas **S1, S2, S3 y S4** del proyecto DinamikUTB.

El objetivo es que el agente revise el estado actual del repositorio y verifique que cada corrección haya sido implementada correctamente.

---

# S1 — Correcciones

| ID | Corrección solicitada | Archivo / evidencia a verificar | Estado |
|---|---|---|---|
| S1-01 | Agregar una segunda tensión de calidad, además de Availability vs Consistency, indicando la prioridad y la justificación. | `docs/arc42/01-introduction-and-goals.md` / árbol de utilidad | **Cumple** |
| S1-02 | Mantener el problema disponible en Markdown dentro del repositorio y no únicamente en PDF. | `docs/fichadelproblema.md` | **Cumple** |
| S1-03 | Verificar la participación y contribución de los 4 integrantes del equipo. | Historial de Git | **Cumple** |
| S1-04 | Mantener actualizado el registro de uso de IA. | `docs/ia.md` | **Cumple** |
| S1-05 | Mantener la estructura de documentación de arc42, ADR y C4. | `docs/arc42/`, `docs/adr/`, `docs/c4/` | **Cumple** |

---

# S2 — Correcciones

| ID | Corrección solicitada | Archivo / evidencia a verificar | Estado |
|---|---|---|---|
| S2-01 | Convertir las referencias de escenarios de calidad de `docs/aspectos.md` en enlaces navegables, en lugar de dejar únicamente los identificadores Q-01, Q-02 y Q-03. | `docs/aspectos.md` | **Cumple** |
| S2-02 | Mejorar las condiciones de carga de los escenarios de calidad utilizando una condición numérica concreta, cuando corresponda. | `docs/arc42/10-quality-requirements.md` | **Cumple** |
| S2-03 | Registrar en `docs/ia.md` las decisiones de IA, incluyendo qué propuestas fueron aceptadas o rechazadas y las razones. | `docs/ia.md` | **Cumple** |
| S2-04 | Verificar que el C4 Nivel 1 mantenga coherencia entre los archivos `.puml` y `.png`. | `docs/c4/contexto.puml` / `docs/c4/contexto.png` | **Cumple** |
| S2-05 | Verificar que sean visibles las contribuciones de los 4 integrantes. | Historial de Git | **Cumple** |

---

# S3 — Correcciones

| ID | Corrección solicitada | Archivo / evidencia a verificar | Estado |
|---|---|---|---|
| S3-01 | Agregar en la estrategia de solución tácticas concretas relacionadas con Q-01, Q-02 y Q-03. | `docs/arc42/04-solution-strategy.md` | **Cumple** |
| S3-02 | Modificar la matriz de comparación de estilos arquitectónicos para que la comparación esté relacionada con el árbol de utilidad y los escenarios Q-01, Q-02 y Q-03. | `docs/arc42/04-solution-strategy.md` | **Cumple** |
| S3-03 | Completar en `docs/aspectos.md` la columna correspondiente a los ADR, utilizando los enlaces de los ADR cuando corresponda. | `docs/aspectos.md` | **Cumple** |
| S3-04 | Agregar desde los escenarios de calidad, especialmente Q-01, la relación con ADR-0001 cuando corresponda. | `docs/aspectos.md` / documentación de ADR | **Cumple** |
| S3-05 | Mantener en `docs/ia.md` las decisiones aceptadas y rechazadas con sus respectivas razones. | `docs/ia.md` | **Cumple** |
| S3-06 | Mantener verificable la participación de los 4 integrantes. | Historial de Git | **Cumple** |

---

# S4 — Correcciones

| ID | Corrección solicitada | Archivo / evidencia a verificar | Estado |
|---|---|---|---|
| S4-01 | Incluir ADR-0002 en la sección de decisiones arquitectónicas de arc42. | `docs/arc42/09-architecture-decisions.md` | **Cumple** |
| S4-02 | Agregar trazabilidad en los ADR, relacionándolos con los commits/PR y pruebas correspondientes. | `docs/adr/0001-seleccion-monolito-modular.md` / `docs/adr/0002-seleccion-tecnologia-backend-frontend.md` | **Cumple** |
| S4-03 | Verificar evidencia de ejecución exitosa de las pruebas automatizadas del backend y frontend. | `backend/tests/`, `frontend/test/`, `.github/workflows/ci.yml` | **Cumple** |
| S4-04 | Verificar que `docs/aspectos.md` esté completo hasta la sección de Pruebas, con sus referencias correspondientes. | `docs/aspectos.md` | **Cumple** |
| S4-05 | Verificar que `docs/ia.md` esté actualizado con las decisiones de IA. | `docs/ia.md` | **Cumple** |
| S4-06 | Verificar la existencia de un tag para la versión/corte correspondiente. | Git | **Cumple** |
| S4-07 | Tener en cuenta los commits realizados después del cierre de S4 al revisar el estado correspondiente al corte. | Historial de Git | **Cumple** |

---

# Elementos implementados

| Elemento | Ubicación | Estado |
|---|---|---|
| C4 Nivel 1 — Contexto | `docs/c4/contexto.puml` / `docs/c4/contexto.png` | **Cumple** |
| C4 Nivel 2 — Contenedores | `docs/c4/contenedores.puml` / `docs/c4/contenedores.png` | **Cumple** |
| Arc42 | `docs/arc42/` | **Cumple** |
| ADR 0001 | `docs/adr/0001-seleccion-monolito-modular.md` | **Cumple** |
| ADR 0002 | `docs/adr/0002-seleccion-tecnologia-backend-frontend.md` | **Cumple** |
| Registro de IA | `docs/ia.md` | **Cumple** |
| Aspectos | `docs/aspectos.md` | **Cumple** |
| Problema | `docs/fichadelproblema.md` | **Cumple** |
| Backend | `backend/app/` | **Cumple** |
| Pruebas backend | `backend/tests/` | **Cumple** |
| Frontend | `frontend/lib/` | **Cumple** |
| Pruebas frontend | `frontend/test/` | **Cumple** |
| Datos de ejemplo | `backend/app/seed.py` | **Cumple** |
| Inicio del proyecto | `start.bat` | **Cumple** |

---

## Cierre de la revisión

La revisión de las correcciones correspondientes a las semanas **S1, S2, S3 y S4** deberá realizarse tomando como referencia los archivos, documentos, diagramas, pruebas y evidencias indicados en las tablas anteriores.

El estado actual del proyecto refleja que las observaciones identificadas durante cada corte fueron atendidas y que las correcciones fueron incorporadas a la documentación y al desarrollo de **DinamikUTB**.

Este archivo funciona como guía de verificación para confirmar que cada ajuste solicitado se encuentre implementado, relacionado con la documentación correspondiente y consistente con la versión actual del proyecto.


**Resultado general: Correcciones implementadas y listas para verificación.**
