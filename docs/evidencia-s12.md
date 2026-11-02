
# Evidencia S12 · Estrategia de datos y eventos

- Repositorio: [https://github.com/ISCOUTB/AS_202620_DinamikUTB](https://github.com/ISCOUTB/AS_202620_DinamikUTB)
- Commit evaluado: `8dad793` · 2026-10-25T23:15:00-05:00
- Despliegue de referencia: Servidor del laboratorio vía Dokploy (ADR-0012)

## Dónde está cada entregable

| Criterio de la ficha | Dónde está |
|---|---|
| Tabla operación → garantía de consistencia | [arc42 §8.8](arc42/08-cross-cutting-concepts.md) (17 operaciones reales de la API y administración) |
| Dos operaciones verificadas contra el código | Detalladas abajo (operación fuerte y eventual) |
| Diseño de caché: qué, dónde, cuánto | [arc42 §8.9](arc42/08-cross-cutting-concepts.md): justificación de ausencia de caché en servidor e inventario de copias en el cliente |
| Política de invalidación tras escritura | [arc42 §8.9](arc42/08-cross-cutting-concepts.md): invalidación en cliente por reemplazo directo de modelo y por `ValueKey` reactiva |
| Garantías del flujo por eventos | [arc42 §8.10](arc42/08-cross-cutting-concepts.md): sin broker; efecto saliente SMTP como mejor esfuerzo / como máximo una vez |
| ADR de la decisión más costosa de revertir | [ADR-0011](adr/0011-historial-de-cambios-transaccional.md) (complementado por [ADR-0014](adr/0014-extension-historial-datos-estudiante.md)) |
| Argumento de por qué es la más costosa | ADR-0011, sección 2 (comparativa frente a 4 alternativas) y sección 6 |
| Almacenes y brokers en el C4 nivel 2 | [docs/c4/contenedores.puml](c4/contenedores.puml): bases PostgreSQL, SQLite, volumen Docker, almacén local y SMTP |
| arc42 sección 8 con consistencia y caché | [arc42 §8.8–8.11](arc42/08-cross-cutting-concepts.md) |
| Despliegue consolidado | [ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md) |

---

## Dos operaciones contrastadas con el código

### 1. Fuerte: `PUT /requisitos/{id}/estado` con su historial (filas 1 y 2)

```bash
git grep -nE "(db\.add\(|RequisitoHistorial\(|db\.commit\()" -- backend/app/requisitos/service.py
```

Resultado verificable en backend/app/requisitos/service.py:

- requisito = db.get(Requisito, requisito_id, with_for_update=True) serializa la fila.
- db.add(RequisitoHistorial(...)) prepara la auditoría en la misma sesión.
- # single transaction: UPDATE + history row, atomic acompaña al único db.commit().
- La prueba test_historial.py::test_si_falla_el_historial_el_cambio_no_queda_aplicado demuestra que si falla el historial, la transacción revierte y no se modifica el requisito.

### 2. Eventual / mejor esfuerzo: telemetría operativa y vista del estudiante (filas 3 y 6)

Bash
```
git grep -nE "(auditoria_cambio_estado|Future\.wait)" -- backend/app frontend/lib
```

- logger.info("auditoria_cambio_estado", ...) se emite intencionalmente tras el commit (telemetría volátil que no bloquea la consistencia de datos).
- dashboard_screen.dart ejecuta tres consultas en paralelo mediante Future.wait, aceptando desfases temporales que se reconcilian reactivamente por ValueKey o por recarga explícita.

---

## Credenciales y auditoría de seguridad

Bash
```
git grep -nIE '(AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY|ghp_[A-Za-z0-9]{36}|xox[baprs]-|sk-[A-Za-z0-9]{20,})' HEAD
```

Sin coincidencias de secretos reales en el repositorio.

> **Nota sobre el commit 4226597 (Create apply_s12.py):**\
> Al auditar el historial con git log -S "PRIVATE KEY", aparece este commit. Al examinar su contenido (git show 4226597), se constata que corresponde a la incorporación de un script auxiliar que contenía la expresión regular de búsqueda de claves para escaneo de seguridad, no a una clave privada ni a una credencial real filtrada.

---

## Despliegue en el laboratorio (Ambiente activo)

El despliegue en Render expiró y fue retirado. El sistema de referencia activo corre en el laboratorio bajo Dokploy ([**ADR-0012**](https://www.google.com/url?sa=E\&q=adr/0012-despliegue-en-servidor-del-laboratorio.md)):

| **Petición de comprobación** | **Resultado verificado** |
|---|---|
| GET [https://api.dinamikutb.iscoutb.dev/health](https://api.dinamikutb.iscoutb.dev/health) | **HTTP 200** ({"status":"ok"}) |
| GET [https://api.dinamikutb.iscoutb.dev/metrics](https://api.dinamikutb.iscoutb.dev/metrics) | **HTTP 200** (métricas de Prometheus) |
| GET [https://api.dinamikutb.iscoutb.dev/requisitos/T000123456](https://api.dinamikutb.iscoutb.dev/requisitos/T000123456) | **HTTP 401** (autenticación obligatoria) |
| GET [https://api.dinamikutb.iscoutb.dev/docs](https://api.dinamikutb.iscoutb.dev/docs) | **HTTP 404** (desactivado en producción) |

---

## Limitaciones declaradas

- Las pruebas de concurrencia sobre escrituras simultáneas son secuenciales en la suite de Pytest (SQLite local); la serialización en producción descansa en with_for_update=True soportado por PostgreSQL.
- El servidor SMTP opera bajo mejor esfuerzo: si el servidor de correo institucional se encuentra fuera de línea, la solicitud responde HTTP 503 sin cola de reintentos asíncrona.
- El volumen pgdata en el laboratorio persiste los datos entre reinicios del contenedor, pero aún requiere la configuración de una tarea cron periódica de respaldo (pg_dump).
