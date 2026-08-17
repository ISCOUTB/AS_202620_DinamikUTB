# 10. Quality Requirements

## 10.1 Quality Requirements Overview

Los requisitos de calidad de DinamikUTB se centran principalmente en garantizar que la información académica mostrada al estudiante sea correcta, que los datos estén protegidos y que el sistema sea fácil de utilizar.

La prioridad se establece considerando el impacto que tendría una falla sobre el proceso de graduación del estudiante y el riesgo técnico asociado.

### Priorización de atributos de calidad

| Prioridad | Atributo de calidad | Impacto | Riesgo técnico | Justificación |
|---|---|---|---|---|
| 1 | Exactitud / Consistencia | Alto | Alto | Una información incorrecta podría llevar al estudiante a tomar decisiones equivocadas sobre sus requisitos de graduación. |
| 2 | Seguridad | Alto | Alto | El sistema manejará información académica y datos personales de los estudiantes. |
| 3 | Usabilidad | Medio | Medio | La información debe ser fácil de entender para que el estudiante pueda utilizar el sistema rápidamente. |
| 4 | Rendimiento | Medio | Medio | Las consultas del progreso académico deben responder rápidamente. |
| 5 | Disponibilidad | Medio | Bajo | El sistema debe estar disponible cuando el estudiante necesite consultar su información. |
| 6 | Trazabilidad | Bajo | Bajo | Los cambios realizados sobre la información deben poder ser identificados mediante un historial. |
| 7 | Mantenibilidad | Bajo | Bajo | El sistema debe poder evolucionar para incorporar nuevos requisitos y programas académicos. |

---

## 10.2 Árbol de utilidad

El árbol de utilidad organiza los atributos de calidad de acuerdo con su importancia para DinamikUTB.

```text
DinamikUTB
│
├── Exactitud / Consistencia
│   └── Información académica correcta
│
├── Seguridad
│   └── Protección de información académica y acceso según rol
│
├── Usabilidad
│   └── Información clara y fácil de comprender
│
├── Rendimiento
│   └── Respuesta rápida de las consultas
│
├── Disponibilidad
│   └── Acceso al sistema cuando el estudiante lo necesite
│
├── Trazabilidad
│   └── Historial de cambios sobre la información
│
└── Mantenibilidad
    └── Incorporación de nuevos requisitos y programas académicos
