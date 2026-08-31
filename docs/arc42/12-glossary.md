# 12. Glossary

> Este glosario reúne los términos propios del dominio de **DinamikUTB**, el proceso de graduación universitaria, y del vocabulario específico que el equipo usa en la documentación del proyecto. No incluye términos genéricos de arquitectura de software (API, endpoint, contenedor, etc.), que se asumen conocidos por cualquier lector técnico.

## Términos del dominio académico

| Término | Definición |
|---|---|
| **Requisito de grado** | Condición académica o administrativa que un estudiante debe cumplir para graduarse (créditos, idioma, práctica, opción de grado, electivas, entre otros). Es la unidad central que DinamikUTB rastrea. |
| **Estado de un requisito** | Valor que indica en qué punto se encuentra un requisito para un estudiante: `cumplido`, `pendiente` o `en_proceso`. Corresponde al campo `estado` del modelo `Requisito` en `backend/app/requisitos/models.py`. |
| **Porcentaje de avance** | Proporción de requisitos cumplidos frente al total exigido por el programa académico del estudiante. Todavía no está calculado por el sistema (ver A-02 en `docs/aspectos.md`); hoy el sistema solo expone el estado individual de cada requisito. |
| **Programa académico** | Carrera o plan de estudios de la universidad (por ejemplo, Ingeniería de Sistemas). Define qué requisitos aplican a sus estudiantes. En el corte vertical actual no existe todavía como entidad propia en la base de datos. |
| **Malla curricular** | Estructura de cursos, electivas y requisitos que conforman un programa académico completo. |
| **Requisito de idioma** | Nivel de dominio de un idioma extranjero (por ejemplo, inglés B2) exigido como condición de grado. |
| **Opción de grado** | Modalidad mediante la cual un estudiante culmina su proceso de graduación (por ejemplo, trabajo de grado, práctica empresarial, seminario). |
| **Electiva** | Curso que el estudiante elige dentro de un conjunto definido por su programa, a diferencia de un curso obligatorio de la malla. |
| **Práctica o pasantía** | Experiencia laboral supervisada, exigida como requisito de grado en varios programas de la UTB. |

## Términos propios del proyecto

| Término | Definición |
|---|---|
| **Aspecto** | Necesidad del sistema documentada con trazabilidad completa (requisito → escenario → C4 → ADR → código → pruebas → evidencia), según la metodología Aspect Driven Development que sigue el curso. Registrados en `docs/aspectos.md` con el prefijo `A-` (por ejemplo, A-01). |
| **Escenario de calidad** | Descripción concreta y medible de un atributo de calidad (fuente, estímulo, respuesta, medida), definida en `docs/arc42/10-quality-requirements.md` con el prefijo `Q-` (por ejemplo, Q-01). |
| **Corte vertical** | Recorrido mínimo y ejecutable de un caso de uso que atraviesa las tres capas del sistema — interfaz, lógica y persistencia — de punta a punta. El primero de DinamikUTB implementa la consulta de requisitos de un estudiante (A-01). |
| **Centro de ayuda** | Módulo planeado (`ayuda/`) para que un estudiante reporte inconsistencias en su información académica y un coordinador les dé seguimiento (ver A-07). Sin código todavía. |
| **Táctica arquitectónica** | Mecanismo concreto de diseño o código que ayuda a cumplir la medida de un escenario de calidad específico, documentado en `docs/arc42/04-solution-strategy.md`, sección 4.8.1. |

---

Este glosario se actualizará a medida que se incorporen nuevos aspectos y términos del dominio en las próximas semanas del proyecto.
