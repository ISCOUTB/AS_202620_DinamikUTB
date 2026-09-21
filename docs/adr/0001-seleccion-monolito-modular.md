---
id: ADR-0001
title: Selección de monolito modular como modelo arquitectónico
status: Aceptado
date: 2026-08-23
deciders: Equipo de arquitectura DinamikUTB
---

# ADR-0001: Selección de monolito modular como modelo arquitectónico

![Status: Aceptado](https://img.shields.io/badge/Status-Accepted-brightgreen?style=flat-square)
![Date: 2026--08--23](https://img.shields.io/badge/Date-2026--08--23-blue?style=flat-square)
![Scope: Core architecture](https://img.shields.io/badge/Scope-Core%20Architecture-orange?style=flat-square)

---

## 1. Contexto y descripción del problema

**DinamikUTB** requiere una arquitectura que permita desarrollar inicialmente un sistema con un enfoque controlado y acotado, manteniendo una estructura clara y sencilla de implementar durante el proyecto.

El sistema gestionará información crítica sobre:
* **Estudiantes:** Perfil académico y avance.
* **Requisitos de grado:** Validación de créditos y electivas.
* **Programas académicos:** Mapeo de mallas curriculares.
* **Centro de ayuda:** Soporte e iteración con el usuario.

Aunque la solución iniciará con un núcleo funcional simplificado, se proyecta su evolución para incorporar más módulos e integraciones con sistemas universitarios.

---

## 2. Factores de decisión

| Factor | Descripción |
| :--- | :--- |
| **Simplicidad inicial** | Evitar sobreingeniería y complejidad arquitectónica innecesaria. |
| **Organización** | Funcionalidades delimitadas mediante módulos independientes. |
| **Mantenibilidad** | Agilidad para aplicar modificaciones y correcciones. |
| **Evolución** | Escalabilidad limpia para nuevos programas y características. |
| **Testabilidad** | Facilidad para implementar pruebas unitarias y de integración. |
| **Integraciones futuras** | Preparado para consumir servicios externos a futuro. |

---

## 3. Alternativas consideradas

### 3.1 Arquitectura en capas

La arquitectura en capas organiza el sistema en diferentes niveles de responsabilidad, como presentación, aplicación, lógica de negocio y persistencia.

* **Ventajas:** Estructura sencilla, ampliamente conocida y de rápida implementación inicial.
* **Desventajas:** Puede producir mayor acoplamiento entre las capas y dificultar la evolución a medida que aumenten las funcionalidades.

### 3.2 Arquitectura hexagonal

La arquitectura hexagonal separa el núcleo de la aplicación de los elementos externos mediante puertos y adaptadores.

* **Ventajas:** Alto nivel de desacoplamiento, excelente testabilidad e independencia tecnológica.
* **Desventajas:** Introduce mayor complejidad estructural (*boilerplate*) que resulta innecesaria para el alcance inicial.

### 3.3 Arquitectura monolítico modular

El monolito modular mantiene la aplicación como una única unidad desplegable, pero organiza internamente sus funcionalidades en módulos con responsabilidades claramente delimitadas.

* **Ventajas:** Mantiene un despliegue sencillo, separa las funcionalidades principales, permite la evolución progresiva y evita la sobreingeniería inicial.
* **Desventajas:** Los módulos forman parte de una misma aplicación y requiere rigor para mantener límites claros entre ellos.

> [!Note]
> **¿Por qué destaca para nuestro proyecto?** Proporciona la sencillez operativa de un monolito convencional, manteniendo una organización modular que facilita el crecimiento y el desacoplamiento progresivo.

---

## 4. Decisión

Se selecciona **modular monolith (monolito modular)** como la estrategia arquitectónica base para **DinamikUTB**.

> **Estrategia seleccionada:** Desarrollo de una única aplicación estructurada internamente en módulos independientes y débilmente acoplados.

Esta alternativa satisface el balance deseado:
1. **Desarrollo fluido:** Sin la sobrecarga de gestionar múltiples servicios o capas de abstracción complejas.
2. **Evolución progresiva:** Permite desacoplar módulos o migrarlos a Hexagonal solo cuando el dominio lo exija.

---

## 5. Consecuencias

### Consecuencias positivas

* **Despliegue unificado:** Operaciones e infraestructura de bajo costo inicial.
* **Límites claros:** Aislamiento del código por contexto de negocio.
* **Evolución sin reescritura:** Crecimiento modular ordenado.

### Consecuencias negativas

* **Punto único de fallo:** Un error crítico no capturado afecta a la aplicación completa.
* **Disciplina de equipo:** Requiere rigor para evitar dependencias cruzadas indebidas entre módulos.

---

## 6. Estructura arquitectónica

```text
DinamikUTB
├── core/           # Configuración compartida y middleware
├── usuarios/       # Gestión de perfiles y autenticación
├── estudiantes/    # Historial y avance académico
├── requisitos/     # Motores de validación de grado
├── programas/      # Mallas curriculares y planes de estudio
└── ayuda/          # Módulo de soporte y FAQ

```
Esta estructura podrá modificarse durante el desarrollo si aparecen nuevas responsabilidades o se requiere dividir alguno de los módulos existentes.

Los límites entre módulos deberán mantenerse claros para evitar dependencias innecesarias.

---

## 7. Consideraciones futuras

La selección del monolito modular no impide una evolución arquitectónica posterior. Si el crecimiento del sistema genera necesidades de mayor desacoplamiento, determinados módulos podrán incorporar principios de arquitectura hexagonal o evolucionar de forma independiente.

> **Principio adoptado:** Comenzar con una arquitectura modular y sencilla, aumentando el nivel de desacoplamiento únicamente cuando las necesidades reales del sistema lo justifiquen.

---

## 8. Relación con atributos de calidad

| Atributo | Relación con la decisión |
| :--- | :--- |
| **Exactitud / Consistencia** | Los módulos permiten mantener responsabilidades claras sobre la información académica y su procesamiento. |
| **Seguridad** | La separación de responsabilidades facilita organizar autenticación, autorización y gestión de usuarios. |
| **Rendimiento** | Un único sistema evita la sobrecarga y latencia de comunicación entre múltiples servicios. |
| **Disponibilidad** | Un único despliegue simplifica la operación y administración del sistema. |
| **Trazabilidad** | La organización modular facilita identificar dónde se realizan determinadas operaciones. |
| **Mantenibilidad** | Los módulos permiten modificar funcionalidades sin mezclar responsabilidades de todo el sistema. |

---

## 9. Estado de la decisión

**Aceptado.**

Esta decisión establece la arquitectura inicial del proyecto. Cualquier modificación significativa de la estrategia arquitectónica deberá registrarse mediante un nuevo ADR.

---

## 10. Trazabilidad

| Elemento | Referencia |
| :--- | :--- |
| **Aspecto que sustenta** | [A-01](../aspectos.md#a-01--seguimiento-del-cumplimiento-de-requisitos) — Seguimiento del cumplimiento de requisitos |
| **Elemento C4** | Contenedores `Backend API` y `Base de datos` en `docs/c4/contenedores.puml` |
| **Commits que lo implementan** | `308ec02` a `d951eb8`, creación incremental de `backend/app/requisitos/` (modelo, esquema, servicio, router) sobre la estructura modular definida por esta decisión |
| **Pruebas que lo cubren** | `backend/tests/test_requisitos.py` (2 casos: consulta con datos, consulta sin datos) |
