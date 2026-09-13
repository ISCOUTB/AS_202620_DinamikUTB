# 8. Cross-cutting Concepts

## 8.1 Lenguaje ubicuo

Términos del dominio compartidos entre el equipo, el código y la documentación, para que una palabra signifique lo mismo en todos los contextos. Complementa el glosario general (`docs/arc42/12-glossary.md`) con el vocabulario específico de contextos delimitados de esta semana.

| Término | Significado dentro de DinamikUTB |
|---|---|
| **Contexto delimitado** (Bounded Context) | Frontera dentro de la cual un término del dominio tiene un significado único y consistente. En DinamikUTB, cada módulo (`usuarios/`, `estudiantes/`, `requisitos/`, `programas/`, `ayuda/`) es un contexto delimitado. |
| **Núcleo compartido** (Shared Kernel) | Contexto cuya funcionalidad es consumida directamente por todos los demás, sin que ellos dupliquen su lógica. `usuarios/` cumple este rol: resuelve autenticación y rol una sola vez, reutilizada por el resto. |
| **Cliente / Proveedor** (Customer/Supplier) | Relación donde un contexto (cliente) consume datos o servicios de otro (proveedor), sin que el proveedor conozca al cliente. `requisitos/` es cliente de `estudiantes/` y `programas/`. |
| **Capa anticorrupción** (Anticorruption Layer) | Mecanismo que traduce el modelo de un sistema externo al modelo propio, para no contaminar el dominio con conceptos ajenos. No existe todavía en DinamikUTB porque el alcance actual no contempla integraciones con sistemas externos (`01-introduction-and-goals.md`, sección 1.5). |
| **Dueño único de datos** | Cada entidad de datos pertenece a exactamente un módulo, que es el único autorizado a escribirla. Los demás módulos que necesiten esa información la consultan a través del servicio del módulo dueño, nunca accediendo directo a su tabla. |

## 8.2 Mapa de contextos

```text
                         ┌────────────────┐
                         │   usuarios/    │
                         │ (núcleo        │
                         │  compartido)   │
                         └───────┬────────┘
                    consumido por│ (autenticación y rol)
              ┌──────────────────┼──────────────────┬──────────────┐
              ▼                  ▼                  ▼              ▼
     ┌────────────────┐ ┌────────────────┐ ┌────────────────┐ ┌──────────┐
     │  estudiantes/  │ │   programas/   │ │  requisitos/   │ │  ayuda/  │
     │  (proveedor)   │ │  (proveedor)   │ │   (cliente)    │ │          │
     └───────┬────────┘ └───────┬────────┘ └────────────────┘ └────┬─────┘
             │  cliente/proveedor │                                │
             └───────────────────┴───────────────►  requisitos/    │
                                                                    │
                                            consume datos de ───────┘
                                            estudiantes/ (solicitudes)
```

| Relación | Tipo | Descripción |
|---|---|---|
| `usuarios/` → todos los demás | Núcleo compartido | Autenticación y resolución de rol, consumida sin duplicar lógica (ver `05-building-block-view.md`, sección 5.2, "Reglas de dependencia entre módulos"). |
| `estudiantes/` → `requisitos/` | Cliente-Proveedor | `requisitos/` consulta el avance registrado en `estudiantes/` para calcular el estado de un requisito (A-02). Ambos módulos ya tienen código propio (`Estudiante` y `Requisito`), pero `requisitos/` todavía no consulta datos de `estudiantes/` en tiempo de ejecución — la relación existe en el diseño, la consulta cruzada real queda para una siguiente iteración. `estudiantes/` no conoce ni depende de `requisitos/`. |
| `programas/` → `requisitos/` | Cliente-Proveedor | `requisitos/` consulta qué requisitos aplican según el programa académico del estudiante. `programas/` no depende de `requisitos/`. Sin código todavía en ninguno de los dos lados de esta relación específica. |
| `estudiantes/` → `ayuda/` | Cliente-Proveedor | `ayuda/` necesita identificar al estudiante que envía una solicitud. |
| *(ninguno)* → externo | Capa anticorrupción | No aplica: el alcance actual no integra sistemas externos. Se documentará cuando exista una integración real. |

## 8.3 Estado de implementación por contexto

Siguiendo la misma disciplina de honestidad aplicada en el resto de la documentación (ver README, sección "Usuarios"): este mapa describe el diseño completo del sistema, no todos los contextos tienen código todavía.

| Contexto | Diseñado desde | Código real |
|---|---|---|
| `requisitos/` | S2 (ADR-0001) | Sí — modelo, servicio, router, esquema, incluyendo consulta y actualización de estado (S4, S6) |
| `estudiantes/` | S2 (ADR-0001) | Sí — modelo, servicio, router de consulta (S6) |
| `usuarios/`, `programas/`, `ayuda/` | S2 (ADR-0001) | No — solo estructura de carpetas |

## 8.4 Propiedad de datos por módulo

| Módulo (dueño) | Entidad | Ubicación en código | Quién más la lee (vía servicio, no acceso directo) |
|---|---|---|---|
| `requisitos/` | `Requisito` | `backend/app/requisitos/models.py` | Ninguno — solo el propio módulo lee y escribe. |
| `estudiantes/` | `Estudiante` | `backend/app/estudiantes/models.py` | Ninguno todavía — `requisitos/` está diseñado para consultarlo (ver 8.2), pero el código actual no hace esa llamada cruzada. |
| `programas/` | *(sin entidad implementada)* | — | — |
| `usuarios/` | *(sin entidad implementada)* | — | — |
| `ayuda/` | *(sin entidad implementada)* | — | — |

