# 4. Solution Strategy

La estrategia de solución de **DinamikUTB** se define considerando el alcance actual del proyecto, sus atributos de calidad prioritarios y la necesidad de permitir una evolución progresiva del sistema.

El proyecto iniciará con un enfoque controlado y acotado, por lo que se busca una solución que mantenga una implementación sencilla, pero que al mismo tiempo permita organizar adecuadamente las funcionalidades y escalar progresivamente la capacidad de almacenamiento de información en el futuro.

Para definir la estrategia arquitectónica se compararon tres alternativas: **arquitectura en capas, arquitectura hexagonal y monolito modular**.

---

## 4.1 Context

Para definir la estrategia arquitectónica de **DinamikUTB** se analizaron tres alternativas:

1. **Arquitectura en capas**
2. **Arquitectura hexagonal**
3. **Monolito modular**

La comparación se realiza considerando las necesidades actuales del proyecto y su posible evolución.

DinamikUTB arrancará con un núcleo funcional simplificado para su desarrollo semestral. Aun así, se busca que el sistema pueda escalar gradualmente para sumar más programas académicos, módulos e integraciones externas sin requerir una reestructuración completa.

Por esta razón, la selección no busca utilizar la arquitectura más compleja, sino encontrar un equilibrio entre **simplicidad, organización y capacidad de evolución**.

---

## 4.2 Evaluation Criteria

| Criterio | Descripción |
|---|---|
| **Simplicidad inicial** | Facilidad para comprender, desarrollar y mantener la solución durante el proyecto. |
| **Organización interna** | Capacidad para separar responsabilidades y mantener una estructura clara. |
| **Evolución del sistema** | Facilidad para incorporar nuevas funcionalidades y programas académicos. |
| **Independencia tecnológica** | Facilidad para realizar cambios en tecnologías como persistencia, interfaz o servicios externos. |
| **Testabilidad** | Facilidad para realizar pruebas sobre las diferentes partes del sistema. |
| **Integraciones futuras** | Facilidad para incorporar posteriormente servicios o sistemas externos. |
| **Adecuación al proyecto** | Qué tan apropiada resulta la alternativa para el tamaño y alcance actual de DinamikUTB. |

---

## 4.3 Rating Scale

Para realizar la comparación se utiliza una escala de **1 a 5**:

| Valor | Interpretación |
|---:|---|
| **1** | Muy desfavorable |
| **2** | Desfavorable |
| **3** | Aceptable |
| **4** | Favorable |
| **5** | Muy favorable |

Las valoraciones representan la adecuación de cada alternativa al contexto específico de **DinamikUTB**, no una clasificación absoluta de las arquitecturas.

---

## 4.4 Comparison Matrix

| Criterio | Capas | Hexagonal | Monolito modular |
|---|---:|---:|---:|
| Simplicidad inicial | 5 | 3 | 5 |
| Organización interna | 4 | 5 | 5 |
| Evolución del sistema | 3 | 5 | 5 |
| Independencia tecnológica | 3 | 5 | 3 |
| Testabilidad | 3 | 5 | 4 |
| Integraciones futuras | 3 | 5 | 4 |
| Adecuación al proyecto | 5 | 3 | 5 |
| **Total** | **26** | **31** | **31** |

> **Nota:** El resultado numérico no determina por sí solo la decisión arquitectónica. La selección también considera el contexto, las restricciones y el nivel de complejidad que resulta razonable para el proyecto.

---

## 4.5 Alternatives Analysis

### 4.5.1 Arquitectura en capas

La arquitectura en capas organiza el sistema en diferentes niveles de responsabilidad, por ejemplo, presentación, aplicación, lógica de negocio y persistencia.

**Ventajas para DinamikUTB:**

- Es sencilla de comprender.
- Tiene una estructura ampliamente conocida.
- Permite separar responsabilidades.
- Facilita un inicio rápido del desarrollo.
- Resulta apropiada para una aplicación pequeña o mediana.

**Limitaciones:**

- Puede generar un mayor acoplamiento entre las diferentes capas.
- Los cambios en elementos externos pueden afectar otras partes del sistema.
- La evolución de la estructura puede resultar más difícil cuando aumente la cantidad de funcionalidades.

**Valoración:**

Es una alternativa válida para DinamikUTB y presenta una excelente relación entre simplicidad y funcionalidad inicial. Sin embargo, ofrece menos mecanismos para controlar el acoplamiento y facilitar la evolución futura.

---

### 4.5.2 Arquitectura hexagonal

La arquitectura hexagonal busca mantener el núcleo de la aplicación independiente de elementos externos mediante puertos y adaptadores.

**Ventajas para DinamikUTB:**

- Favorece la separación entre la lógica de la aplicación y las tecnologías externas.
- Facilita las pruebas de la lógica sin depender directamente de infraestructura.
- Permite sustituir adaptadores, como mecanismos de persistencia o interfaces.
- Facilita futuras integraciones con servicios externos.

