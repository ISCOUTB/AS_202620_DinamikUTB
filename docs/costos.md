# Estimación de costo mensual 

Método: se parte del volumen de nuestros escenarios de calidad.

## 1. Volumen supuesto

| Supuesto | Valor | Origen |
|---|---|---|
| Carga de prueba de disponibilidad | 100 solicitudes concurrentes durante 10 min | Q-05 |
| Peor caso de la prueba | 100 usuarios × 1 petición cada 10 s × 600 s = **6 000 peticiones** | derivado |
| Tamaño medio de respuesta de la API | ~1 KB → **~6 MB** en la prueba | supuesto |
| Peso del build web de Flutter | ~3 MB por carga completa | supuesto |
| Piloto real | 500 estudiantes × 4 visitas/mes = **2 000 cargas/mes** → ~6 GB | supuesto |
| Filas en la base | 500 estudiantes × 8 requisitos = 4 000 filas (< 1 MB) | supuesto |

## 2. Costo por pieza

| Pieza | Plataforma | Costo con el volumen supuesto | Límite gratuito | Punto de ruptura |
|---|---|---|---|---|
| Frontend estático | GitHub Pages | $0 | ~100 GB/mes de banda y 1 GB de sitio | ~33 000 cargas/mes (100 GB ÷ 3 MB); estamos en 2 000 |
| Backend | Render Free Web Service | $0 | 750 h/mes de instancia | Un mes de 744 h ya consume casi todo: **solo cabe un servicio**. Un segundo servicio o el modo siempre encendido exige plan de pago (~USD 7/mes, confirmar) |
| Base de datos | Render Postgres Free | $0 | 1 GB, **expira a los 30 días** (+14 de gracia) | No se rompe por tamaño (< 1 MB de 1 GB), sino por **tiempo**: recrear y resembrar antes del día 25 o pasar a plan de pago (~USD 6/mes, confirmar) |
| CI/CD | GitHub Actions | $0 | repositorio público | Sin límite práctico para nuestro uso |
| Análisis estático | SonarCloud | $0 | proyectos públicos | Pasaría a pago si el repo se vuelve privado |
| Tarjeta de crédito | — | No requerida | — | — |

## 3. Total mensual

- **Hoy (capa gratuita): USD 0/mes.**
- **Si se quisiera eliminar el spin down y el vencimiento de la base:** web de pago + Postgres de pago ≈ **USD 13/mes** (referencia, confirmar).

## 4. Qué se rompe y cuándo

1. Al día 30 de creada la base (mitigación: recreación y resiembra antes del día 25, ver `arc42/11`).
2. Tras 15 min sin tráfico: el primer request tarda ~1 min (spin down). Aceptado en Q-05.
3. Al superar ~33 000 cargas/mes del frontend, o si se añade un segundo servicio al backend.
