# 5. Building Block View

Esta sección descompone **DinamikUTB** en sus bloques de construcción, siguiendo la decisión de **monolito modular** documentada en [ADR-0001](../adr/0001-seleccion-monolito-modular.md) y la estrategia de solución de `04-solution-strategy.md`. 

---

## 5.1 Whitebox Overall System — Nivel 1

**DinamikUTB** está compuesto por dos aplicaciones desplegables de forma independiente que se comunican mediante una API HTTP/JSON:

```text
┌─────────────────────────┐        HTTPS / JSON          ┌─────────────────────────┐
│                         │ ───────────────────────────▶ │                         │
│   Frontend (Flutter)    │                              │   Backend (FastAPI)      │
│                         │ ◀─────────────────────────── │   Monolito modular      │
└─────────────────────────┘                              └───────────┬─────────────┘
                                                                      │
                                                                      ▼
                                                          ┌─────────────────────────┐
                                                          │   Base de datos propia   │
                                                          │  (motor por definir)     │
                                                          └─────────────────────────┘
```

| Bloque | Responsabilidad | Tecnología |
|---|---|---|
| **Frontend** | Presentar la información al usuario según su rol y capturar sus interacciones (consultas, solicitudes al centro de ayuda). | Flutter |
| **Backend** | Concentrar la lógica de negocio: autenticación, cálculo de requisitos, gestión de programas y centro de ayuda. Expone la API que consume el frontend. | FastAPI (Python) |
| **Base de datos** | Persistir usuarios, estudiantes, requisitos, programas y solicitudes. | Por definir (ver `09-architecture-decisions.md`, decisión pendiente) |

El backend es, internamente, un **monolito modular**: se despliega como una sola aplicación, pero está dividido en módulos con responsabilidades delimitadas, descritos en el nivel 2.

---

## 5.2 Whitebox Backend — Nivel 2

```text
backend/app/
├── core/           # Configuración compartida, middleware, conexión a base de datos
├── usuarios/       # Autenticación, autorización, gestión de cuentas y roles
├── estudiantes/    # Perfil académico y datos de avance del estudiante
├── requisitos/     # Cálculo y consulta del estado de los requisitos de grado
├── programas/      # Programas académicos y mallas curriculares
└── ayuda/          # Centro de ayuda y gestión de solicitudes
```

| Módulo | Responsabilidad | Depende de | Escenario(s) de calidad que sustenta |
|---|---|---|---|
| **core** | Configuración compartida (settings, conexión a base de datos, middleware transversal). No contiene lógica de negocio. | `En desarrollo` | Base para [Q-01](./10-quality-requirements.md/#escenario-q-01--exactitud-de-la-informacion-academica) y [Q-02](./10-quality-requirements.md/#escenario-q-02--seguridad-y-aislamiento-de-la-informacion) |
| **usuarios** | Autenticar usuarios y resolver sus permisos como dependencia inyectable de FastAPI, reutilizada por el resto de los módulos. | `core` | [Q-02](./10-quality-requirements.md/#escenario-q-02--seguridad-y-aislamiento-de-la-informacion) |
| **estudiantes** | Mantener y exponer el perfil académico y el avance de cada estudiante. | `core`, `usuarios` | [Q-01](./10-quality-requirements.md/#escenario-q-01--exactitud-de-la-informacion-academica) |
| **requisitos** | Único lugar donde se calcula el estado de un requisito y el porcentaje de avance; valida los datos con Pydantic antes de persistirlos y agrupa actualizaciones múltiples en una transacción. | `core`, `usuarios`, `estudiantes`, `programas` | [Q-01](./10-quality-requirements.md/#escenario-q-01--exactitud-de-la-informacion-academica), [Q-02](./10-quality-requirements.md/#escenario-q-02--seguridad-y-aislamiento-de-la-informacion) |
| **programas** | Gestionar los programas académicos y los requisitos que cada uno exige, permitiendo incorporar nuevas carreras sin modificar `requisitos/`. | `core`, `usuarios` | Soporta la extensibilidad ([RF-06](./01-introduction-and-goals.md/#funcionalidades-principales) / [A-06](../aspectos.md/#a-06---extensibilidad-para-multiples-programas-academicos)) |
| **ayuda** | Registrar y gestionar las solicitudes que estudiantes envían por posibles inconsistencias, y su atención por coordinadores. | `core`, `usuarios`, `estudiantes` | [RF-07](./01-introduction-and-goals.md/#funcionalidades-principales) |


### Reglas de dependencia entre módulos

- `requisitos/`, `estudiantes/`, `programas/` y `ayuda/` dependen de `usuarios/` para resolver autenticación y rol, nunca al revés.
- `requisitos/` puede depender de `programas/` (para saber qué requisitos aplican a un programa) y de `estudiantes/` (para saber el avance registrado), pero `programas/` y `estudiantes/` no dependen de `requisitos/`.
- Ningún módulo accede directamente a las tablas de otro módulo; toda comunicación entre módulos ocurre a través de las funciones de servicio que cada módulo expone, para mantener el límite de módulo que exige el [ADR-0001](../adr/0001-seleccion-monolito-modular.md).


---

## 5.3 Whitebox Frontend — Nivel 2

El frontend replica la misma división por dominio que el backend, para que cada pantalla consuma únicamente el módulo de la API que le corresponde:

```text
frontend/lib/
├── core/           # Cliente HTTP, manejo de sesión, componentes compartidos
├── usuarios/       # Pantallas de autenticación y perfil de acceso
├── estudiantes/    # Pantalla principal de progreso académico
├── requisitos/     # Visualización de requisitos cumplidos/pendientes
├── programas/      # Consulta de programas y mallas (coordinador/administrador)
└── ayuda/          # Centro de ayuda y envío de solicitudes
```

| Módulo | Responsabilidad | Escenario de calidad que sustenta |
|---|---|---|
| **core** | Cliente HTTP hacia el backend, manejo de sesión/token, widgets compartidos. | [Q-02](./10-quality-requirements.md/#escenario-q-02--seguridad-y-aislamiento-de-la-informacion) (nunca expone datos sin sesión válida) |
| **usuarios** | Login y gestión de la sesión del usuario. | [Q-02](./10-quality-requirements.md/#escenario-q-02--seguridad-y-aislamiento-de-la-informacion) |
| **estudiantes** | Pantalla principal: primer contenido visible tras iniciar sesión. | [Q-03](./10-quality-requirements.md/#escenario-q-03--facilidad-de-comprension-de-la-informacion)|
| **requisitos** | Widgets que muestran el estado de cada requisito con estados explícitos (cargando, error, listo). | [Q-03](./10-quality-requirements.md/#escenario-q-03--facilidad-de-comprension-de-la-informacion) |
| **programas** | Consulta y gestión de programas académicos, visible solo para coordinador/administrador. | [RF-06](./01-introduction-and-goals.md/#funcionalidades-principales) |
| **ayuda** | Formulario de solicitudes y seguimiento de su estado. | [RF-07](./01-introduction-and-goals.md/#funcionalidades-principales) |

---

## 5.4 Relación con otras vistas

- La comunicación entre estos bloques durante los casos de uso principales se describe en `06-runtime-view.md`.
- Las decisiones que originaron esta estructura están registradas en `09-architecture-decisions.md` y en [ADR-0001](../adr/0001-seleccion-monolito-modular.md).
- La justificación de por qué se eligió esta división modular frente a capas u hexagonal está en `04-solution-strategy.md`.
