---
id: ADR-0001
title: Selección de Monolito Modular como Arquitectura Inicial
status: Accepted
date: 2026-08-23
deciders: Equipo de Arquitectura DinamikUTB
---

# ADR-0001: Selección de Monolito Modular como Arquitectura Inicial

![Status: Accepted](https://img.shields.io/badge/Status-Accepted-brightgreen?style=flat-square)
![Date: 2026--08--23](https://img.shields.io/badge/Date-2026--08--23-blue?style=flat-square)
![Scope: Core Architecture](https://img.shields.io/badge/Scope-Core%20Architecture-orange?style=flat-square)

---

## 1. Contexto y Descripción del Problema

**DinamikUTB** requiere una arquitectura que permita desarrollar inicialmente un sistema con un enfoque controlado y acotado, manteniendo una estructura clara y sencilla de implementar durante el proyecto.

El sistema gestionará información crítica sobre:
* **Estudiantes:** Perfil académico y avance.
* **Requisitos de Grado:** Validación de créditos y electivas.
* **Programas Académicos:** Mapeo de mallas curriculares.
* **Centro de Ayuda:** Soporte e iteración con el usuario.

Aunque la solución iniciará con un núcleo funcional simplificado, se proyecta su evolución para incorporar más módulos e integraciones con sistemas universitarios.

---

## 2. Decision Drivers

| Driver | Descripción |
| :--- | :--- |
| **Simplicidad inicial** | Evitar sobreingeniería y complejidad arquitectónica innecesaria. |
| **Organización** | Funcionalidades delimitadas mediante módulos independientes. |
| **Mantenibilidad** | Agilidad para aplicar modificaciones y correcciones. |
| **Evolución** | Escalabilidad limpia para nuevos programas y características. |
| **Testabilidad** | Facilidad para implementar pruebas unitarias y de integración. |
| **Integraciones futuras** | Preparado para consumir servicios externos a futuro. |

---

## 3. Alternativas Consideradas

### 3.1 Layered Architecture

La arquitectura en capas organiza el sistema en diferentes niveles de responsabilidad, como presentación, aplicación, lógica de negocio y persistencia.

* **Ventajas:** Estructura sencilla, ampliamente conocida y de rápida implementación inicial.
* **Desventajas:** Puede producir mayor acoplamiento entre las capas y dificultar la evolución a medida que aumenten las funcionalidades.

### 3.2 Hexagonal Architecture

La arquitectura hexagonal separa el núcleo de la aplicación de los elementos externos mediante puertos y adaptadores.

* **Ventajas:** Alto nivel de desacoplamiento, excelente testabilidad e independencia tecnológica.
* **Desventajas:** Introduce mayor complejidad estructural (*boilerplate*) que resulta innecesaria para el alcance inicial.

### 3.3 Modular Monolith

El monolito modular mantiene la aplicación como una única unidad desplegable, pero organiza internamente sus funcionalidades en módulos con responsabilidades claramente delimitadas.

* **Ventajas:** Mantiene un despliegue sencillo, separa las funcionalidades principales, permite la evolución progresiva y evita la sobreingeniería inicial.
* **Desventajas:** Los módulos forman parte de una misma aplicación y requiere rigor para mantener límites claros entre ellos.

> [!TIP]
> **¿Por qué destaca para nuestro proyecto?** Proporciona la sencillez operativa de un monolito convencional con la disciplina de diseño de un sistema distribuido.

---

## 4. Decisión

Se selecciona **Modular Monolith (Monolito Modular)** como la estrategia arquitectónica base para **DinamikUTB**.

> [!NOTE]
> **Estrategia Seleccionada:** Desarrollo de una única aplicación estructurada internamente en módulos independientes y débilmente acoplados.

Esta alternativa satisface el balance deseado:
1. **Desarrollo fluido:** Sin la sobrecarga de gestionar múltiples servicios o capas de abstracción complejas.
2. **Evolución progresiva:** Permite desacoplar módulos o migrarlos a Microservicios / Hexagonal solo cuando el dominio lo exija.

---

## 5. Consecuencias

### Consecuencias Positivas

* **Despliegue unificado:** Operaciones e infraestructura de bajo costo inicial.
* **Límites claros:** Aislamiento del código por contexto de negocio.
* **Evolución sin reescritura:** Crecimiento modular ordenado.

### Consecuencias Negativas

* **Punto único de fallo:** Un error crítico no capturado afecta a la aplicación completa.
* **Disciplina de equipo:** Requiere rigor para evitar dependencias cruzadas indebidas entre módulos.

---

## 6. Estructura Arquitectónica

```text
DinamikUTB
├── core/           # Configuración compartida y middleware
├── usuarios/       # Gestión de perfiles y autenticación
├── estudiantes/    # Historial y avance académico
├── requisitos/     # Motores de validación de grado
├── programas/      # Mallas curriculares y planes de estudio
└── ayuda/          # Módulo de soporte y FAQ

Esta estructura podrá modificarse durante el desarrollo si aparecen nuevas responsabilidades o se requiere dividir alguno de los módulos existentes.

Los límites entre módulos deberán mantenerse claros para evitar dependencias innecesarias.

---

## 7. Consideraciones Futuras

La selección del monolito modular no impide una evolución arquitectónica posterior. Si el crecimiento del sistema genera necesidades de mayor desacoplamiento, determinados módulos podrán incorporar principios de arquitectura hexagonal o evolucionar de forma independiente.

> **Principio adoptado:** Comenzar con una arquitectura modular y sencilla, aumentando el nivel de desacoplamiento únicamente cuando las necesidades reales del sistema lo justifiquen.

---

## 8. Relación con Atributos de Calidad

| Atributo | Relación con la Decisión |
| :--- | :--- |
| **Exactitud / Consistencia** | Los módulos permiten mantener responsabilidades claras sobre la información académica y su procesamiento. |
| **Seguridad** | La separación de responsabilidades facilita organizar autenticación, autorización y gestión de usuarios. |
| **Rendimiento** | Un único sistema evita la sobrecarga y latencia de comunicación entre múltiples servicios. |
| **Disponibilidad** | Un único despliegue simplifica la operación y administración del sistema. |
| **Trazabilidad** | La organización modular facilita identificar dónde se realizan determinadas operaciones. |
| **Mantenibilidad** | Los módulos permiten modificar funcionalidades sin mezclar responsabilidades de todo el sistema. |

---

## 9. Estado de la Decisión

**Aceptado.**

Esta decisión establece la arquitectura inicial del proyecto. Cualquier modificación significativa de la estrategia arquitectónica deberá registrarse mediante un nuevo ADR.
