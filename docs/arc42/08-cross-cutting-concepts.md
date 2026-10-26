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
| `usuarios/` | S2 (ADR-0001) | Sí — modelo `Usuario`, servicio (Argon2id, bloqueo por intentos), router (`/auth/login`, `/auth/me`) y dependencias de autenticación y autorización por rol |
| `requisitos/` | S2 (ADR-0001) | Sí — modelo, servicio, router y esquema: consulta, resumen de avance y actualización de estado con historial transaccional (S12, ADR-0011) |
| `estudiantes/` | S2 (ADR-0001) | Sí — modelo, servicio y router de consulta |
| `programas/`, `ayuda/` | S2 (ADR-0001) | No — solo estructura de carpetas |

## 8.4 Propiedad de datos por módulo

| Módulo (dueño) | Entidad | Ubicación en código | Quién más la lee (vía servicio, no acceso directo) |
|---|---|---|---|
| `usuarios/` | `Usuario` | `backend/app/usuarios/models.py` | Los demás módulos consumen la dependencia `CurrentUser` (`usuarios/dependencies.py`), no la tabla. |
| `requisitos/` | `Requisito`, `RequisitoHistorial` | `backend/app/requisitos/models.py` | Ninguno — solo el propio módulo lee y escribe. |
| `estudiantes/` | `Estudiante` | `backend/app/estudiantes/models.py` | Ninguno todavía — `requisitos/` está diseñado para consultarlo (ver 8.2), pero el código actual no hace esa llamada cruzada. |
| `programas/`, `ayuda/` | *(sin entidad implementada)* | — | — |

Cada entidad tiene un único dueño. Las referencias entre módulos (`Requisito.estudiante_id` y `Usuario.codigo_estudiantil` hacia `Estudiante.codigo_estudiantil`) son **por valor, sin clave foránea**, para no acoplar tablas entre módulos; su consecuencia sobre la consistencia está en 8.8 (fila 11).

## 8.5 Violaciones de propiedad de datos detectadas

**Método de verificación:** se buscó en todo `backend/app` cualquier operación de escritura a base de datos (`INSERT`, `UPDATE`, `session.add`, `session.commit`, `db.add`, `db.commit`) fuera del módulo dueño de cada entidad.

```bash
git grep -nIE "(INSERT INTO|UPDATE |session\.add\(|session\.commit\(|db\.add\(|db\.commit\()" -- backend/app
```

**Resultado (repetido en S12 sobre el commit vigente):**

```text
backend/app/requisitos/service.py:59:    db.add(
backend/app/requisitos/service.py:69:    db.commit()
backend/app/seed.py:68:            db.add(Estudiante(**ESTUDIANTE_DE_EJEMPLO))
backend/app/seed.py:79:        db.commit()
backend/app/usuarios/service.py:47:    db.add(usuario)
backend/app/usuarios/service.py:48:    db.commit()
backend/app/usuarios/service.py:74:        db.commit()
backend/app/usuarios/service.py:82:    db.commit()
```

**Conclusión:** no se detectan escrituras de un módulo sobre la entidad de otro dentro del flujo de la aplicación:

- `requisitos/service.py:59` y `:69` — `db.add(RequisitoHistorial(...))` y `db.commit()` dentro de `actualizar_estado_requisito`. Escribe `Requisito` y `RequisitoHistorial`, ambas del módulo `requisitos/`, en una sola transacción (ADR-0011).
- `usuarios/service.py:47-48` (`crear_usuario`) y `:74`, `:82` (`autenticar`: reinicio y conteo de intentos fallidos) — escriben únicamente `Usuario`, entidad del propio módulo.
- **Excepción reconocida:** `seed.py:68` y `:79` insertan `Estudiante` directamente (y `Requisito` mediante `db.add_all`, que el patrón de búsqueda no captura), sin pasar por los servicios dueños. Es un script de datos de ejemplo; también se ejecuta al arrancar el servicio desplegado, pero solo inserta si la tabla está vacía. Los usuarios demo sí se crean a través de `usuarios/service.crear_usuario`. Se acepta mientras `estudiantes/` no tenga endpoint de creación, y debe pasar por los servicios dueños cuando lo tenga.

