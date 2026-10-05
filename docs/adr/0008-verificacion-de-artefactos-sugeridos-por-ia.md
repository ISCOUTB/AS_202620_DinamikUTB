---
id: ADR-0008
title: Verificación obligatoria de artefactos de terceros sugeridos por IA antes de incorporarlos
status: Aceptado
date: 2026-10-01
deciders: Equipo de arquitectura DinamikUTB
---

# ADR-0008: Verificación obligatoria de artefactos de terceros sugeridos por IA antes de incorporarlos

![Status: Aceptado](https://img.shields.io/badge/Status-Accepted-brightgreen?style=flat-square)
![Date: 2026--10--01](https://img.shields.io/badge/Date-2026--10--01-blue?style=flat-square)
![Scope: Process](https://img.shields.io/badge/Scope-Process-orange?style=flat-square)

---

## 1. Contexto y descripción del problema

El equipo usa Claude de forma extensiva para redactar código, documentación y configuración de CI/CD (ver `docs/ia.md`). Al migrar SonarCloud a análisis desde el pipeline (S7), Claude propuso fijar la acción `SonarSource/sonarqube-scan-action` por un hash de commit específico, como práctica de seguridad contra ataques de cadena de suministro (mismo criterio ya aplicado a `actions/checkout` y `subosito/flutter-action`). El hash propuesto, `a68d0ecc0abbcfa74e29868dbf1eb0d3bfe5cb2f`, **no existía** en el repositorio real de SonarSource. El pipeline falló con `"Unable to resolve action... unable to find version"`.

Esto reveló un riesgo concreto: un modelo de lenguaje puede producir un identificador externo (hash, nombre de paquete, versión) que tiene el formato correcto y es técnicamente plausible, pero que no corresponde a un artefacto real. Si el equipo lo hubiera aceptado sin verificar y el error hubiera sido, en cambio, un hash *válido* mal dirigido (de un fork malicioso, por ejemplo), el riesgo sería de seguridad y no solo de pipeline roto.

## 2. Factores de decisión

| Factor | Descripción |
| :--- | :--- |
| **Integridad de la cadena de suministro del CI** | El pipeline ejecuta código de terceros (acciones de GitHub, dependencias de Python y Dart) en cada push; un artefacto incorrecto puede comprometer la ejecución sin que el código propio tenga ningún error. |
| **Velocidad del equipo** | El proyecto corre contra fechas de corte semanales ([02-architecture-constraints.md](../arc42/02-architecture-constraints.md), sección 2.2); cualquier política de verificación no puede ser tan costosa que frene el ritmo del semestre. |
| **Política de uso responsable de IA del curso** | El curso exige registrar en `docs/ia.md` qué se acepta, qué se corrige y qué se rechaza de las propuestas de IA, con motivo técnico — no alcanza con "la IA lo sugirió". |
| **Confiabilidad de la evidencia** | Si el equipo no puede garantizar que lo que hay en el repositorio es lo que dice ser, toda la trazabilidad construida en `docs/aspectos.md` y los ADR pierde valor como evidencia. |

## 3. Alternativas consideradas

### 3.1 Confiar en la propuesta de la IA sin verificación adicional

* **Ventajas:** Cero fricción, máxima velocidad.
* **Desventajas:** Es exactamente lo que falló: un hash inventado llegó hasta un push real al repositorio. No hay garantía de que el siguiente error sea tan visible (un pipeline roto se nota de inmediato; una dependencia con nombre casi idéntico a la legítima, no).
* **Descartada**, por la evidencia directa del incidente.

### 3.2 Confiar en el escaneo posterior de SonarCloud / Dependabot

* **Ventajas:** No añade pasos manuales; se apoya en herramientas ya integradas al pipeline (S7).
* **Desventajas:** Actúa **después** de que el artefacto ya se mergeó y, en el caso de un hash de acción, después de que ya se ejecutó al menos una vez en CI. Para un ataque de cadena de suministro, llegar tarde no sirve.
* **Descartada** por no prevenir, solo detectar tarde.

### 3.3 Verificación manual contra la fuente oficial antes de aceptar

* **Ventajas:** Se ejecuta antes de que el artefacto entre al repositorio. Para hashes de GitHub Actions, un solo comando (`git ls-remote <repo> refs/tags/<version>`) confirma el valor real sin necesidad de herramientas nuevas. Para paquetes de Python o Dart, el equivalente es `pip index versions <paquete>` o revisar la página oficial en PyPI / pub.dev antes de fijar la versión.
* **Desventajas:** Agrega un paso manual cada vez que se acepta una propuesta de IA que incluya un identificador externo (hash, nombre de paquete, versión). No es automatizable sin trabajo adicional de tooling que el equipo no tiene tiempo de construir este semestre.

## 4. Decisión

Se adopta como práctica del equipo: **toda propuesta de IA que incluya un identificador verificable externamente (hash de commit, nombre de paquete, número de versión) se verifica contra la fuente oficial antes de incorporarla al repositorio**, usando el comando más directo disponible para ese tipo de artefacto (`git ls-remote` para GitHub Actions, consulta directa a PyPI/pub.dev para paquetes).

> **Justificación principal:** el incidente real con `sonarqube-scan-action` demuestra que la propuesta de una IA puede ser plausible y estar mal, y que el costo de verificar (un comando) es muchísimo menor que el costo de un artefacto incorrecto llegando a producción o a la evidencia del curso.

Esta decisión no reemplaza ningún ADR anterior: es una práctica de proceso, no una decisión de arquitectura del sistema.

## 5. Consecuencias

### Consecuencias positivas

* **El incidente se corrigió antes del cierre de S7**, con el hash real (`0303d6b62e310685c0e34d0b9cde218036885c4d`) confirmado por `git ls-remote` y documentado en el commit de corrección.
* **Precedente para el resto del proyecto:** cualquier integrante que reciba una sugerencia de IA con un identificador externo sabe qué comando correr antes de aceptarla.

### Consecuencias negativas

* **Fricción añadida:** cada hash o paquete nuevo sugerido por IA cuesta un paso manual extra, en vez de copiar y pegar directamente.
* **Depende de la disciplina del equipo:** no hay ningún control automatizado que impida mergear un identificador sin verificar; es una práctica, no una barrera técnica.

## 6. Relación con atributos de calidad

| Atributo | Relación con la decisión |
| :--- | :--- |
| **Exactitud / Consistencia** | La integridad del pipeline que valida Q-01 depende de que sus propias herramientas (acciones de CI) sean las legítimas, no una sustitución. |
| **Seguridad** | Previene directamente un vector de ataque de cadena de suministro a través de artefactos de terceros mal referenciados. |
| **Mantenibilidad** | Deja un procedimiento documentado y repetible, en vez de depender de que alguien "se dé cuenta" cada vez. |

## 7. Relación con las restricciones del proyecto

Responde a la política de uso responsable de IA del curso, que exige registrar lo aceptado, lo corregido y lo rechazado con motivo técnico (`docs/ia.md`), y no introduce costo ni herramienta nueva, consistente con el límite de simplicidad operativa de [02-architecture-constraints.md](../arc42/02-architecture-constraints.md).

## 8. Estado de la decisión

**Aceptado.** Se aplica desde la corrección del incidente de S7 en adelante.

## 9. Trazabilidad

| Elemento | Referencia |
| :--- | :--- |
| **Aspecto que sustenta** | [A-01](../aspectos.md#a-01--seguimiento-del-cumplimiento-de-requisitos) (integridad del pipeline que valida este aspecto) |
| **Escenario de calidad** | [Q-01](../arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica) |
| **Incidente que motivó la decisión** | Hash inválido `a68d0ecc0abbcfa74e29868dbf1eb0d3bfe5cb2f` propuesto para `SonarSource/sonarqube-scan-action`, corregido a `0303d6b62e310685c0e34d0b9cde218036885c4d` tras verificación con `git ls-remote` |
| **Registro en docs/ia.md** | Entrada "Apoyo en la migración de SonarCloud..." (27/09/2026), estado "Aceptado parcialmente" |
| **Commits** | Commit de corrección del hash en `.github/workflows/ci.yml` (S7) |
