---
id: ADR-0016
title: Módulo ayuda y aislamiento de solicitudes por programa
status: Propuesto
date: 2026-11-20
deciders: Equipo de arquitectura DinamikUTB
---

# ADR-0016: Módulo `ayuda/` y aislamiento de solicitudes por programa


## 1. Contexto y descripción del problema

El estudiante no puede modificar su información académica ([02 §2.2](../arc42/02-architecture-constraints.md)). Si ve un error (una materia aprobada sin marca, una nota mal), necesita un canal formal. `ayuda/` estaba diseñado desde ADR-0001 (RF-07, A-07, Q-07) y sin código. Q-07 exige que un coordinador **no pueda ver** solicitudes de otro programa.

El problema técnico: `Usuario` no tiene programa, y agregárselo haría que `usuarios/` conociera el dominio académico.

## 2. Factores de decisión

| Factor | Descripción |
| :--- | :--- |
| **Aislamiento (Q-07, Q-02)** | 100 % de intentos de ver solicitudes ajenas rechazados. |
| **Propiedad de datos** | `usuarios/` no debe depender de programas. |
| **No filtrar existencia** | Un coordinador ajeno no debe poder distinguir «no existe» de «no es tuyo». |
| **Radicado único sin carreras** | Dos solicitudes simultáneas no deben recibir el mismo número. |

## 3. Alternativas consideradas

### 3.1 Columna `programa` en `Usuario`
* **Desventajas:** `usuarios/` pasa a conocer programas; migración de una tabla de seguridad.
* **Descartada.**

### 3.2 Directorio `coordinadores_programa` en `ayuda/`, enlazado por correo
* **Ventajas:** el mismo directorio alimenta la tarjeta «tu coordinador» (nombre, oficina, campus, horario) y el filtro de visibilidad; `usuarios/` no cambia; un coordinador puede atender varios programas.
* **Desventajas:** el vínculo es el correo; si cambia en una tabla y no en la otra, el coordinador pierde acceso (falla cerrada, no abierta).
* **Seleccionada.**

### 3.3 Radicado con contador propio o `MAX(id)+1`
* **Descartada:** carrera entre solicitudes simultáneas.

### 3.4 Radicado derivado del `id` autoincremental: `UTB-RAD-{año}-{id:04d}`
* **Seleccionada.** Se inserta con un valor temporal, se hace `flush` para obtener el `id` y se fija el radicado en la misma transacción.

## 4. Decisión

1. Modelos `SolicitudDiscrepancia` y `CoordinadorPrograma` en `backend/app/ayuda/`.
2. `POST /ayuda/solicitudes`: solo rol estudiante; el programa se toma del perfil del estudiante, nunca del cuerpo.
3. `GET /ayuda/solicitudes`: estudiante → las suyas; coordinador → las de los programas donde figura por correo; administrador → todas; coordinador sin entrada en el directorio → ninguna.
4. `PUT /ayuda/solicitudes/{id}/estado`: `GestorUser`, con el mismo filtro de visibilidad. Fuera de alcance responde 404. `resuelta` exige respuesta escrita. Repetir el mismo cambio no modifica nada.
5. `GET /ayuda/coordinador`: devuelve el coordinador del programa del estudiante o del coordinador; el administrador debe indicar `?programa=`.
6. Los datos del directorio sembrados son de ejemplo y deben reemplazarse por los reales.

## 5. Consecuencias

### Positivas
* Q-07 se verifica con pruebas (15 solicitudes en dos programas).
* `usuarios/` queda intacto.
* Un solo directorio sirve para mostrar y para autorizar.

### Negativas
* Las solicitudes no tienen historial propio: solo estado, respuesta y `actualizado_en`. Si se quiere auditar cada transición, se necesitará una tabla `solicitudes_historial` (mismo patrón de ADR-0011).
* El directorio se administra por base de datos o `seed`; no hay pantalla de administración todavía.
* `ayuda/` consulta `estudiantes/` solo a través de `obtener_estudiante`.

## 6. Relación con atributos de calidad

| Atributo | Relación |
| :--- | :--- |
| **Seguridad** | Aislamiento por programa y rol, probado. |
| **Trazabilidad** | Radicado, estudiante, fecha, estado. |
| **Mantenibilidad** | Sin cambios en `usuarios/`. |

## 7. Estado de la decisión

**Propuesto.** Completa lo previsto en [ADR-0001](0001-seleccion-monolito-modular.md); no lo reemplaza.

## 8. Trazabilidad

| Elemento | Referencia |
| :--- | :--- |
| **Aspecto** | [A-07](../aspectos.md#a-07--gestión-de-solicitudes-de-estudiantes-en-el-centro-de-ayuda) |
| **Escenarios** | [Q-07](../arc42/10-quality-requirements.md#escenario-q-07--gestión-de-solicitudes-del-centro-de-ayuda), [Q-02](../arc42/10-quality-requirements.md#escenario-q-02--seguridad-y-aislamiento-de-la-información) |
| **C4** | Backend API y bases de datos en `docs/c4/contenedores.puml` |
| **Código** | `backend/app/ayuda/` (`models.py`, `schemas.py`, `service.py`, `router.py`) |
| **Pruebas** | `backend/tests/test_ayuda.py` |
| **Commits** | `<completar con el hash del merge>` |
