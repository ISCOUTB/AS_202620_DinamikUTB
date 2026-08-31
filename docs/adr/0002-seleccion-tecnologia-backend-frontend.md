---
id: ADR-0002
title: Selección de tecnologías de backend y frontend
status: Aceptado
date: 2026-08-30
deciders: Equipo de arquitectura DinamikUTB
---
 
# ADR-0002: Selección de tecnologías de backend y frontend
 
![Status: Aceptado](https://img.shields.io/badge/Status-Accepted-brightgreen?style=flat-square)
![Date: 2026--08--30](https://img.shields.io/badge/Date-2026--08--30-blue?style=flat-square)
![Scope: Technology stack](https://img.shields.io/badge/Scope-Technology%20Stack-orange?style=flat-square)
 
---
 
## 1. Contexto y descripción del problema
 
El curso establece un conjunto cerrado de tecnologías permitidas para el desarrollo de **DinamikUTB**, según lo documentado en `docs/arc42/02-architecture-constraints.md`:
 
* **Backend:** NestJS o FastAPI.
* **Frontend:** Flutter o Next.js.
El ADR-0001 definió el **monolito modular** como estilo arquitectónico, pero no fijó la tecnología concreta con la que ese monolito se implementa.
 
Esta decisión es necesaria porque el equipo ya inició el desarrollo del backend y del frontend (ver estructura de carpetas en `README.md` y `start.bat`), por lo que la tecnología utilizada debe quedar formalmente registrada y justificada frente a las alternativas permitidas por el curso.
 
---
 
## 2. Factores de decisión
 
| Factor | Descripción |
| :--- | :--- |
| **Curva de aprendizaje** | El equipo debe poder avanzar con la tecnología dentro del tiempo disponible del semestre. |
| **Compatibilidad con el monolito modular** | La tecnología debe permitir organizar el código en módulos con límites claros (ver [ADR-0001](../adr/0001-seleccion-monolito-modular.md)). |
| **Soporte para los escenarios de calidad** | Debe facilitar cumplir [Q-01](../arc42/10-quality-requirements.md/#escenario-q-01--exactitud-de-la-informacion-academica) (exactitud), [Q-02](../arc42/10-quality-requirements.md/#escenario-q-02--seguridad-y-aislamiento-de-la-informacion) (seguridad) y [Q-03](../arc42/10-quality-requirements.md/#escenario-q-03--facilidad-de-comprension-de-la-informacion) (usabilidad), definidos en `docs/arc42/10-quality-requirements.md`. |
| **Multiplataforma** | El frontend debe poder ejecutarse al menos en navegador, dado que el flujo de inicio (`start.bat`) despliega la interfaz en Google Chrome. |
| **Tipado y validación de datos** | Relevante para [Q-01](../arc42/10-quality-requirements.md/#escenario-q-01--exactitud-de-la-informacion-academica), ya que reduce el riesgo de que datos inválidos lleguen a persistirse. |
| **Documentación automática de la API** | Facilita la integración entre backend y frontend y las pruebas manuales durante el desarrollo. |
 
---
 
## 3. Alternativas consideradas
 
### 3.1 Backend: NestJS vs. FastAPI
 
**NestJS**
 
* **Ventajas:** Estructura modular nativa basada en decoradores (`@Module`), fuertemente inspirada en patrones ya usados en frameworks empresariales; TypeScript de punta a punta si el frontend fuera Next.js.
* **Desventajas:** Mayor cantidad de configuración inicial (decoradores, inyección de dependencias, módulos) para el tamaño actual del proyecto; el equipo tiene menor experiencia previa con TypeScript en backend.
**FastAPI**
 
* **Ventajas:** Validación de datos declarativa mediante Pydantic, directamente alineada con la táctica de [Q-01](../arc42/10-quality-requirements.md/#escenario-q-01--exactitud-de-la-informacion-academica) de rechazar estados inválidos antes de persistirlos; generación automática de documentación interactiva (`/docs`); sintaxis más simple para un equipo con más experiencia en Python; buen soporte para dependencias inyectables (usado en la táctica de autenticación de [Q-02](../arc42/10-quality-requirements.md/#escenario-q-02--seguridad-y-aislamiento-de-la-informacion)).
* **Desventajas:** Su modularidad depende de la disciplina del equipo para organizar routers y servicios por carpeta, ya que no impone una estructura de módulos tan explícita como NestJS.
### 3.2 Frontend: Flutter vs. Next.js
 
**Next.js**
 
* **Ventajas:** Comparte el lenguaje (TypeScript/JavaScript) con un eventual backend en NestJS; buen soporte para renderizado web.
* **Desventajas:** Enfocado principalmente a web; extender a móvil implicaría herramientas adicionales fuera del alcance evaluado.
**Flutter**
 
* **Ventajas:** Un mismo código fuente permite ejecutar la aplicación en web y, a futuro, en dispositivos móviles, lo cual es relevante porque el estudiante es el usuario principal y podría necesitar consultar su progreso desde el celular; widgets con manejo explícito de estados de carga/error, alineados con la táctica de [Q-03](../arc42/10-quality-requirements.md/#escenario-q-03--facilidad-de-comprension-de-la-informacion) sobre mostrar el estado real de cada consulta.
* **Desventajas:** Lenguaje (Dart) distinto al del backend, lo que no permite compartir tipos o validaciones entre frontend y backend.
---
 
## 4. Decisión
 
Se selecciona:
 
* **Backend:** **FastAPI** (Python).
* **Frontend:** **Flutter**.
> **Justificación principal:** FastAPI facilita directamente las tácticas ya definidas para Q-01 y Q-02 en `docs/arc42/04-solution-strategy.md` (validación con Pydantic y autenticación como dependencia inyectable), mientras que Flutter permite que la interfaz prioritaria del estudiante —la pantalla de progreso, ligada a Q-03— pueda ejecutarse en distintas plataformas sin reescribir la aplicación.
 
Esta decisión no reemplaza al ADR-0001: el monolito modular sigue siendo el estilo arquitectónico, y FastAPI se organiza internamente respetando los módulos ya definidos (`usuarios/`, `estudiantes/`, `requisitos/`, `programas/`, `ayuda/`).
 
---
 
## 5. Consecuencias
 
### Consecuencias positivas
 
* **Validación centralizada:** Pydantic permite rechazar datos inválidos en la capa de esquemas, apoyando directamente la medida de Q-01.
* **Autenticación reutilizable:** El sistema de dependencias de FastAPI permite inyectar la autenticación una sola vez y reutilizarla en los routers de los distintos módulos, apoyando Q-02.
* **Documentación automática:** `/docs` facilita que el equipo y los evaluadores del curso verifiquen los endpoints sin herramientas adicionales.
* **Multiplataforma real:** Flutter permite que, si el proyecto continúa más allá del semestre, la misma base de código se extienda a móvil sin reescribir la interfaz.
### Consecuencias negativas
 
* **Dos lenguajes distintos:** Python en el backend y Dart en el frontend impiden compartir modelos o validaciones entre ambos lados; cualquier cambio en un esquema debe replicarse manualmente en el cliente Flutter.
* **Disciplina modular no impuesta por el framework:** A diferencia de NestJS, FastAPI no obliga estructuralmente a mantener los límites entre módulos; el equipo debe sostenerlos por convención, como ya se advierte en el ADR-0001.
* **Curva de aprendizaje de Flutter:** El equipo requiere familiarizarse con el manejo de estado en Flutter para implementar correctamente los tres estados (cargando, error, listo) que exige la táctica de Q-03.
---
 
## 6. Relación con atributos de calidad
 
| Atributo | Relación con la decisión |
| :--- | :--- |
| **Exactitud / Consistencia** | Pydantic (FastAPI) permite rechazar datos inválidos antes de persistirlos, apoyando directamente la medida de Q-01. |
| **Seguridad** | El sistema de dependencias de FastAPI centraliza la autenticación y autorización reutilizada entre módulos, apoyando Q-02. |
| **Usabilidad** | Flutter permite manejar explícitamente los estados de carga/error/listo en la pantalla de progreso, apoyando Q-03. |
| **Rendimiento** | FastAPI, al ser asíncrono por diseño, favorece tiempos de respuesta bajos en las consultas principales del sistema. |
| **Disponibilidad** | No incide de forma directa; depende principalmente del despliegue, ya cubierto por la decisión de monolito único en el ADR-0001. |
| **Trazabilidad** | No incide de forma directa; depende del diseño de historial de cambios, no de la tecnología elegida. |
| **Mantenibilidad** | La documentación automática de FastAPI y la organización por carpetas en Flutter (`frontend/lib/<módulo>/`) facilitan ubicar y modificar funcionalidades existentes. |
 
---
 
## 7. Relación con las restricciones del proyecto
 
Esta decisión satisface directamente las restricciones técnicas definidas en `docs/arc42/02-architecture-constraints.md`:
 
* Backend limitado a NestJS o FastAPI → se elige **FastAPI**.
* Frontend limitado a Flutter o Next.js → se elige **Flutter**.
No introduce ninguna tecnología fuera de las permitidas por el curso.
 
---
 
## 8. Estado de la decisión
 
**Aceptado.**
 
Esta decisión formaliza una tecnología que el equipo ya venía utilizando en el desarrollo (ver `README.md`). Cualquier cambio posterior de tecnología de backend o frontend deberá registrarse mediante un nuevo ADR.
 
