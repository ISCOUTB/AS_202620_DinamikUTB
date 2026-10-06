# Evidencia S9 · Generación verificada y trazable

## La porción

El endpoint de escritura `PUT /requisitos/{requisito_id}/estado` (`backend/app/requisitos/router.py`,
`service.py`, `schemas.py`) y su prueba de contrato (`backend/tests/test_contrato.py`), construidos
con apoyo de Claude en la sesión de trabajo de S4 y S7 respectivamente (ver entradas de
`docs/ia.md`).

## Cadena completa

1. **Aspecto:** [A-01](aspectos.md#a-01--seguimiento-del-cumplimiento-de-requisitos) — fila con las
   ocho columnas completas, incluida la Evidencia que apunta aquí.
2. **ADR con decisión del equipo:** [ADR-0008](adr/0008-verificacion-de-artefactos-sugeridos-por-ia.md).
   No es un ADR que dice "aceptamos lo que propuso la IA": documenta un incidente real (un hash
   inventado que rompió el pipeline) y la decisión del equipo de verificar, de ahí en adelante,
   todo identificador externo que una propuesta de IA incluya, antes de incorporarlo.
3. **Código:** `backend/app/requisitos/router.py`, `service.py`, `schemas.py`.
4. **Prueba que falla ante el defecto que cubre:** [docs/api/evidencia-prueba-contrato.md](api/evidencia-prueba-contrato.md).
   Documenta la secuencia real: un commit que agregó un campo incompatible al contrato
   (`f7c17b9`) hizo fallar `test_el_contrato_versionado_coincide_con_la_api_real` en un run real
   en rojo
   ([run](https://github.com/ISCOUTB/AS_202620_DinamikUTB/actions/runs/35551548541)), y el revert
   posterior volvió a dejarlo en verde.
5. **Medición del escenario asociado:**

   | Escenario | Medida objetivo | Medición actual |
   |---|---|---|
   | [Q-01](arc42/10-quality-requirements.md#escenario-q-01--exactitud-de-la-información-académica) | 100% de los datos correctos, verificado con 20 casos de Pytest | **20 de 20 casos en verde (100%)**, en `backend/tests/test_requisitos.py`: 5 casos base (consulta con datos, consulta vacía, actualización válida, actualización con estado inválido, actualización de requisito inexistente) más 15 casos generados con `pytest.mark.parametrize` — 5 actualizaciones a estado válido, 8 variantes de payload inválido (vacío, texto fuera del enum, espacio final, `null`, número, lista, objeto vacío, mayúsculas) y 2 de requisito inexistente. La carga completa prometida desde S2 queda cerrada con este conteo real, no estimado. |

## Extracto de `docs/ia.md` — aceptado, corregido, rechazado

| Fecha | Propuesta de la IA | Resultado |
|---|---|---|
| 20/09/2026 | Hash `a68d0ecc...` para fijar `sonarqube-scan-action` por SHA | **Rechazado y corregido.** El equipo verificó con `git ls-remote` que el hash no existía en el repositorio oficial, obtuvo el real (`0303d6b6...`) y lo reemplazó. Ver [ADR-0008](adr/0008-verificacion-de-artefactos-sugeridos-por-ia.md). |
| 28/08/2026 | Enlazar el ADR-0001 desde el aspecto A-03 (alertas tempranas) | **Rechazado.** El equipo determinó que el ADR no sustenta ese aspecto porque no define ningún mecanismo de alertas; se dejó sin enlazar en vez de forzar una relación sin sustento. |

(Extracto; la tabla completa con fecha, herramienta, propósito y validación está en `docs/ia.md`.)

## Auditoría de erosión (límites de contexto y propiedad de datos, S6)

Se repitió el método de [`08-cross-cutting-concepts.md`](arc42/08-cross-cutting-concepts.md), sección 8.5, sobre el código de esta
porción:

```bash
git grep -nIE "(INSERT INTO|UPDATE |session\.add\(|session\.commit\(|db\.add\(|db\.commit\()" -- backend/app/requisitos/
```

Resultado: la única escritura está en `requisitos/service.py`, dentro del módulo dueño de la
entidad `Requisito`. No hay escritura cruzada hacia `estudiantes/` ni ningún otro módulo. El
endpoint generado con apoyo de IA respeta el límite de propiedad de datos establecido en S6.

## Dependencias propuestas por el modelo, verificadas

| Dependencia | Propuesta por | Verificación | Resultado |
|---|---|---|---|
| `pytest-cov==7.1.0` | Claude, para generar cobertura hacia SonarCloud | `pip install pytest-cov`, confirmado con `pip freeze` contra el índice real de PyPI | Legítimo, versión real instalada |
| `coverage==7.16.2` | Dependencia transitiva de `pytest-cov` | Igual que arriba | Legítimo |
| `httpx==0.28.1` | Dependencia transitiva de FastAPI/Starlette (cliente HTTP usado en pruebas de contrato) | Verificado en [PyPI](https://pypi.org/project/httpx/0.28.1/): proyecto real, mismo nombre y mantenedor que el paquete instalado | Legítimo, no corresponde al paquete similar `httpx2` que el proyecto también usa intencionalmente (ver `pyproject.toml`) |
| `httpcore==1.0.9` | Dependencia transitiva de `httpx` | Verificado en [PyPI](https://pypi.org/project/httpcore/1.0.9/): coincide con el proyecto oficial de encode | Legítimo |
| `truststore==0.10.4` | Dependencia transitiva (verificación de certificados del sistema operativo) | Verificado en [PyPI](https://pypi.org/project/truststore/0.10.4/): coincide con el proyecto oficial de Python Packaging Authority | Legítimo |
| Hash de `SonarSource/sonarqube-scan-action` | Claude | `git ls-remote` contra el repositorio oficial | **Inválido en el primer intento** (ver ADR-0008); corregido tras verificación |

> **Nota:** `httpx`, `httpcore` y `truststore` no fueron propuestas directas de una conversación con IA — llegaron como dependencias transitivas de paquetes que sí fueron aceptados. Se incluyen igual en esta verificación porque forman parte de lo que "el modelo trajo consigo" al proponer `fastapi`/`httpx2`/`pytest-cov`, y la ficha pide verificar toda dependencia nueva del período, no solo las de primer nivel.

## Credenciales

Barrido del contrato (sección 9) repetido sobre el árbol actual, incluyendo `docs/` y los archivos
generados con apoyo de IA (ADR, `docs/api/openapi.json`, este mismo archivo):

```bash
git grep -nIE '(AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY|ghp_[A-Za-z0-9]{36}|xox[baprs]-|sk-[A-Za-z0-9]{20,}|(password|passwd|secret|token|api_?key)\s*[:=]\s*.{6,})' HEAD
```

Sin coincidencias. `DATABASE_URL` y `SONAR_TOKEN` se referencian por nombre de variable, nunca con
su valor, en `render.yaml` y `.github/workflows/ci.yml`.

## Componente generativo

DinamikUTB no incorpora ningún componente generativo en el sistema desplegado. La decisión de no
incorporarlo, evaluada contra el candidato más cercano (A-03), está en
[ADR-0009](adr/0009-no-incorporacion-componente-generativo.md).