`estudiantes/` no aparece en el resultado porque hoy es de solo lectura.

Esta ausencia de violaciones no es una garantía futura: en cuanto se implemente el endpoint que consulte `estudiantes/` desde `requisitos/` (para completar A-02), o se agreguen `programas/` y `ayuda/`, esta verificación debe repetirse.

**Plan de corrección (preventivo, no reactivo):**

| Acción preventiva | Cuándo aplica |
|---|---|
| Ningún módulo accede directamente a `session`/`db` de otro módulo; toda escritura pasa por la función de servicio del módulo dueño de la entidad. | Ya vigente en `requisitos/`, `estudiantes/` y `usuarios/`; se debe mantener al implementar `programas/` y `ayuda/`, y al conectar `requisitos/` con `estudiantes/` como lectura cruzada. |
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
| A-08 — Historial de cambios | `requisitos/` (primer módulo con historial) | Resuelto por patrón: cada módulo dueño registra su historial en su propia tabla, en la misma transacción (ADR-0011). Hoy solo `requisitos/` escribe datos académicos; `estudiantes/` y `programas/` lo adoptarán al tener escrituras. No se creó un contexto de "auditoría". |

**Conclusión:** 6 de 8 aspectos corresponden con claridad a uno de los cinco contextos del mapa (A-08 se incorporó en S12 como patrón por módulo dueño). Los dos restantes no tienen esa correspondencia: A-03 por falta de una decisión explícita sobre su mecanismo de disparo, y A-04 porque su naturaleza es transversal y no de dominio. Ninguno se fuerza a un contexto para completar la tabla artificialmente.

## 8.8 Estrategia de consistencia

**Principio.** Hay una sola base relacional por ambiente (SQLite en local y CI, PostgreSQL en el ambiente desplegado: [ADR-0003](../adr/0003-seleccion-motor-de-base-de-datos.md), [ADR-0007](../adr/0007-persistencia-render-postgres.md)), un solo proceso de backend ([ADR-0010](../adr/0010-extraccion-de-modulo.md)) y comunicación síncrona ([ADR-0004](../adr/0004-comunicacion-sincrona-frontend-backend.md)). Por eso la garantía por defecto es **fuerte por petición**: la respuesta se envía después del `commit` y lee solo datos confirmados. La consistencia eventual aparece únicamente donde esta tabla lo declara. Entre los ambientes desplegados (Render y laboratorio, [ADR-0012](../adr/0012-despliegue-en-servidor-del-laboratorio.md)) **no hay replicación**: cada uno tiene su propia base.

Garantías usadas: **Fuerte** (transacción confirmada antes de responder); **Fuerte por petición** (cada petición es consistente, varias seguidas no son un instante único); **Mejor esfuerzo** (estado en memoria, volátil); **Por convención** (sin restricción en la base).

