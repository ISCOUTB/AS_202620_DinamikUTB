# Correcciones — DinamikUTB

Este archivo responde de forma trazable a los hallazgos publicados en las evidencias S1 a S4 y en la revisión preliminar de S5 (`semana-05-corte1`). Cada fila cita la evidencia verificable en el repositorio; no es evidencia por sí solo, es un índice hacia ella.

Conforme a la regla del kit, este documento no busca cambiar la calificación de esas semanas, reporta el estado **actual** del proyecto frente a cada hallazgo, para el compendio de S5.

---

## Nota sobre la restricción nueva de este corte

La ficha `semana-05-corte1.md` condiciona la evaluación del reto a que "el aula aporte explícitamente ese enunciado y su asignación". Para este equipo, el docente confirmó directamente que no se asignó ninguna restricción nueva para este corte y que las filas correspondientes de la matriz (diagnóstico, línea base, ADR del reto, aplicación sobre el corte vertical, prueba del cambio, resultado contra umbral) no aplican en ausencia de esa asignación.

| Fila de la matriz de corte1 | Motivo técnico | Evidencia | Estado |
|---|---|---|---|
| 3–9 (restricción nueva, línea base, ADR del reto, cambio implementado, límites C4 del cambio, prueba del cambio, resultado vs. umbral) | Sin restricción asignada por el aula para este equipo; confirmado directamente por el docente. Por regla propia de la ficha, estas filas no se evalúan sin asignación explícita. | Confirmación del docente | Rechazada con justificación |

---

## Nota sobre la etiqueta `corte-1`

El docente indicó explícitamente que no se crearan etiquetas de git para este corte. El estado calificado se identifica por el hash del último commit anterior al cierre acordado, en lugar de una etiqueta `corte-1`.

| Fila de la matriz | Motivo técnico | Evidencia | Estado |
|---|---|---|---|
| 1 (etiqueta `corte-1` sobre un commit anterior al cierre) | Instrucción explícita del docente de no usar tags para este corte. Se usa como estado calificado el último commit de la rama `master` anterior al cierre. | Confirmación del docente; `git log -1 --until="<cierre>"` sobre `master` | Ajustada por instrucción del docente |

---

## S1 — Hallazgos y su estado actual

| Hallazgo (semana-01-evidencia-s1) | Acción realizada | Evidencia | Estado |
|---|---|---|---|
| Ficha del problema entregada en PDF, no en Markdown | Se mantiene `docs/fichadelproblema.md` como archivo Markdown real, con contenido completo (contexto, problema, usuarios afectados, alcance, aspecto de calidad priorizado) | `docs/fichadelproblema.md` | Corregida |
| Solo una tensión de calidad declarada (se pedían dos) | Se declararon dos tensiones enfrentadas entre sí en `README.md`: "Disponibilidad vs. Consistencia" y "Usabilidad vs. Funcionalidad", cada una con prioridad y justificación | `README.md`, sección "Atributos de calidad" | Corregida |
| Esteban Ramírez Ríos sin commits verificables en el periodo S1 | No aplica corrección retroactiva sobre S1 (regla: las semanas anteriores no se recalifican); el patrón de participación se retomó y se sostiene en S3 y S4 | `git shortlog -sne` sobre commits de S3/S4; ver hallazgo de S2 sobre concentración de commits | No aplica (histórico) |

---

## S2 — Hallazgos y su estado actual

| Hallazgo (semana-02-evidencia-s2) | Acción realizada | Evidencia | Estado |
|---|---|---|---|
| `docs/aspectos.md` con escenarios referenciados por ID de texto, no por hipervínculo | Se reemplazaron los identificadores de texto por enlaces reales de Markdown hacia los encabezados de `10-quality-requirements.md` | `docs/aspectos.md`, columna "Escenario de calidad" | Corregida |
| Escenarios de calidad sin herramienta ni carga definidas | Se agregaron las filas "Herramienta" y "Carga" a Q-01, Q-02 y Q-03, con valores concretos (Pytest/20 casos, FastAPI TestClient/20 intentos, prueba de usabilidad/5 usuarios) | `docs/arc42/10-quality-requirements.md`, sección 10.3 | Corregida |
| `docs/ia.md` sin registrar qué se rechazó y por qué | Se agregaron entradas con validación "Rechazado" y "Rechazado parcialmente", incluyendo el motivo técnico del rechazo | `docs/ia.md`, entradas del 23/08/2026 en adelante | Corregida |
| Entrega tardía de `ia.md` (9 minutos después del cierre de S2) | No aplica corrección retroactiva sobre el estado calificado de S2 | — | No aplica (histórico) |
| Trabajo del periodo S2 concentrado en una sola persona (JuanchisV, 35 de 36 commits) | Ver seguimiento consolidado en la sección "Concentración de commits" al final de este documento | `git shortlog -sne` por periodo | Parcial (ver nota consolidada) |

---

## S3 — Hallazgos y su estado actual

