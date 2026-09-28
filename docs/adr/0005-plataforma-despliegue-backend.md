---
id: ADR-0005
title: Selección de plataforma de despliegue del backend y estrategia de persistencia
status: Aceptado
date: 2026-09-26
deciders: Equipo de arquitectura DinamikUTB
---

# ADR-0005: Selección de plataforma de despliegue del backend y estrategia de persistencia

![Status: Aceptado](https://img.shields.io/badge/Status-Accepted-brightgreen?style=flat-square)
![Date: 2026--09--26](https://img.shields.io/badge/Date-2026--09--26-blue?style=flat-square)
![Scope: Deployment](https://img.shields.io/badge/Scope-Deployment-orange?style=flat-square)

---

## 1. Contexto y descripción del problema

Hasta ahora, DinamikUTB (backend FastAPI + SQLite, ver [ADR-0002](0002-seleccion-tecnologia-backend-frontend.md) y [ADR-0003](0003-seleccion-motor-de-base-de-datos.md)) solo se ha ejecutado localmente mediante `start.bat`. La ficha de esta semana exige que el sistema esté **desplegado y sea accesible desde fuera de la universidad**, con costo dentro del límite de un proyecto de semestre y sin requerir tarjeta de crédito del equipo.

Esta decisión resuelve dos preguntas relacionadas pero distintas:

1. **Dónde corre el proceso del backend** (FastAPI).
2. **Dónde y cómo persiste la base de datos**, porque no todas las plataformas gratuitas preservan un archivo SQLite entre despliegues.

## 2. Factores de decisión

| Factor | Descripción |
| :--- | :--- |
| **Sin tarjeta de crédito** | El equipo no cuenta con una tarjeta corporativa; la plataforma debe permitir un despliegue funcional sin solicitar datos de pago. |
| **Persistencia real de los datos** | La medida de [Q-01](../arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica) exige que la información mostrada corresponda con lo registrado; una base que se reinicia sola viola esa medida en la práctica, aunque el cálculo del servicio sea correcto. |
| **Compatibilidad con lo ya decidido** | Evitar reabrir ADR-0002/ADR-0003 sin necesidad. |
| **Simplicidad operativa** | El equipo tiene tiempo limitado dentro del semestre ([02-architecture-constraints.md](../arc42/02-architecture-constraints.md), sección 2.2); se prefiere *git push* a deploy sobre configuración manual de servidores. |
| **Disponibilidad** | [Q-05](../arc42/10-quality-requirements.md#escenario-q-05--disponibilidad-del-sistema) exige que el sistema responda sin interrupciones prolongadas. |

## 3. Alternativas consideradas

### 3.1 Servidor del laboratorio de la universidad

* **Ventajas:** Mantiene SQLite exactamente como lo fijó ADR-0003, sin migrar nada. Sin costo, sin tarjeta.
* **Desventajas:** Su alcance desde fuera de la red universitaria no está verificado, y confirmarlo depende de la coordinación de laboratorios, un tiempo que no está estimado para su disponibilidad antes del cierre del corte. Se desconoce si ofrece deploy automático desde Git salvo configuración manual adicional.
* **Descartada** por esta razón: el equipo ha priorizado una alternativa que puede verificarse y desplegarse sin depender de un tercero fuera del proyecto.

### 3.2 Render — Free Web Service, manteniendo SQLite tal cual

* **Ventajas:** Deploy directo desde GitHub, sin tarjeta, HTTPS y variables de entorno incluidas, 750 horas de instancia gratis por mes.
* **Desventajas:** Los servicios gratuitos de Render tienen **filesystem efímero**: cualquier archivo escrito localmente —incluido un `.db` de SQLite— se pierde en cada redeploy, reinicio o *spin down* por inactividad (15 minutos sin tráfico). Esto viola directamente la medida de Q-01 apenas el servicio se reinicie, sin que el código tenga ningún error.
* **Descartada** por esta razón: implica desplegar un sistema que se sabe de antemano que pierde datos.

### 3.3 Render — Free Web Service + Render Postgres (Free)

* **Ventajas:** Mismo deploy sencillo sin tarjeta. La base de datos gestionada por Render sí persiste mientras el plan gratuito esté activo. ADR-0003 ya anticipó esta ruta de evolución: *"al acceder a través de SQLAlchemy, una futura migración a un motor con mayor concurrencia (como PostgreSQL) no debería requerir cambios en la lógica de los módulos"*.
* **Desventajas:** El Postgres gratuito de Render tiene almacenamiento fijo de 1 GB y **expira 30 días después de su creación**, con 14 días de gracia para migrarlo antes de que se elimine junto con sus datos. Además, el web service gratuito entra en *spin down* tras 15 minutos sin tráfico y tarda cerca de un minuto en volver a responder al primer request.
* **Seleccionada.**

### 3.4 Railway (Free)

* **Ventajas:** Deploy automático desde Git con detección de runtime, sin tarjeta para empezar.
* **Desventajas:** El plan gratuito da 5 USD de crédito el primer mes y luego solo 1 USD/mes; ese presupuesto no alcanza para mantener un servicio corriendo de forma continua. No es viable para un sistema que debe estar accesible durante todo el corte.

### 3.5 Fly.io

* **Ventajas:** Control fino de la ubicación de las máquinas, contenedores completos.
* **Desventajas:** Fly.io **ya no ofrece plan gratuito para cuentas nuevas** y exige tarjeta de crédito desde el registro. Descartada de inmediato por la restricción de "sin tarjeta".

## 4. Decisión

Se selecciona la alternativa **3.3: Render Free Web Service para el backend, con persistencia en Render Postgres (Free)**.

> **Justificación principal:** es la alternativa que el equipo puede desplegar y verificar sin tarjeta de crédito y sin depender de que la coordinación del laboratorio habilite acceso externo. La migración a Postgres es de bajo riesgo porque ADR-0003 ya la dejó prevista al elegir SQLAlchemy como capa de acceso a datos.

Esta decisión no reemplaza a [ADR-0001](0001-seleccion-monolito-modular.md) ni a [ADR-0002](0002-seleccion-tecnologia-backend-frontend.md); ajusta la consecuencia operativa de [ADR-0003](0003-seleccion-motor-de-base-de-datos.md) únicamente para el ambiente desplegado — el desarrollo local sigue usando SQLite sin cambios.

## 5. Consecuencias

### Consecuencias positivas

* **Despliegue verificable sin fricción:** URL pública con HTTPS, sin tarjeta, desde el repositorio existente.
* **Camino de evolución ya anticipado:** la migración a Postgres usa la misma capa SQLAlchemy que ya aísla al resto de los módulos del motor específico ([ADR-0003](0003-seleccion-motor-de-base-de-datos.md)).

### Consecuencias negativas

* **Expiración de la base de datos cada 30 días:** requiere un procedimiento recurrente de recreación y resiembra (`python -m app.seed` o equivalente) antes de que expire, o una migración a un plan pago si el proyecto continúa más allá del semestre. Registrado en [11-risks-and-technical-debt.md](../arc42/11-risks-and-technical-debt.md).
* ***Spin down* de 15 minutos:** el primer request tras inactividad tarda ~1 minuto en responder. Afecta la medida de Q-05 y debe comunicarse explícitamente en cualquier demo o evidencia.
* **Diferencia entre ambientes:** el ambiente desplegado ya no es 100 % SQLite, aunque el desarrollo local sí lo siga siendo — documentado en [07-deployment-view.md](../arc42/07-deployment-view.md).

## 6. Relación con atributos de calidad

| Atributo | Relación con la decisión |
| :--- | :--- |
| **Exactitud / Consistencia** | Resolver la persistencia real era condición previa para que Q-01 tuviera sentido en un ambiente desplegado; SQLite tal cual en Render la habría violado por diseño. |
| **Disponibilidad** | El *spin down* de Render es el principal riesgo introducido sobre Q-05; documentado como consecuencia negativa y como ítem del registro de riesgos. |
| **Seguridad** | No se resuelve en esta decisión: el endpoint `GET /requisitos/{estudiante_id}` sigue sin autenticación (ver `06-runtime-view.md`), por lo que desplegarlo públicamente expone datos académicos sin control de acceso. Ver el hallazgo correspondiente en [11-risks-and-technical-debt.md](../arc42/11-risks-and-technical-debt.md). |
| **Mantenibilidad** | El acceso a través de SQLAlchemy mantiene la migración de motor aislada de la lógica de negocio, como ya lo documentaba ADR-0003. |

## 7. Relación con las restricciones del proyecto

Satisface la restricción de "base de datos propia" de [02-architecture-constraints.md](../arc42/02-architecture-constraints.md) (sección 2.1) y el límite de costo cero / sin tarjeta documentado en esa misma sección, verificado por esta decisión.

## 8. Estado de la decisión

**Aceptado.** El equipo se encargó de revisar las alternativas y confirmar la selección de Render (Free Web Service + Postgres Free) sobre el servidor del laboratorio, priorizando una opción verificable dentro del tiempo disponible del corte.

Quedan en estado pendientes de completar, en cuanto el equipo ejecute el deploy real:

- URL pública del backend.
- Fecha exacta de creación de la base en Render Postgres (para calcular el día de expiración, ver [11-risks-and-technical-debt.md](../arc42/11-risks-and-technical-debt.md)).
- Commit y prueba de humo correspondientes en la sección 9 de este documento.

## 9. Trazabilidad

| Elemento | Referencia |
| :--- | :--- |
| **Aspectos que sustenta** | [A-01](../aspectos.md#a-01--seguimiento-del-cumplimiento-de-requisitos), [A-04](../aspectos.md#a-04--disponibilidad-del-sistema) |
| **Escenarios de calidad** | [Q-01](../arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica) (principal), [Q-05](../arc42/10-quality-requirements.md#escenario-q-05--disponibilidad-del-sistema) |
| **Elemento C4** | Contenedores `Backend API` y `Base de datos` en `docs/c4/contenedores.puml`, y la caja correspondiente en [07-deployment-view.md](../arc42/07-deployment-view.md) |
| **Commits que lo implementan** | `<pendiente>` — agregar el commit que introduce la configuración de Render y la migración a Postgres |
| **Pruebas que lo cubren** | `<pendiente>` — agregar una prueba de humo (*smoke test*) que verifique `GET /health` sobre la URL pública desplegada |
