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
| `estudiantes/` → `requisitos/` | Cliente-Proveedor | `requisitos/` consulta el avance registrado en `estudiantes/` para calcular el estado de un requisito (A-02). `estudiantes/` no conoce ni depende de `requisitos/`. |
| `programas/` → `requisitos/` | Cliente-Proveedor | `requisitos/` consulta qué requisitos aplican según el programa académico del estudiante. `programas/` no depende de `requisitos/`. |
| `estudiantes/` → `ayuda/` | Cliente-Proveedor | `ayuda/` necesita identificar al estudiante que envía una solicitud. |
| *(ninguno)* → externo | Capa anticorrupción | No aplica: el alcance actual no integra sistemas externos. Se documentará cuando exista una integración real. |

## 8.3 Estado de implementación por contexto

Siguiendo la misma disciplina de honestidad aplicada en el resto de la documentación (ver README, sección "Usuarios"): este mapa describe el diseño completo del sistema, no todos los contextos tienen código todavía.

| Contexto | Diseñado desde | Código real |
|---|---|---|
| `requisitos/` | S2 (ADR-0001) | Sí — modelo, servicio, router, esquema (S4) |
| `usuarios/`, `estudiantes/`, `programas/`, `ayuda/` | S2 (ADR-0001) | No — solo estructura de carpetas |

## 8.4 Propiedad de datos por módulo

| Módulo (dueño) | Entidad | Ubicación en código | Quién más la lee (vía servicio, no acceso directo) |
|---|---|---|---|
| `requisitos/` | `Requisito` | `backend/app/requisitos/models.py` | Ninguno todavía, solo el propio módulo escribe y lee. |
| `estudiantes/` | *(sin entidad implementada)* | — | — |
| `programas/` | *(sin entidad implementada)* | — | — |
| `usuarios/` | *(sin entidad implementada)* | — | — |
| `ayuda/` | *(sin entidad implementada)* | — | — |

Solo existe una entidad real hoy (`Requisito`), con un único dueño (`requisitos/`) y sin ningún otro módulo escribiéndola — condición de dueño único trivialmente satisfecha porque no hay contención posible todavía. Esta tabla se ampliará a medida que se implementen los demás módulos.

## 8.5 Violaciones de propiedad de datos detectadas

**Método de verificación:** se buscó en todo `backend/app` cualquier operación de escritura a base de datos (`INSERT`, `UPDATE`, `session.add`, `session.commit`, `db.add`, `db.commit`) fuera del módulo dueño de cada entidad.

```bash
git grep -nIE "(INSERT INTO|UPDATE |session\.add\(|session\.commit\(|db\.add\(|db\.commit\()" -- backend/app
```

**Resultado:** backend/app/seed.py:39: db.commit()


**Conclusión:** no se detectaron violaciones de propiedad de datos, porque no hay contención posible todavía: solo existe una escritura real en todo el backend, y está en `backend/app/seed.py`, un script de datos de ejemplo para desarrollo local, no parte del flujo de la aplicación. El endpoint implementado (`GET /requisitos/{estudiante_id}`) es de solo lectura; no existe todavía ningún endpoint que escriba un `Requisito` desde la API, y ningún otro módulo (`estudiantes/`, `programas/`, `usuarios/`, `ayuda/`) tiene entidades ni lógica de persistencia implementada.

Esta ausencia de violaciones no es una garantía futura: en cuanto se implemente el endpoint de creación/actualización de requisitos (necesario para A-02, cálculo del avance) o cualquier lógica en los módulos vacíos, esta verificación debe repetirse, es la primera acción del plan de corrección declarado más abajo, aunque hoy no exista una violación real que corregir.

**Plan de corrección (preventivo, no reactivo):** dado que hoy no hay violaciones, el plan no es de corrección sino de prevención, para que no aparezcan cuando se implementen los módulos restantes:

| Acción preventiva | Cuándo aplica |
|---|---|
| Ningún módulo accede directamente a `session`/`db` de otro módulo; toda escritura pasa por la función de servicio del módulo dueño de la entidad. | Ya vigente en el único módulo con código (`requisitos/`); se debe mantener al implementar `estudiantes/`, `programas/`, `usuarios/`, `ayuda/`. |
| Repetir el comando de verificación de esta sección antes de cada corte, no solo en la semana 6. | A partir de ahora, como parte del checklist de cada entrega. |