| Hallazgo (semana-03-evidencia-s3) | Acción realizada | Evidencia | Estado |
|---|---|---|---|
| Sección 4 de arc42 sin tácticas concretas ligadas a los escenarios (relación declarativa) | Se agregó la subsección 4.8.1 con tácticas por escenario (Q-01, Q-02, Q-03), su ubicación en el código y cómo se verifican | `docs/arc42/04-solution-strategy.md`, sección 4.8.1 | Corregida |
| Matriz comparativa de estilos con criterios genéricos, sin relación con el árbol de utilidad | Se reescribió la sección 4.4 comparando los tres estilos directamente contra los escenarios Q-01, Q-02, Q-03, con la escala de tres valores de la sección 4.3 | `docs/arc42/04-solution-strategy.md`, secciones 4.2–4.4 | Corregida |
| Columna ADR de `docs/aspectos.md` en "Pendiente" pese a que el ADR-0001 ya existía | Se enlazó el ADR-0001 desde las filas de aspectos que efectivamente sustenta (A-01, A-02, A-04, A-05, A-06); se dejó A-03 sin enlace por no tener sustento real en la decisión documentada | `docs/aspectos.md` | Corregida |
| Escenario Q-01 no enlazaba al ADR-0001 | Se agregó una columna ADR a la tabla de la sección 10.4 de `10-quality-requirements.md`, enlazando Q-01 y Q-02 al ADR correspondiente | `docs/arc42/10-quality-requirements.md`, sección 10.4 | Corregida |
| Sin pipeline ni evidencia de ejecución de las pruebas | Se agregó `.github/workflows/ci.yml` con dos jobs (backend y frontend) | `.github/workflows/ci.yml` | Corregida |
| Concentración de commits (JuanchisV 21 de 46 en S3) | Ver seguimiento consolidado al final de este documento | `git shortlog -sne` por periodo | Parcial (ver nota consolidada) |

---

## S4 — Hallazgos y su estado actual

| Hallazgo (semana-04-evidencia-s4) | Acción realizada | Evidencia | Estado |
|---|---|---|---|
| Sección 9 de arc42 no enlazaba el ADR-0002 existente | Se agregó ADR-0002 al índice de decisiones (9.1) y se relacionó con los aspectos que sustenta (9.2) | `docs/arc42/09-architecture-decisions.md` | Corregida |
| ADR-0001 y ADR-0002 sin sección de trazabilidad (commit/PR y pruebas) | Se agregó la sección "Trazabilidad" a ambos ADR, citando el aspecto sustentado, el elemento C4, los commits que lo implementan y las pruebas que lo cubren | `docs/adr/0001-seleccion-monolito-modular.md`, sección 10; `docs/adr/0002-seleccion-tecnologia-backend-frontend.md`, sección 9 | Corregida |
| Sin evidencia de ejecución en verde del pipeline para las pruebas del corte vertical | Se citó la URL del run de GitHub Actions correspondiente en la columna "Pruebas" de la fila A-01 | `docs/aspectos.md`, fila A-01; [run](https://github.com/ISCOUTB/AS_202620_DinamikUTB/actions/runs/33475979818) | Corregida |
| `docs/aspectos.md` y `docs/ia.md` marcados "No verificado" por falta de contenido en la revisión automática | Ambos archivos están completos y actualizados en el estado actual del repositorio | `docs/aspectos.md`, `docs/ia.md` | Corregida |
| Commits de corrección de `start.bat` posteriores al cierre de S4 | No aplica corrección retroactiva sobre el estado calificado de S4; el `start.bat` corregido ya está vigente en el estado actual del repositorio, verificado end-to-end (creación de entorno virtual, instalación de dependencias, backend y frontend arrancando juntos) | `start.bat`; verificación manual documentada en la sesión de trabajo del equipo | Corregida en el estado actual (histórico de S4 no se recalifica) |

---

## S5 (revisión preliminar) — Hallazgos y su estado actual

| Hallazgo (semana-05-corte1, revisión preliminar) | Acción realizada | Evidencia | Estado |
|---|---|---|---|
| No existe la etiqueta `corte-1` | Ver nota dedicada al inicio de este documento (instrucción del docente) | — | Ajustada por instrucción del docente |
| ADR-0003 formaliza una decisión pendiente de la línea base (motor de BD) en vez de responder a una restricción nueva | Ver nota dedicada al inicio de este documento (no hubo restricción asignada, confirmado por el docente); el ADR-0003 sigue siendo válido como cierre de una brecha documental real (`02-architecture-constraints.md` §2.1 dejaba el motor sin decidir desde S2) | `docs/adr/0003-seleccion-motor-de-base-de-datos.md` | Rechazada con justificación (no aplica sin restricción asignada) |
| Cadena de trazabilidad de A-08 se corta en Código/Pruebas/Evidencia | Se mantiene honesto: A-08 no tiene código implementado todavía. La fila de `docs/aspectos.md` indica explícitamente que el ADR-0003 cubre solo el motor transaccional de forma parcial, y que el mecanismo de almacenamiento del historial requiere un ADR adicional | `docs/aspectos.md`, fila A-08 | Pendiente (corregida posteriormente) |
| `correcciones.md` anterior era una autoevaluación genérica sin evidencia citable | Se reconstruyó este archivo completo, citando hallazgo, acción, evidencia verificable y estado por cada fila | Este archivo | Corregida |

---

## Concentración de commits (seguimiento consolidado, S2–S4)

Este hallazgo se repite desde S2 y no se cierra con una sola acción puntual, por lo que se documenta de forma consolidada en vez de repetirlo en cada sección:

- **S2:** JuanchisV concentró 35 de 36 commits del periodo.
- **S3:** JuanchisV concentró 21 de 46 commits del periodo; Esteban Ramírez Ríos retomó su participación (2 commits), cerrando el hallazgo de ausencia total de S1.
- **S4/S5 (estado actual, `git shortlog -sne`):** distribución consolidada por persona: Juan José Vargas Pérez ~104, Luis Daniel Padilla Leottau ~37, Gillianis Pérez Revolledo ~23, Esteban Ramírez Ríos ~7.

**Estado: parcial.** Los cuatro integrantes contribuyen de forma verificable en cada periodo reciente (a diferencia de S1), pero la distribución sigue siendo desigual. El equipo reconoce el desbalance y se compromete a repartir de forma más equitativa el trabajo de las semanas restantes del curso.
