---
id: ADR-0006
title: Selección de plataforma de despliegue del frontend
status: Aceptado
date: 2026-09-26
deciders: Equipo de arquitectura DinamikUTB
---

# ADR-0006: Selección de plataforma de despliegue del frontend

![Status: Aceptado](https://img.shields.io/badge/Status-Accepted-brightgreen?style=flat-square)
![Date: 2026--09--26](https://img.shields.io/badge/Date-2026--09--26-blue?style=flat-square)
![Scope: Deployment](https://img.shields.io/badge/Scope-Deployment-orange?style=flat-square)

---

## 1. Contexto y descripción del problema

[ADR-0002](0002-seleccion-tecnologia-backend-frontend.md) seleccionó Flutter precisamente porque un mismo código fuente puede ejecutarse en web sin reescritura. Hasta ahora esa capacidad solo se ha usado para abrir la app en Chrome localmente (`start.bat`). Esta semana se requiere que el frontend también sea accesible desde fuera de la universidad, como una pieza separada de la decisión de dónde corre el backend (ver [ADR-0005](0005-plataforma-despliegue-backend.md)).

Al ser un build web de Flutter (`flutter build web`), el resultado es un conjunto de archivos estáticos (HTML/JS/CSS/assets) — no requiere un proceso de servidor propio, lo que abre opciones distintas a las del backend.

## 2. Factores de decisión

| Factor | Descripción |
| :--- | :--- |
| **Sin tarjeta de crédito** | Mismo límite que ADR-0005. |
| **Coherencia con las herramientas ya usadas** | El equipo ya usa GitHub Actions para CI; sumar la menor cantidad posible de cuentas/proveedores nuevos reduce la carga operativa dentro del semestre. |
| **Compatibilidad con contenido estático** | El build de Flutter web no necesita cómputo del lado del servidor, solo servir archivos. |
| **Disponibilidad constante** | A diferencia del backend, un sitio estático no tiene "spin down": debe estar siempre servido sin retrasos de arranque en frío. |

## 3. Alternativas consideradas

### 3.1 GitHub Pages

* **Ventajas:** No requiere una cuenta ni proveedor nuevo — usa el mismo repositorio y la misma autenticación de GitHub que ya usan para el código y el CI. Sin tarjeta, sin límite de expiración, siempre activo (no hay *spin down* en contenido estático).
* **Desventajas:** Sirve por defecto bajo una subruta (`usuario.github.io/repositorio/`), lo que exige compilar con `flutter build web --base-href /AS_202620_DinamikUTB/`. Una SPA como Flutter web necesita además un *fallback* a `index.html`, que en GitHub Pages se resuelve duplicando `index.html` como `404.html`.
* **Seleccionada.**

### 3.2 Netlify

* **Ventajas:** Deploy basado en Git, 100 GB de banda mensual incluidos, vistas previas automáticas por *pull request*, sin tarjeta de crédito requerida.
* **Desventajas:** Introduce una cuenta y un proveedor adicional que el equipo tendría que administrar por separado del flujo de GitHub ya establecido, sin un beneficio claro sobre GitHub Pages para un sitio puramente estático como este.

### 3.3 Vercel

* **Ventajas:** Deploy basado en Git, 100 GB de banda mensual, sin tarjeta de crédito.
* **Desventajas:** Está optimizado para frameworks como Next.js; para un build estático de Flutter no ofrece ninguna ventaja sobre GitHub Pages y, al igual que Netlify, suma un proveedor y una cuenta nuevos.

## 4. Decisión

Se selecciona la alternativa **3.1: GitHub Pages** para el despliegue del frontend.

> **Justificación principal:** el frontend es contenido puramente estático, por lo que no necesita las capacidades de cómputo de Netlify o Vercel. Usar GitHub Pages evita introducir una cuenta y un proveedor adicionales, reutilizando la misma plataforma donde ya vive el código y el pipeline de CI, sin costo y sin tarjeta de crédito.

Esta decisión no reemplaza a [ADR-0002](0002-seleccion-tecnologia-backend-frontend.md) (Flutter sigue siendo la tecnología del frontend); únicamente formaliza dónde se sirve el resultado de `flutter build web`.

## 5. Consecuencias

### Consecuencias positivas

* **Sin proveedor adicional:** un solo lugar (GitHub) concentra código, CI y hosting del frontend.
* **Siempre disponible:** al ser contenido estático, no hereda el *spin down* del backend descrito en [ADR-0005](0005-plataforma-despliegue-backend.md).
* **Deploy automatizado:** el workflow `.github/workflows/deploy-pages.yml` compila con `flutter build web` y publica en cada push a `master`. La URL del backend se inyecta con `--dart-define=API_BASE_URL`.

### Consecuencias negativas

* **Configuración de ruta base obligatoria:** olvidar `--base-href` rompe la carga de assets; está fijada en `deploy-pages.yml` y documentada en el README.
* **El frontend desplegado depende de la disponibilidad del backend** (ver [ADR-0005](0005-plataforma-despliegue-backend.md)): si el servicio de Render está en *spin down*, la primera consulta tardará ~1 minuto aunque el sitio estático cargue de inmediato. Debe comunicarse en la interfaz (estado "cargando", táctica de Q-03).
* **CORS:** el origen de GitHub Pages (`https://iscoutb.github.io`) se declara en la variable `CORS_ORIGINS` del backend (`render.yaml`), reemplazando el comodín `*` anterior.

## 6. Relación con atributos de calidad

| Atributo | Relación con la decisión |
| :--- | :--- |
| **Usabilidad** | Sostiene que la pantalla de progreso (Q-03) esté accesible sin fricción de infraestructura adicional. |
| **Disponibilidad** | El hosting estático no introduce su propio riesgo de caída, pero hereda el del backend (ADR-0005). |
| **Mantenibilidad** | Reduce la superficie operativa del equipo a un solo proveedor (GitHub) para código, CI y frontend. |

## 7. Relación con las restricciones del proyecto

Cumple la restricción de frontend en Flutter de [02-architecture-constraints.md](../arc42/02-architecture-constraints.md) y el límite de costo cero / sin tarjeta que también sustenta [ADR-0005](0005-plataforma-despliegue-backend.md).

## 8. Estado de la decisión

**Aceptado.** URL pública esperada: `https://iscoutb.github.io/AS_202620_DinamikUTB/` (confirmar tras el primer deploy).

## 9. Trazabilidad

| Elemento | Referencia |
| :--- | :--- |
| **Aspectos que sustenta** | [A-01](../aspectos.md#a-01--seguimiento-del-cumplimiento-de-requisitos) |
| **Escenario de calidad** | [Q-03](../arc42/10-quality-requirements.md#escenario-q-03--facilidad-de-comprensión-de-la-información) |
| **Elemento C4** | Contenedor `Frontend Flutter` en `docs/c4/contenedores.puml`, y su caja en [07-deployment-view.md](../arc42/07-deployment-view.md) |
| **Código** | `.github/workflows/deploy-pages.yml`, `frontend/lib/main.dart` (`API_BASE_URL`) |
| **Commits que lo implementan** | `<hash del commit que agrega deploy-pages.yml>` |
| **Pruebas que lo cubren** | `frontend/test/widget_test.dart`; verificación manual: la URL pública carga y consulta al backend desplegado (hora registrada en el README) |
