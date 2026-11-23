# Estimación de costo mensual

Método: se parte del volumen de nuestros escenarios de calidad.

> **Topología vigente:** frontend en GitHub Pages y backend + PostgreSQL 16 en el
> servidor del laboratorio (Dokploy + Traefik), según
> [ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md). La capa gratuita
> de Render se conserva más abajo como registro histórico del ambiente
> experimental retirado el 25/10/2026.

## 1. Volumen supuesto

| Supuesto | Valor | Origen |
|---|---|---|
| Carga de prueba de disponibilidad | 100 solicitudes concurrentes durante 10 min | Q-05 |
| Peor caso de la prueba | 100 usuarios × 1 petición cada 10 s × 600 s = **6 000 peticiones** | derivado |
| Tamaño medio de respuesta de la API | ~1 KB → **~6 MB** en la prueba | supuesto |
| Peso del build web de Flutter | ~3 MB por carga completa | supuesto |
| Piloto real | 500 estudiantes × 4 visitas/mes = **2 000 cargas/mes** → ~6 GB | supuesto |
| Filas en la base | 500 estudiantes × 8 requisitos = 4 000 filas (< 1 MB) | supuesto |

## 2. Costo por pieza (topología vigente)

| Pieza | Plataforma | Costo con el volumen supuesto | Límite | Punto de ruptura |
|---|---|---|---|---|
| Frontend estático | GitHub Pages | $0 | ~100 GB/mes de banda y 1 GB de sitio | ~33 000 cargas/mes (100 GB ÷ 3 MB); estamos en 2 000 |
| Backend | FastAPI en Docker sobre Dokploy (laboratorio) | $0 para el equipo | 0,5 CPU y 192 MB (ADR-0012) | Un segundo servicio o más tráfico exige más cuota del laboratorio |
| Base de datos | PostgreSQL 16 en Docker, volumen `pgdata` | $0 para el equipo | 0,5 CPU y 160 MB; `max_connections=30` | No expira por tiempo; el riesgo es la **falta de respaldo** del volumen |
| CI/CD | GitHub Actions | $0 | repositorio público | Sin límite práctico para nuestro uso |
| Análisis estático | SonarCloud | $0 | proyectos públicos | Pasaría a pago si el repo se vuelve privado |
| Tarjeta de crédito | — | No requerida | — | — |

### Registro histórico: capa gratuita de Render (retirada)

| Pieza | Plataforma | Costo | Límite que se rompió |
|---|---|---|---|
| Backend | Render Free Web Service | $0 | 750 h/mes: un mes de 744 h casi agota la instancia; con *spin down* el primer request tardaba ~1 min |
| Base de datos | Render Postgres Free | $0 | 1 GB, pero expira a los 30 días (+14 de gracia); expiró el 27/10/2026 |

## 3. Total mensual

- **Hoy (topología vigente): USD 0/mes para el equipo.** El costo real es el
  consumo del servidor del laboratorio, sin facturación directa.
- **Si se migrara a un proveedor pagado:** referencia ≈ **USD 13/mes**
  (web + Postgres administrado), pendiente de confirmar contra tarifas vigentes.

## 4. Qué se rompe y cuándo (topología vigente)

1. Si el laboratorio deja de ser accesible desde fuera de la universidad: el API
   deja de estar disponible aunque GitHub Pages siga sirviendo la SPA
   ([ADR-0012](adr/0012-despliegue-en-servidor-del-laboratorio.md) §5).
2. Si se pierde el volumen `pgdata`: no hay `pg_dump` programado, por lo que se
   perdería el historial. Deuda registrada en
   [arc42 §11.3](arc42/11-risks-and-technical-debt.md).
3. Al superar ~33 000 cargas/mes del frontend o la cuota de CPU/memoria del
   laboratorio.
