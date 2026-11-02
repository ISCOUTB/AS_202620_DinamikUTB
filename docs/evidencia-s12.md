# Evidencia S12 · Estrategia de datos y eventos

- Repositorio: https://github.com/ISCOUTB/AS_202620_DinamikUTB
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