| # | Operación | Garantía | Mecanismo en código | Desfase aceptado y reconciliación | Prueba |
|---|---|---|---|---|---|
| 1 | `PUT /requisitos/{id}/estado` | **Fuerte** | Un solo `db.commit()` en `requisitos/service.py` confirma el `UPDATE` y la fila de historial | Última escritura gana (sin control de versión, F6 de 11.5) | `test_idempotencia.py`, `test_historial.py` |
| 2 | Historial de ese cambio (`requisitos_historial`) | **Fuerte**, atómico con la fila 1 | Misma transacción ([ADR-0011](../adr/0011-historial-de-cambios-transaccional.md)) | Si falla el historial, el cambio no se aplica | `test_historial.py::test_si_falla_el_historial...` |
| 3 | Log `auditoria_cambio_estado` | **Mejor esfuerzo** (como máximo una vez) | `logger.info` después del `commit` | Puede perderse si el proceso muere entre `commit` y log; por eso **no** es el registro de auditoría (lo es la fila 2) | Sin prueba (telemetría) |
| 4 | `GET /requisitos/{id}` y `GET /estudiantes/{codigo}` | **Fuerte por petición** | Consulta directa a la base; sin réplicas, por lo que se ve lo propio recién escrito | Ninguno | `test_requisitos.py`, `test_estudiantes.py` |
| 5 | `GET /requisitos/{id}/resumen` | **Fuerte por petición** | Un único `GROUP BY` (`calcular_resumen`) | Ninguno dentro de la petición | `test_requisitos.py::test_resumen_...` |
| 6 | Pantalla de inicio del estudiante (3 `GET` en paralelo) | **Fuerte por petición, eventual entre peticiones** | `Future.wait` en `dashboard_screen.dart` | Si un `PUT` cae entre las tres consultas, contadores y lista pueden diferir momentáneamente; converge al deslizar para actualizar. El porcentaje solo lo calcula el backend (Q-01) | Sin prueba (descrito) |
| 7 | `POST /auth/login` | **Fuerte por fila**, con contador de intentos no atómico | `autenticar` actualiza `intentos_fallidos` y confirma | `intentos_fallidos += 1` es leer-modificar-escribir sin bloqueo: dos fallos simultáneos pueden contarse como uno y el bloqueo llegar levemente tarde; lo acota el limitador por IP (fila 8) | `test_auth.py` (bloqueo) |
| 8 | Limitador de login por IP | **Mejor esfuerzo, volátil** | `LimitadorVentana` en memoria | Se reinicia con el *spin down* y no se comparte entre instancias | `test_auth.py::test_login_limita_el_ritmo_por_ip` |
| 9 | Autorización en cada petición | **Fuerte** | `get_current_user` lee `Usuario` de la base cada vez | Desactivar un usuario o cambiar su rol es inmediato. **Cerrar sesión solo borra el token en el cliente**: el JWT sigue válido hasta su expiración (30 min), revocación eventual acotada | `test_auth.py::test_usuario_desactivado...` |
| 10 | Creación de usuarios y arranque (`python -m app.seed`) | **Idempotente por tabla** | Inserta si la tabla está vacía; estudiante y requisitos en un `commit`, cada usuario demo en el suyo | Un fallo a medias se completa en el siguiente arranque; sin exclusión mutua entre instancias (hay una por ambiente) | Sin prueba (`seed.py` excluido de cobertura) |
| 11 | Referencias entre módulos (`Requisito.estudiante_id`, `Usuario.codigo_estudiantil` → `Estudiante`) | **Por convención** | Sin clave foránea (propiedad de datos, 8.4) | Pueden existir filas huérfanas; consultar un estudiante sin datos devuelve lista vacía con 200. Se reconcilia validando al crear (no hay endpoint de creación todavía) | `test_requisitos.py::test_estudiante_sin_requisitos...` |
| 12 | `GET /metrics` | **Mejor esfuerzo, volátil** | Contadores en memoria con *lock* | Se ponen a cero con cada reinicio o *spin down* | `test_health.py::test_metrics...` |

**Verificación contra el código** (detalle en [docs/evidencia-s12.md](../evidencia-s12.md)):

- *Fuerte (fila 1):* `requisitos/service.py` agrega `RequisitoHistorial` (línea 59) y llama a un único `db.commit()` (línea 69); ninguna escritura queda fuera de esa transacción.
- *Eventual / mejor esfuerzo (filas 3 y 6):* `logger.info("auditoria_cambio_estado"...)` va después del `commit`, y `dashboard_screen.dart` lanza tres peticiones con `Future.wait`, sin instantánea común.

## 8.9 Estrategia de caché

**Decisión: no hay caché de datos académicos en el servidor.** Razones:

1. **Q-01 exige 100 % de correspondencia** con lo registrado. Una caché agrega una ventana de datos viejos que solo se justifica si hay un problema de latencia que resolver.
2. **No hay ese problema.** Con el volumen de [docs/costos.md](../costos.md) (~2 000 cargas al mes) y consultas por columna indexada sobre pocas filas por estudiante, la latencia de la base es despreciable frente a la verdadera demora: el arranque en frío de Render (~1 min), que una caché en proceso **no resuelve** porque se pierde con el *spin down*.
3. **Una caché compartida (Redis o similar) sería otro servicio**, fuera del límite de costo cero y de los 512 MB del laboratorio ([ADR-0010](../adr/0010-extraccion-de-modulo.md), criterio C3).
4. **Las respuestas llevan `Cache-Control: no-store`** (`backend/app/main.py`) de forma deliberada: contienen datos personales y ni el navegador ni intermediarios deben guardarlas.

**Inventario de lo que se comporta como caché:**

| Elemento | Qué guarda | Dónde | Vida | Qué lo invalida | Riesgo |
|---|---|---|---|---|---|
| `get_settings()` (`@lru_cache`) | Configuración de entorno | Memoria del proceso | El proceso | Reinicio (en pruebas, `cache_clear()`) | Ninguno: inmutable en ejecución |
| Estado de pantalla Flutter (`AsyncView` + `IndexedStack`) | Respuestas de las consultas | Memoria del cliente | Hasta recargar | (a) Escritura propia: `GestionRequisitosScreen` reemplaza el elemento con la respuesta del `PUT`. (b) Escritura ajena: deslizar para actualizar o *Reintentar*. (c) Cerrar sesión: se destruye el árbol de pantallas | Datos desactualizados tras escritura ajena (ver abajo) |
| Token JWT (`flutter_secure_storage`) | Credencial | Cliente | 30 min | `401` → `onUnauthorized` → `cerrarSesion()` | Ver 8.8, fila 9 |
| Limitador de login y métricas | Contadores | Memoria del proceso | Ventana de 60 s / el proceso | Vencimiento de ventana / reinicio | Ver 8.8, filas 8 y 12 |

**Política de invalidación declarada.** El servidor siempre responde desde la base (no hay copia que invalidar del lado servidor). Las copias del cliente se invalidan así: tras una **escritura propia**, con la respuesta del `PUT` (implementado); tras una **escritura ajena**, por acción explícita del usuario (implementado: deslizar para actualizar o *Reintentar*).

**Operación que hoy se rompe:** un estudiante tiene abierta su pantalla de inicio y un coordinador cambia un requisito. El estudiante ve el estado anterior hasta que desliza para actualizar o recarga la aplicación; no hay revalidación automática. Es una limitación conocida: los estudiantes no escriben y los cambios son poco frecuentes. **Plan:** revalidar al volver la aplicación a primer plano. No se hace con una recarga al cambiar de pestaña porque descartaría el estado de la búsqueda del coordinador.

**Cuándo se reabre esta decisión:** si una medición real muestra latencia de consulta relevante, si A-03 requiere un cálculo periódico costoso, o si se despliega más de una instancia. Diseño previsto en ese caso: *cache-aside* del resumen por estudiante (`resumen:{estudiante_id}`) en un almacén compartido, **invalidado explícitamente con `DELETE` desde `actualizar_estado_requisito` tras el `commit`**, con TTL corto (60 s) solo como red de seguridad, no como política. Se aceptaría la ventana entre el `commit` y el `DELETE`.

## 8.10 Eventos y mensajería

No existe flujo por eventos ni broker: la integración es síncrona ([ADR-0004](../adr/0004-comunicacion-sincrona-frontend-backend.md)) y el único trabajo periódico candidato (alertas, A-03) está pospuesto ([ADR-0010](../adr/0010-extraccion-de-modulo.md), 3.2; [ADR-0009](../adr/0009-no-incorporacion-componente-generativo.md)). Por eso no se declaran garantías de entrega. Si A-03 introduce mensajería, se partirá de **al menos una vez con consumidor idempotente**, en la línea del diseño actual (`PUT` de valor absoluto, historial solo si el valor cambia).

## 8.11 Decisión de datos más costosa de revertir

El mecanismo del historial de cambios, por ser el único cuyo pasado no se puede reconstruir: [ADR-0011](../adr/0011-historial-de-cambios-transaccional.md).
