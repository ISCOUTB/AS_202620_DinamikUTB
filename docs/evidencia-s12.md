# Evidencia S12 · Estrategia de datos y eventos

- Repositorio: https://github.com/ISCOUTB/AS_202620_DinamikUTB
- Commit evaluado: `<hash completo>` · fecha: `<fecha del commit>`

## Dónde está cada entregable

| Criterio de la ficha | Dónde está |
|---|---|
| Tabla operación → garantía de consistencia | [arc42 §8.8](arc42/08-cross-cutting-concepts.md) (12 operaciones reales de la API y del arranque) |
| Dos operaciones verificadas contra el código | Más abajo |
| Diseño de caché: qué, dónde, cuánto | [arc42 §8.9](arc42/08-cross-cutting-concepts.md): decisión de no tener caché de servidor e inventario de las copias existentes |
| Política de invalidación tras escritura | [arc42 §8.9](arc42/08-cross-cutting-concepts.md): servidor sin copia; cliente invalidado con la respuesta del `PUT` (propia) o recarga manual (ajena); operación que se rompe y plan |
| Garantías del flujo por eventos | [arc42 §8.10](arc42/08-cross-cutting-concepts.md): no hay flujo por eventos ni broker |
| ADR de la decisión más costosa de revertir | [ADR-0011](adr/0011-historial-de-cambios-transaccional.md) |
| Argumento de por qué es la más costosa | ADR-0011, sección 2 (comparación con 4 decisiones alternativas) y sección 6 (costo de reversión) |
| Almacenes y brokers en el C4 nivel 2 | [docs/c4/contenedores.puml](c4/contenedores.puml): bases (SQLite local, Postgres desplegado), almacén de sesión del cliente y registro operativo; sin broker, declarado en el pie |
| arc42 sección 8 con consistencia y caché | [arc42 §8.8–8.11](arc42/08-cross-cutting-concepts.md) |

## Dos operaciones contrastadas con el código

**Fuerte: `PUT /requisitos/{id}/estado` con su historial (filas 1 y 2).**

```bash
git grep -nE "(db\.add\(RequisitoHistorial|RequisitoHistorial\(|db\.commit\(\))" -- backend/app/requisitos/service.py
```

Se esperan `RequisitoHistorial(`, `db.add(` y **un único** `db.commit()` en `actualizar_estado_requisito`: el `UPDATE` y la fila de historial se confirman juntos. La prueba `test_si_falla_el_historial_el_cambio_no_queda_aplicado` fuerza una violación `NOT NULL` en el historial y comprueba que el estado sigue como estaba.

**Eventual / mejor esfuerzo: log de auditoría y pantalla de inicio (filas 3 y 6).**

```bash
git grep -nE "(auditoria_cambio_estado|Future\.wait)" -- backend/app frontend/lib
```

El log se emite después del `commit` (puede perderse, por eso no es el registro de auditoría), y `dashboard_screen.dart` lanza tres consultas con `Future.wait` sin instantánea común. El desfase se acepta y se reconcilia al actualizar.

## Qué existe en el código que parece caché

```bash
git grep -nIE '(redis|memcach|cache|ttl|expire)' HEAD -- . ':!docs'
```

Las coincidencias son: `@lru_cache` de `get_settings` (configuración, no datos), `Cache-Control: no-store` en `main.py` (el opuesto a una caché), `cache_clear()` en pruebas y la expiración (`exp`) del JWT. No hay caché de datos de dominio; ver [arc42 §8.9](arc42/08-cross-cutting-concepts.md).

## Limitaciones declaradas

- El historial solo cubre cambios de estado de `requisitos/` y **no tiene endpoint de consulta** (RF-08 y Q-08 parciales).
- La durabilidad del historial es la de la base; la gratuita de Render expira a los 30 días (F7).
- Sin control de versión en las escrituras: última escritura gana (F6). La prueba existente es secuencial, no demuestra una carrera.
- Las filas 6, 3 y 10 de la tabla de consistencia están descritas, sin prueba automatizada.
- Referencias entre módulos sin clave foránea: pueden existir filas huérfanas (fila 11).
- No se ejecutó prueba de carga ni medición de latencia que respalde la decisión de no tener caché: se apoya en el volumen de `docs/costos.md` y se reabre ante una medición real.

## Archivos de este cambio

`backend/app/requisitos/models.py`, `backend/app/requisitos/service.py`, `backend/tests/test_historial.py`, `docs/adr/0011-historial-de-cambios-transaccional.md`, `docs/c4/contenedores.puml`, `docs/arc42/08*`, `09*`, `10*`, `11*`, `docs/aspectos.md`, `docs/ia.md`, `README.md`.
