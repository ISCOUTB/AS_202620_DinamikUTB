
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
- [Ejecución del Proyecto](#ejecución-del-proyecto)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Entorno desplegado](#entorno-desplegado)
- [Resiliencia y modos de fallo](#resiliencia-y-modos-de-fallo)
- [Equipo](#equipo)

---

# Descripción

**DinamikUTB** es una plataforma diseñada para facilitar a los estudiantes el seguimiento de los diferentes requisitos necesarios para completar satisfactoriamente su proceso de graduación.

La solución busca centralizar información que actualmente puede encontrarse distribuida entre reglamentos académicos, plataformas institucionales y otras fuentes de consulta.

El sistema permite que el estudiante pueda conocer de manera clara:

- Qué requisitos ya ha completado.
- Qué requisitos tiene pendientes.
- Cuáles se encuentran en proceso.
- Qué requisitos requieren atención.
- Qué tan cerca se encuentra de completar su proceso de graduación.

Además, la plataforma permite a coordinadores y administradores gestionar catálogos de requisitos, programas académicos y supervisar el avance curricular.

---

# Contexto

En la Universidad Tecnológica de Bolívar, los estudiantes deben cumplir diferentes condiciones académicas y administrativas, entre ellas:

- Créditos académicos de la malla curricular.
- Nivel de idioma extranjero (ej. Inglés B2).
- Prácticas o pasantías profesionales.
- Opción de grado (proyecto de ingeniería, seminario, etc.).
- Cursos electivos y complementarios del programa.

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
- Facilitar la planificación académica del estudiante mediante la visualización de la malla curricular.
- Permitir la gestión de múltiples programas académicos.

---

# Usuarios

El sistema está orientado a tres roles principales, alineados con los stakeholders definidos en `docs/arc42/01-introduction-and-goals.md`:

### Estudiantes

Usuarios principales de la plataforma. Consultan su progreso hacia la graduación: requisitos cumplidos, pendientes, malla curricular y porcentaje de avance.

### Coordinadores Académicos

Supervisan y gestionan la información de los estudiantes de su programa. Consultan estudiantes de su carrera, gestionan requisitos y atienden solicitudes de inconsistencias.

### Administradores

Gestionan el funcionamiento general del sistema: cuentas de usuario, programas académicos, requisitos de catálogo, seguimiento institucional y exportación de reportes.

---

# Solución Propuesta

**DinamikUTB** proporciona una vista centralizada del proceso de graduación del estudiante.

El sistema analiza los requisitos establecidos para el programa académico y permite determinar cuáles han sido cumplidos, cuáles permanecen en proceso y cuáles están pendientes. La solución se estructura bajo una arquitectura de **monolito modular** en el backend y una interfaz cliente multiplataforma construida en Flutter.

---

# Funcionalidades

## Seguimiento de requisitos y avance

- Consulta centralizada de requisitos de grado por estudiante.
- Cálculo automático del porcentaje de avance hacia la graduación.
- Matriz de requisitos clasificada por estado (cumplido, en proceso, pendiente).
- Consulta interactiva de la malla curricular por niveles y verificación de prerrequisitos.

## Gestión administrativa y académica

- Directorio de estudiantes con filtros por programa, semestre y estado.
- Administración del catálogo de programas académicos y requisitos institucionales.
- Módulo de seguimiento académico y detección de estudiantes próximos a egreso.
- Exportación segura de reportes en formato CSV con protección contra inyecciones de fórmulas.
- Restablecimiento seguro de contraseñas mediante tokens atómicos de un solo uso.

---

# Atributos de calidad

## Disponibilidad vs. Consistencia

- **Disponibilidad:** El sistema debe permanecer accesible incluso ante fallas parciales o alta demanda.
- **Consistencia:** La información sobre los requisitos de grado debe ser correcta y coherente.
- **Prioridad:** Consistencia > Disponibilidad (Q-01).

Se prioriza la consistencia porque mostrar información incorrecta podría inducir a decisiones académicas erróneas.

## Usabilidad vs. Funcionalidad

- **Usabilidad:** La interfaz debe ser sencilla, intuitiva y responsive, adaptándose fluidamente de dispositivos móviles a pantallas de escritorio.
- **Funcionalidades:** El sistema ofrece herramientas agrupadas modularmente (Mi progreso, Malla curricular, Requisitos de grado, Panel de gestión y Perfil).
- **Prioridad:** Usabilidad > Funcionalidad (Q-03).

---

# Ejecución del Proyecto

**DinamikUTB** utiliza una arquitectura de **monolito modular**, con un backend desarrollado en **FastAPI** y un frontend desarrollado en **Flutter**. La persistencia se maneja con **SQLAlchemy**: **SQLite** en desarrollo local/CI y **PostgreSQL** en el entorno desplegado del laboratorio ([ADR-0003](docs/adr/0003-seleccion-motor-de-base-de-datos.md), [ADR-0012](docs/adr/0012-despliegue-en-servidor-del-laboratorio.md)).

## Requisitos Previos

* **Python 3.12** o superior
* **Flutter SDK** (canal stable)
* **Git**
* **Google Chrome**

## Inicio Rápido (Local)

Desde la raíz del repositorio, ejecuta el script de arranque:

```cmd
start.bat
```

Este comando automatiza el entorno de desarrollo:

Prepara el entorno virtual del backend e instala dependencias.

Inicia el servidor de API en FastAPI (http://127.0.0.1:8000).

Carga los datos de ejemplo idempotentemente si la base está vacía.

Compila y ejecuta el cliente Flutter directamente en Google Chrome.

## Datos de ejemplo

Para sembrar datos iniciales de prueba (estudiante de ejemplo y usuarios demo):

```bash
cd backend
python -m app.seed
```

## Componentes del Sistema

| Componente | Tecnología | Propósito |
|---|---|---|
| Backend API | FastAPI / Python 3.12 | API REST modular, autenticación JWT, rate limit y auditoría |
| Persistencia | SQLAlchemy (SQLite local / PostgreSQL en producción) | Almacenamiento relacional de información académica y auditoría |
| Frontend | Flutter Web / Multiplataforma | Interfaz gráfica adaptativa para estudiantes y administración |
| Pruebas Backend | Pytest / Pytest-cov | Suite de pruebas unitarias, de contrato y de integración |
| Pruebas Frontend | Flutter Test | Pruebas de componentes, validadores y responsividad |
| Integración continua | GitHub Actions | Validación automática de pruebas, análisis y empaquetado Docker |
| Análisis estático | SonarCloud | Calidad de código, mantenibilidad y Quality Gate |
| Despliegue principal | Dokploy / Docker en servidor de laboratorio | Contenedores web (Nginx), API (FastAPI) y base de datos con volumen persistente |

## URLs de Desarrollo

Una vez iniciado el sistema en local:

- API: http://127.0.0.1:8000
- Documentación OpenAPI: http://127.0.0.1:8000/docs
- Health check: http://127.0.0.1:8000/health
- Métricas: http://127.0.0.1:8000/metrics

## Ejecución de pruebas y análisis

Pruebas del backend con reporte de cobertura:

```bash
cd backend
python -m pytest --cov --cov-report=xml
```

Pruebas del frontend y análisis estático:

```bash
cd frontend
flutter analyze
flutter test
```

## Estructura del proyecto

```text
AS_202620_DinamikUTB/
├── README.md                         # Documentación principal
├── start.bat                         # Inicio automatizado para desarrollo local
├── docker-compose.yml                # Docker compose para desarrollo local con Postgres
├── deploy/
│   ├── compose.lab.yaml              # Despliegue en Dokploy en el laboratorio (ADR-0012)
│   └── .env.example                  # Variables de entorno de despliegue
├── .coveragerc                       # Configuración de cobertura de pruebas
├── sonar-project.properties          # Configuración del análisis de SonarCloud
├── .github/
│   └── workflows/
│       ├── ci.yml                    # Pipeline de CI (Pytest, Flutter test, SonarCloud)
│       └── publish-frontend-image.yml # Publicación de imagen Docker en GHCR
├── backend/                          # API en FastAPI
│   ├── app/
│   │   ├── main.py                   # Configuración de la API, middleware y seguridad
│   │   ├── seed.py                   # Población inicial de datos demo
│   │   ├── core/                     # Base de datos, config, seguridad, métricas y rate limit
│   │   ├── usuarios/                 # Autenticación, JWT, roles RBAC y recuperación
│   │   ├── estudiantes/              # Perfiles académicos y trazabilidad histórica
│   │   ├── requisitos/               # Gestión, cálculo de avance e historial transaccional
│   │   ├── programas/                # Gestión de programas académicos
│   │   ├── curriculo/                # Catálogo de mallas curriculares y prerrequisitos
│   │   ├── reportes/                 # Exportación segura de reportes CSV
│   │   └── ayuda/                    # Trazabilidad para solicitudes de inconsistencias
│   └── tests/                        # Suite de pruebas automatizadas
├── frontend/                         # Cliente en Flutter
│   ├── lib/
│   │   ├── main.dart                 # Punto de entrada e inyección de dependencias
│   │   ├── core/                     # Red, storage seguro, tema, shell y auth gate
│   │   ├── usuarios/                 # Vistas de login, perfil y recuperación
│   │   ├── estudiantes/              # Dashboard del estudiante y widgets de avance
│   │   ├── curriculo/                # Malla curricular y tarjetas de cursos
│   │   ├── requisitos/               # Seguimiento y gestión de requisitos
│   │   └── administracion/           # Panel administrativo completo
│   └── test/                         # Pruebas de widgets y servicios
└── docs/                             # Documentación de arquitectura
    ├── adr/                          # Decisiones arquitectónicas (0001 a 0014)
    ├── arc42/                        # Documentación arc42 (secciones 1 a 12)
    ├── c4/                           # Diagramas C4 de contexto y contenedores
    ├── aspectos.md                   # Matriz de Aspect-Driven Development
    └── evidencia-s12.md              # Evidencia de estrategia de datos y consistencia
```

## Entorno desplegado

El entorno principal de la aplicación se encuentra desplegado en el servidor del laboratorio institucional mediante Dokploy, con persistencia en volumen Docker (pgdata). El entorno experimental previo de Render fue retirado.

| Pieza | URL / Acceso | Estado |
|---|---|---|
| Frontend Web | https://dinamikutb.iscoutb.dev | Activo |
| Backend API | https://api.dinamikutb.iscoutb.dev | Activo (FastAPI) |
| Health check | https://api.dinamikutb.iscoutb.dev/health | 200 {"status":"ok"} |
| Métricas (Q-05) | https://api.dinamikutb.iscoutb.dev/metrics | Formato Prometheus |
| Base de datos | PostgreSQL 16 (Dokploy) | Persistencia en volumen pgdata |
| Análisis estático | SonarCloud | Quality Gate en verde |

Comprobación externa verificada (red móvil fuera de la universidad):

```text
HTTP/2 200 OK
{"status":"ok"}
```

## Resiliencia y modos de fallo

La integración entre el frontend Flutter, la API FastAPI y la base de datos está analizada en detalle en arc42 §11.5:

- Cliente HTTP resiliente: frontend/lib/requisitos/requisitos_service.dart aplica timeout de 25 s por intento y hasta 3 intentos con retroceso exponencial (backoff creciente) ante fallos de conexión o respuestas 5xx.
- Idempotencia en escrituras: El endpoint PUT /requisitos/{id}/estado fija un valor absoluto; repetirlo conserva el mismo resultado sin duplicar registros.
- Concurrencia protegida: La consulta de actualización utiliza with_for_update=True en SQLAlchemy para serializar escrituras concurrentes a nivel de fila en PostgreSQL.
- Historial transaccional: Las modificaciones en requisitos y datos de estudiantes se guardan atómicamente en sus respectivas tablas de auditoría _historial dentro de la misma transacción (ADR-0011, ADR-0014).
- Invalidación reactiva de interfaz: AuthGate invalida y reconstruye las pantallas de inicio y malla mediante una ValueKey reactiva ante cambios en los datos del perfil del usuario, evitando estados desincronizados.
- Tokens seguros: Los enlaces de recuperación se invalidan atómicamente en la base de datos mediante actualización condicional para evitar doble uso simultáneo.

## Equipo

- Gillianis Perez Revolledo
- Esteban Ramírez Rios
- Luis Daniel Padilla Leottau
- Juan José Vargas Pérez
