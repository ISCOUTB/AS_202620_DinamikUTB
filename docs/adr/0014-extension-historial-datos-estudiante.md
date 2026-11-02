---
id: ADR-0014
title: Extensión del historial de cambios a la información académica del estudiante
status: Aceptado
date: 2026-10-30
deciders: Equipo de arquitectura DinamikUTB
---

# ADR-0014: Extensión del historial de cambios a la información académica del estudiante

![Status: Aceptado](https://img.shields.io/badge/Status-Accepted-brightgreen?style=flat-square)
![Date: 2026--10--30](https://img.shields.io/badge/Date-2026--10--30-blue?style=flat-square)
![Scope: Data](https://img.shields.io/badge/Scope-Data-orange?style=flat-square)

---

## 1. Contexto y relación con el ADR-0011

El [ADR-0011](0011-historial-de-cambios-transaccional.md) estableció el mecanismo fundamental del historial de cambios de DinamikUTB (A-08 / Q-08): tablas de auditoría *append-only* en la misma base y confirmadas en la misma transacción que la mutación. En su momento, el sistema solo disponía de escrituras sobre el estado de los requisitos (`requisitos_historial`).

Posteriormente se incorporaron operaciones de escritura sobre la información del estudiante (`POST /estudiantes`, `PUT /estudiantes/{codigo}/administrativo`, `PUT /auth/mi-perfil` y el renombre masivo en `PUT /programas/{id}`). Para evitar vacíos de trazabilidad y satisfacer íntegramente el escenario [Q-08](../arc42/10-quality-requirements.md#escenario-q-08--historial-de-cambios-sobre-la-información-académica) (100 % de modificaciones sobre datos académicos registradas), se formaliza la extensión de este patrón sin alterar el ADR-0011 aceptado.

Asimismo, se aclara que la consideración histórica del ADR-0011 §2 respecto a la ausencia de catálogo de requisitos quedó superada con la incorporación del modelo `RequisitoPrograma` y `catalogo_id` (A-06).

---

## 2. Decisión

1. **Extensión del patrón al módulo `estudiantes/`:** Se crea la tabla `estudiantes_historial` (`id`, `estudiante_id`, `campo`, `valor_anterior`, `valor_nuevo`, `actor_id`, `creado_en`) administrada exclusivamente por `estudiantes/`.
2. **Alcance de los campos auditados:** Son datos académicos sujetos a historial el `nombre`, `programa` y `semestre` del estudiante.
3. **Exclusiones deliberadas (datos administrativos):** Los campos `rol` y `activo` de la cuenta de usuario pertenecen al contexto `usuarios/`. Son credenciales y permisos administrativos de control de acceso (A-05), no datos académicos de grado; por ende, quedan fuera del historial de modificaciones curriculares.
4. **Renombre masivo de programas:** Cuando un administrador renombra un programa académico en `programas/`, la actualización masiva de `Estudiante.programa` se delega en `estudiantes.service.actualizar_programa_masivo`, confirmando en una única transacción la modificación del programa, los registros del estudiante y las filas correspondientes en `estudiantes_historial`.

---

## 3. Consecuencias

### Positivas
- Se elimina la brecha de auditoría en los datos del estudiante: ningún cambio de nombre, programa o semestre ocurre sin su fila de auditoría atómica.
- Se preserva el límite de contexto delimitado: `programas/` no hace `UPDATE` ciego sobre tablas ajenas; delega en el servicio dueño.
- Coherencia total con Q-08.

### Negativas
- Mayor volumen de inserciones transaccionales durante operaciones de renombre de programas (una fila de historial por cada estudiante matriculado). Volumen despreciable para las dimensiones del piloto universitario.

---

## 4. Trazabilidad

| Elemento | Referencia |
|---|---|
| **Decisión complementada** | [ADR-0011](0011-historial-de-cambios-transaccional.md) |
| **Aspecto sustentado** | [A-08](../aspectos.md#a-08--historial-de-cambios-sobre-la-información-académica) |
| **Escenarios de calidad** | [Q-08](../arc42/10-quality-requirements.md#escenario-q-08--historial-de-cambios-sobre-la-información-académica) |
| **Código** | `backend/app/estudiantes/models.py` (`EstudianteHistorial`), `backend/app/estudiantes/service.py` |
