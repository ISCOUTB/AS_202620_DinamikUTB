# DinamikUTB

> Sistema digital para el seguimiento de requisitos necesarios para la graduación universitaria.

---

## Índice

- [Descripción](#descripción)
- [Contexto](#contexto)
- [Problema](#problema)
- [Objetivos](#objetivos)
- [Usuarios](#usuarios)
- [Solución Propuesta](#solución-propuesta)
- [Funcionalidades](#funcionalidades)
- [Atributos de calidad](#atributos-de-calidad)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Ejecución del Proyecto](#ejecución-del-proyecto)
- [Equipo](#equipo)


---

# Descripción

**DinamikUTB** es una plataforma diseñada para facilitar a los estudiantes el seguimiento de los diferentes requisitos necesarios para completar satisfactoriamente su proceso de graduación.

La solución busca centralizar información que actualmente puede encontrarse distribuida entre reglamentos académicos, plataformas institucionales y otras fuentes de consulta.

El sistema permitirá que el estudiante pueda conocer de manera clara:

- Qué requisitos ya ha completado.
- Qué requisitos tiene pendientes.
- Cuáles se encuentran en proceso.
- Qué requisitos requieren atención.
- Qué tan cerca se encuentra de completar su proceso de graduación.

Además, la plataforma podrá generar alertas tempranas cuando identifique requisitos importantes que aún no hayan sido completados.

---

# Contexto

En la Universidad Tecnológica de Bolívar, los estudiantes deben cumplir diferentes condiciones académicas y administrativas, entre ellas:

- Créditos académicos.
- Nivel de idioma extranjero.
- Prácticas o pasantías.
- Opción de grado.
- Electivas específicas.
- Otros requisitos establecidos por el programa académico.


---

# Problema

Los estudiantes no cuentan con una herramienta centralizada que les permita conocer en cualquier momento cuáles requisitos de grado han cumplido y cuáles todavía tienen pendientes.

Como consecuencia, un estudiante podría tener que cursar semestres adicionales para completar un requisito que pudo haber sido planificado con anterioridad.

Esto puede representar:

- Mayor tiempo para obtener el título.
- Costos adicionales de matrícula.
- Retraso en el inicio de la vida laboral.
- Dificultades para planificar la carga académica.
- Frustración por falta de información oportuna.

---

# Objetivos

## Objetivo General

Desarrollar una plataforma digital que permita a los estudiantes consultar y realizar seguimiento al cumplimiento de los requisitos necesarios para su graduación.

## Objetivos Específicos

- Centralizar la información relacionada con los requisitos de grado.
- Mostrar el estado actual de cada requisito.
- Permitir consultar el progreso hacia la graduación.
- Identificar requisitos pendientes.
- Generar alertas tempranas sobre requisitos críticos.
- Facilitar la planificación académica del estudiante mediante una visualización dinámica.
- Permitir una futura ampliación hacia diferentes programas académicos.

---

# Usuarios

El sistema estará orientado principalmente a:

### Estudiantes

Serán los usuarios principales de la plataforma.

Podrán consultar su progreso académico y conocer los requisitos que todavía necesitan cumplir.

### Coordinaciones Académicas

Podrán beneficiarse indirectamente de la reducción de consultas repetitivas relacionadas con requisitos de graduación.

### Administradores

En futuras versiones podrán encargarse de gestionar los requisitos correspondientes a cada programa académico.

---

# Solución Propuesta

**DinamikUTB** proporcionará una vista centralizada del proceso de graduación del estudiante.

El sistema analizará los requisitos establecidos para el programa académico y permitirá determinar cuáles han sido cumplidos y cuáles permanecen pendientes.

La plataforma también podrá generar alertas cuando detecte que un requisito importante aún no ha sido completado y el estudiante se encuentre cerca de finalizar su programa académico.

---

# Funcionalidades

## Seguimiento de requisitos

El estudiante podrá consultar el estado de cada requisito necesario para graduarse.

--- 
# Atributos de calidad
 
##  Disponibilidad vs. Consistencia

**DinamikUTB** debe mantener un equilibrio entre la disponibilidad del sistema y la consistencia de la información.

- **Disponibilidad:** El sistema debe permanecer accesible incluso ante fallas parciales o alta demanda.
- **Consistencia:** La información sobre los requisitos de grado debe ser correcta y coherente.
- **Prioridad:** Consistencia > Disponibilidad

Se prioriza la consistencia porque mostrar información incorrecta podría afectar las decisiones del estudiante sobre su graduación.

##  Usabilidad  vs. Funcionalidad

Se plantea implementar una interfaz organizada por módulos, donde las funcionalidades se agrupen según la necesidad de los usuarios. 

- **Usabilidad:** El sistema debe ser sencillo, intuitivo y permitir que los estudiantes encuentren rápidamente la información que necesitan.
- **Funcionalidades:** El sistema debe ofrecer las herramientas pasa consultar:
   - **Mi progreso:** Cursos aprobados, pendientes y porcentaje de avance.
   - **Requisitos de grado:** Requisitos cumplidos y pendientes.
   - **Plan Académico:** Cursos requeridos de la carrera, recomendados o electivos.
   - **Perfil:** Información del estudiante.
 -**Prioridad:** Usabilidad > Funcionalidad

De esta manera, **DinamikUTB** pueda priorizar la usabilidad sin saturar una pantalla de demasiadas funcionalidades y no afectar la experiencia del estudiante.

---


# **Ejecución del Proyecto**

**DinamikUTB** utiliza una arquitectura de **monolito modular**, con un backend desarrollado en **FastAPI** y un frontend desarrollado en **Flutter**.


## Requisitos Previos

Antes de ejecutar el proyecto, se debe contar con las siguientes herramientas instaladas:

* **Python 3.12** o superior
* **Flutter SDK**
* **Git**
* **Google Chrome**


## Inicio Rápido

Desde la raíz del repositorio, ejecuta el siguiente script:

> [!IMPORTANT]
> **Comando de inicio:**
> 
> ```cmd
> start.bat
> ```

Este comando automatiza el entorno de desarrollo ejecutando las siguientes acciones:

1. Levanta el servicio del backend en **FastAPI**.
2. Inicia el cliente del frontend en **Flutter**.
3. Despliega la interfaz de usuario directamente en **Google Chrome**.

---

## Componentes del Sistema

| Componente | Tecnología | Propósito |
| :--- | :--- | :--- |
| **Backend** | FastAPI | API base y estructura inicial del backend |
| **Frontend** | Flutter | Interfaz de usuario multiplataforma |
| **Pruebas Backend** | Pytest | Validación automatizada del backend |
| **Pruebas Frontend** | Flutter Test | Pruebas unitarias y de componentes de la UI |

---

## URLs de Desarrollo

Una vez iniciado el sistema:

- **API:** `http://127.0.0.1:8000`
- **Documentación de la API:** `http://127.0.0.1:8000/docs`
- **Frontend:** se abre automáticamente en Google Chrome.

---

## Ejecución de pruebas y análisis

Para ejecutar las pruebas del backend:

```bash
cd backend
pytest
```

Para ejecutar las pruebas del frontend:

```bash
cd frontend
flutter test
```

Para verificar el código Flutter:

```bash
cd frontend
flutter analyze
```


# Estructura del proyecto

```text
AS_202620_DinamikUTB/
├── README.md                         # Documentación principal
├── start.bat                         # Inicio del backend y frontend
├── backend/                          # API desarrollada con FastAPI
│   ├── pyproject.toml                # Configuración del proyecto Python
│   ├── requirements.txt              # Dependencias del backend
│   ├── app/
│   │   ├── main.py                   # Punto de entrada de la API
│   │   ├── core/                     # Configuración compartida
│   │   ├── usuarios/                 # Gestión de usuarios
│   │   ├── estudiantes/              # Información y avance académico
│   │   ├── requisitos/               # Requisitos de grado
│   │   ├── programas/                # Programas y planes de estudio
│   │   └── ayuda/                    # Soporte y centro de ayuda
│   └── tests/                        # Pruebas automatizadas del backend
├── frontend/                         # Aplicación multiplataforma en Flutter
│   ├── pubspec.yaml                  # Dependencias y configuración Flutter
│   ├── lib/
│   │   ├── main.dart                 # Punto de entrada de la aplicación
│   │   ├── core/                     # Componentes compartidos
│   │   ├── usuarios/                 # Funcionalidades de usuarios
│   │   ├── estudiantes/              # Funcionalidades de estudiantes
│   │   ├── requisitos/               # Visualización de requisitos
│   │   ├── programas/                # Programas académicos
│   │   └── ayuda/                    # Centro de ayuda
│   ├── test/                         # Pruebas de Flutter
│   └── android/, ios/, linux/        # Configuración por plataforma
│       macos/, web/, windows/
└── docs/                             # Documentación técnica
  ├── adr/                          # Decisiones arquitectónicas
  ├── arc42/                        # Documentación de arquitectura
  ├── c4/                           # Diagramas C4
  ├── aspectos.md                  # Aspectos generales del sistema
  ├── fichadelproblema.md           # Descripción del problema
  └── ia.md                         # Registro relacionado con IA
```

La organización refleja la arquitectura de monolito modular: cada módulo agrupa una responsabilidad funcional dentro del backend y del frontend.

---


## Equipo

    - Gillianis Perez Revolledo
    - Esteban Ramírez Rios
    - Luis Daniel Padilla Leottau
    - Juan José Vargas Pérez
---

