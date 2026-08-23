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

<details>
<summary><b>3.1 Layered Architecture (Arquitectura en Capas)</b> — <i>Descartada</i></summary>

Organiza el sistema en niveles de responsabilidad tradicionales (*Presentación*, *Aplicación*, *Dominio*, *Persistencia*).

* **Ventajas:** Estructura clásica, curva de aprendizaje nula, implementación rápida.
* **Desventajas:** Alto riesgo de acoplamiento vertical entre capas a medida que crece el dominio.
</details>

<details>
<summary><b>3.2 Hexagonal Architecture (Puertos y Adaptadores)</b> — <i>Descartada para la fase inicial</i></summary>

Aísla completamente la lógica de negocio de la infraestructura mediante interfaces abstradas.

* **Ventajas:** Alto desacoplamiento, excelente para pruebas avanzadas e independencia tecnológica.
* **Desventajas:** Añade complejidad estructural innecesaria (*boilerplate*) para el alcance actual.
</details>

### 3.3 Modular Monolith (Monolito Modular) — *Seleccionada*

Mantiene la aplicación en un **único artefacto desplegable**, pero impone límites estrictos (*encapsulamiento*) entre módulos funcionales.

> [!TIP]
> **¿Por qué destaca?** Proporciona la sencillez operativa de un monolito convencional con la disciplina de diseño de un sistema distribuido.

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