Cada entidad tiene un único dueño y, en el código actual, un único módulo que la escribe o la lee — condición de dueño único satisfecha en ambos casos.

## 8.5 Violaciones de propiedad de datos detectadas

**Método de verificación:** se buscó en todo `backend/app` cualquier operación de escritura a base de datos (`INSERT`, `UPDATE`, `session.add`, `session.commit`, `db.add`, `db.commit`) fuera del módulo dueño de cada entidad.

```bash
git grep -nIE "(INSERT INTO|UPDATE |session\.add\(|session\.commit\(|db\.add\(|db\.commit\()" -- backend/app
```

**Resultado:** 
backend/app/requisitos/service.py:18: db.commit()
backend/app/seed.py:39: db.commit()


**Conclusión:** no se detectaron violaciones de propiedad de datos. Las dos escrituras encontradas son:

- `requisitos/service.py:18` — dentro de la función de servicio del propio módulo dueño de `Requisito`, disparada por el endpoint `PUT /requisitos/{requisito_id}/estado`. Es la escritura correcta en el lugar correcto.
- `seed.py:39` — script de datos de ejemplo para desarrollo local, fuera del flujo normal de la aplicación; no representa un módulo escribiendo la entidad de otro.

`estudiantes/` no aparece en el resultado porque hoy es de solo lectura (no tiene endpoint de creación), y ningún módulo escribe la tabla `estudiantes` desde fuera de su propio servicio.

Esta ausencia de violaciones no es una garantía futura: en cuanto se implemente el endpoint que consulte `estudiantes/` desde `requisitos/` (para completar A-02), o se agreguen `programas/`, `usuarios/` y `ayuda/`, esta verificación debe repetirse.

**Plan de corrección (preventivo, no reactivo):**

| Acción preventiva | Cuándo aplica |
|---|---|
| Ningún módulo accede directamente a `session`/`db` de otro módulo; toda escritura pasa por la función de servicio del módulo dueño de la entidad. | Ya vigente en `requisitos/` y `estudiantes/`; se debe mantener al implementar `programas/`, `usuarios/`, `ayuda/`, y al conectar `requisitos/` con `estudiantes/` como lectura cruzada. |
| Cuando `requisitos/` consulte datos de `estudiantes/`, debe hacerlo llamando a una función de `estudiantes/service.py`, nunca importando `Estudiante` y consultando la tabla directamente desde `requisitos/`. | Antes de implementar la lectura cruzada para A-02. |
| Repetir el comando de verificación de esta sección antes de cada corte. | A partir de ahora, como parte del checklist de cada entrega. |

## 8.6 C4 nivel 3 y ADR de reajuste

No aplica esta semana. Los cinco contextos del mapa (8.2) son los mismos definidos desde el ADR-0001 (S2): no hubo cambio en los límites entre contextos, solo incorporación de código dentro de límites ya existentes. La ficha de esta semana exime del C4 nivel 3 y del ADR de reajuste cuando los límites no cambian respecto al corte anterior.
## 8.7 Correspondencia entre aspectos y contextos

| Aspecto | Contexto(s) del mapa | Observación |
|---|---|---|
| A-01 — Seguimiento de requisitos | `requisitos/` | Correspondencia directa y clara. |
| A-02 — Cálculo del estado de graduación | `requisitos/` (cliente), `estudiantes/` (proveedor) | Correspondencia clara; requiere la relación cliente-proveedor documentada en 8.2, todavía no implementada en código (ver 8.4). |
| A-05 — Protección y control de acceso | `usuarios/` | Correspondencia directa; `usuarios/` es el núcleo compartido que resuelve este aspecto para todos los demás contextos. |
| A-06 — Extensibilidad para múltiples programas | `programas/` | Correspondencia directa. |
| A-07 — Gestión de solicitudes del centro de ayuda | `ayuda/` | Correspondencia directa. |
| A-03 — Alertas tempranas de requisitos pendientes | **Sin contexto asignado** | No se ha decidido si esta lógica vive dentro de `requisitos/` (como una extensión del cálculo de estado) o si merece su propio contexto. Pendiente de una decisión explícita, igual que ya está anotado en `docs/aspectos.md` ("mecanismo de disparo sin decidir"). |
| A-04 — Disponibilidad del sistema | **Transversal, no asignable a un solo contexto** | Es un atributo de calidad de infraestructura y despliegue (ver ADR-0001, sección 8), no una responsabilidad de dominio que pertenezca a un contexto delimitado específico. No se fuerza una asignación artificial. |
| A-08 — Historial de cambios | **Sin contexto asignado** | Afecta a todos los contextos que modifican datos (`requisitos/`, y a futuro `estudiantes/`, `programas/`), pero no tiene un dueño único definido — podría requerir su propio contexto ("auditoría") o resolverse de forma transversal. `docs/aspectos.md` ya lo marca como parcialmente resuelto por el ADR-0003, sin mecanismo de almacenamiento decidido. |

**Conclusión:** 5 de 8 aspectos corresponden con claridad a uno de los cinco contextos del mapa. Los tres restantes (A-03, A-04, A-08) no tienen esa correspondencia, dos por falta de una decisión explícita todavía (A-03, A-08), y uno porque su naturaleza es transversal y no de dominio (A-04). Ninguno de los tres se fuerza a un contexto para completar la tabla artificialmente.