**Limitaciones:**

- Introduce conceptos y estructuras adicionales desde las primeras etapas.
- Puede resultar más compleja de lo necesario para el tamaño inicial del proyecto.
- Requiere mayor disciplina para mantener correctamente la separación entre puertos y adaptadores.

**Valoración:**

Es una alternativa técnicamente sólida y proporciona buenas posibilidades de evolución. Sin embargo, para el alcance actual de DinamikUTB puede introducir una complejidad mayor de la necesaria.

---

### 4.5.3 Monolito modular

El monolito modular mantiene la aplicación como una única unidad desplegable, pero organiza internamente sus funcionalidades en módulos con responsabilidades bien definidas.

Una posible organización futura de DinamikUTB podría incluir módulos como:

```text
DinamikUTB
│
├── Usuarios
├── Estudiantes
├── Requisitos
├── Programas académicos
└── Centro de ayuda
```

**Ventajas para DinamikUTB**

* Mantiene una implementación y despliegue sencillos.
* Permite separar las principales funcionalidades del sistema.
* Facilita la incorporación de nuevos módulos.
* Es apropiado para el tamaño inicial del proyecto.
* Permite evolucionar progresivamente la arquitectura.
* No obliga a introducir múltiples aplicaciones o servicios desde el inicio.


**Limitaciones**

* Los módulos continúan formando parte de una misma aplicación.
* Requiere establecer límites claros para evitar dependencias innecesarias entre módulos.
* No proporciona por sí solo el mismo nivel de independencia tecnológica que una arquitectura hexagonal.

**Valoración:** Proporciona un equilibrio adecuado entre simplicidad y capacidad de crecimiento para el alcance actual de DinamikUTB.

---

## 4.6 Decision

Después de comparar las alternativas, se selecciona el **Monolito Modular** como estrategia arquitectónica inicial para DinamikUTB.

La decisión se basa principalmente en que permite mantener una solución sencilla para el desarrollo del proyecto, mientras establece una estructura modular que facilite su evolución.

Esta alternativa responde especialmente bien a las condiciones actuales del proyecto:

* El sistema tendrá inicialmente un tamaño pequeño/mediano.
* Se busca evitar complejidad arquitectónica innecesaria.
* Se requiere una estructura clara para separar responsabilidades.
* Se contempla la incorporación de nuevos programas académicos y funcionalidades.
* Las posibles integraciones con sistemas externos de la universidad son una necesidad futura, no una dependencia inicial.
* El sistema podrá evolucionar progresivamente sin requerir una migración inmediata a una arquitectura distribuida.

---

## 4.7 Future Evolution

La elección del Monolito Modular no impide adoptar posteriormente mecanismos de mayor desacoplamiento.

Si el sistema aumenta significativamente su complejidad o aparecen nuevas necesidades de integración, determinados módulos podrán incorporar principios de arquitectura hexagonal o evolucionar de forma independiente.

Por lo tanto, la estrategia inicial busca evitar una sobrearquitectura:

> Primero una estructura modular y sencilla; posteriormente, mayor desacoplamiento cuando las necesidades reales del sistema lo justifiquen.

Esta evolución deberá estar respaldada por nuevas decisiones arquitectónicas documentadas mediante ADR.

---

## 4.8 Quality Attributes Relationship

La decisión se relaciona principalmente con los atributos de calidad priorizados durante S2:

| Atributo | Relación con la decisión |
| :--- | :--- |
| **Exactitud / Consistencia** | La separación de módulos facilita mantener responsabilidades claras sobre la información académica. |
| **Seguridad** | La organización modular facilita separar las responsabilidades relacionadas con usuarios y control de acceso. |
| **Usabilidad** | La arquitectura permite evolucionar las funcionalidades sin afectar innecesariamente otras partes del sistema. |
| **Rendimiento** | Al mantenerse como una única aplicación, se evita inicialmente la complejidad y latencia asociada a múltiples servicios. |
| **Disponibilidad** | Un único sistema desplegable simplifica inicialmente la operación y administración de la aplicación. |
| **Trazabilidad** | La separación modular facilita identificar dónde se realizan determinadas operaciones y cambios. |
| **Mantenibilidad** | La división en módulos permite modificar y ampliar funcionalidades manteniendo responsabilidades delimitadas. |

---

## 4.9 Decision Summary

| Elemento | Decisión |
| :--- | :--- |
| **Arquitectura seleccionada** | Monolito modular |
| **Motivo principal** | Equilibrio entre simplicidad y capacidad de evolución |
| **Despliegue inicial** | Una única aplicación |
| **Base de datos** | Base de datos propia |
| **Integraciones externas** | No requeridas inicialmente |
| **Evolución prevista** | Incorporación progresiva de módulos y, si fuese necesario, mayor desacoplamiento |
| **Decisión documentada en** | `docs/adr/0001-seleccion-monolito-modular.md` |
