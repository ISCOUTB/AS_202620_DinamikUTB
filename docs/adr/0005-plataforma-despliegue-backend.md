---
id: ADR-0005
title: Selección de plataforma de despliegue del backend
status: Aceptado
date: 2026-09-26
deciders: Equipo de arquitectura DinamikUTB
---

# ADR-0005: Selección de plataforma de despliegue del backend

![Status: Aceptado](https://img.shields.io/badge/Status-Accepted-brightgreen?style=flat-square)
![Date: 2026--09--26](https://img.shields.io/badge/Date-2026--09--26-blue?style=flat-square)
![Scope: Deployment](https://img.shields.io/badge/Scope-Deployment-orange?style=flat-square)

> **Nota (27/09/2026):** la decisión sobre **dónde y cómo persiste la base de datos** se separó de este ADR
> y quedó registrada en [ADR-0007](0007-persistencia-render-postgres.md), para tener un ADR por decisión de plataforma.
> Este ADR cubre únicamente dónde corre el proceso del backend.

---

## 1. Contexto y descripción del problema

Hasta ahora, DinamikUTB (backend FastAPI, ver [ADR-0002](0002-seleccion-tecnologia-backend-frontend.md)) solo se ha ejecutado localmente mediante `start.bat`. La ficha de esta semana exige que el sistema esté **desplegado y sea accesible desde fuera de la universidad**, con costo dentro del límite de un proyecto de semestre y sin requerir tarjeta de crédito del equipo.

## 2. Factores de decisión

| Factor | Descripción |
| :--- | :--- |
| **Sin tarjeta de crédito** | El equipo no cuenta con una tarjeta corporativa; la plataforma debe permitir un despliegue funcional sin solicitar datos de pago. |
| **Compatibilidad con lo ya decidido** | Evitar reabrir ADR-0002/ADR-0003 sin necesidad. |
| **Infraestructura como código** | El entorno debe poder describirse en un archivo versionado (`render.yaml`), no en pasos manuales. |
| **Simplicidad operativa** | El equipo tiene tiempo limitado dentro del semestre ([02-architecture-constraints.md](../arc42/02-architecture-constraints.md), sección 2.2); se prefiere *git push* a deploy sobre configuración manual de servidores. |
| **Disponibilidad** | [Q-05](../arc42/10-quality-requirements.md#escenario-q-05--disponibilidad-del-sistema) exige que el sistema responda sin interrupciones prolongadas. |

## 3. Alternativas consideradas

### 3.1 Servidor del laboratorio de la universidad

* **Ventajas:** Sin costo, sin tarjeta.
* **Desventajas:** Su alcance desde fuera de la red universitaria no está verificado, y confirmarlo depende de la coordinación de laboratorios, un tiempo que no está estimado antes del cierre del corte. Se desconoce si ofrece deploy automático desde Git salvo configuración manual adicional.
* **Descartada:** el equipo priorizó una alternativa que puede verificarse y desplegarse sin depender de un tercero.

### 3.2 Render — Free Web Service

* **Ventajas:** Deploy directo desde GitHub, sin tarjeta, HTTPS y variables de entorno incluidas, 750 horas de instancia gratis por mes, y describible como código mediante `render.yaml` (Blueprint).
* **Desventajas:** Tras 15 minutos sin tráfico el servicio entra en *spin down* y el primer request tarda cerca de un minuto. Su filesystem es efímero (por eso la persistencia se decide aparte en [ADR-0007](0007-persistencia-render-postgres.md)).
* **Seleccionada.**

### 3.3 Railway (Free)

* **Ventajas:** Deploy automático desde Git con detección de runtime, sin tarjeta para empezar.
* **Desventajas:** El plan gratuito da 5 USD de crédito el primer mes y luego solo 1 USD/mes; ese presupuesto no alcanza para mantener un servicio corriendo de forma continua.
* **Descartada.**

### 3.4 Fly.io

* **Ventajas:** Control fino de la ubicación de las máquinas, contenedores completos.
* **Desventajas:** Ya no ofrece plan gratuito para cuentas nuevas y exige tarjeta de crédito desde el registro.
* **Descartada de inmediato** por la restricción de "sin tarjeta".

## 4. Decisión

Se selecciona la alternativa **3.2: Render Free Web Service** para el backend, descrito en `render.yaml` y con `healthCheckPath: /health`.

> **Justificación principal:** es la alternativa que el equipo puede desplegar y verificar sin tarjeta de crédito, con infraestructura versionada, y sin depender de que la coordinación del laboratorio habilite acceso externo.

Esta decisión no reemplaza a [ADR-0001](0001-seleccion-monolito-modular.md) ni a [ADR-0002](0002-seleccion-tecnologia-backend-frontend.md).

## 5. Consecuencias

### Consecuencias positivas

* **Despliegue verificable sin fricción:** URL pública con HTTPS, sin tarjeta, desde el repositorio existente.
* **Entorno reproducible:** `render.yaml` describe el servicio, sus variables y su health check.

### Consecuencias negativas

* ***Spin down* de 15 minutos:** el primer request tras inactividad tarda ~1 min. Afecta la medida de Q-05 y debe comunicarse en cualquier demo o evidencia.
* **Un solo servicio gratuito:** 750 h/mes solo alcanzan para una instancia siempre activa (ver [costos](../costos.md)).
* **Seguridad:** el backend queda público sin autenticación (ver [11-risks-and-technical-debt.md](../arc42/11-risks-and-technical-debt.md)).

## 6. Relación con atributos de calidad

| Atributo | Relación con la decisión |
| :--- | :--- |
| **Disponibilidad** | El *spin down* es el principal riesgo sobre Q-05; se mide con `/health` y `/metrics`. |
| **Seguridad** | No se resuelve aquí: los endpoints siguen sin autenticación. Ver hallazgo en `11-risks-and-technical-debt.md`. |
| **Mantenibilidad** | Infraestructura como código en `render.yaml`. |

## 7. Relación con las restricciones del proyecto

Satisface el límite de costo cero / sin tarjeta de [02-architecture-constraints.md](../arc42/02-architecture-constraints.md) (sección 2.1).

## 8. Estado de la decisión

**Aceptado.** Quedan por completar tras el deploy real: la URL pública del backend y el commit de implementación (sección 9).

## 9. Trazabilidad

| Elemento | Referencia |
| :--- | :--- |
| **Aspectos que sustenta** | [A-01](../aspectos.md#a-01--seguimiento-del-cumplimiento-de-requisitos), [A-04](../aspectos.md#a-04--disponibilidad-del-sistema) |
| **Escenario de calidad** | [Q-05](../arc42/10-quality-requirements.md#escenario-q-05--disponibilidad-del-sistema) |
| **Elemento C4** | Contenedor `Backend API` en `docs/c4/contenedores.puml` y su caja en [07-deployment-view.md](../arc42/07-deployment-view.md) |
| **Código** | `render.yaml`, `backend/app/main.py` (`/health`, `/metrics`, logging JSON) |
| **Commits que lo implementan** | `898257c` |
| **Pruebas que lo cubren** | `backend/tests/test_health.py`; verificación manual: `curl <URL>/health` con hora registrada en el README |
