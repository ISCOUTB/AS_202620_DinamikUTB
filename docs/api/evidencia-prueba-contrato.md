# Evidencia: la prueba de contrato falla ante un cambio incompatible

Esta evidencia responde al criterio de S7 que exige demostrar que la prueba de contrato
(`backend/tests/test_contrato.py`) efectivamente detiene un cambio incompatible, no solo
que existe.

## Secuencia real

| Paso | Commit | Cambio | Resultado del pipeline |
|---|---|---|---|
| 1 | [`f7c17b9`](https://github.com/ISCOUTB/AS_202620_DinamikUTB/commit/f7c17b988a97c66391c71b36cc1f6a460b4b2f2d) | Se agregó el campo `creditos: int = 0` a `RequisitoOut` (`backend/app/requisitos/schemas.py`), sin regenerar el contrato versionado en `docs/api/openapi.json`. |  Rojo — [run](https://github.com/ISCOUTB/AS_202620_DinamikUTB/actions/runs/35551548541). `test_el_contrato_versionado_coincide_con_la_api_real` falló, deteniendo la integración. |
| 2 | [`1c4847a`](https://github.com/ISCOUTB/AS_202620_DinamikUTB/commit/1c4847a) | `git revert` del commit anterior, quitando el campo `creditos`. | Rojo — el pipeline volvió a fallar, y agregando una causa distinta, un error de sintaxis YAML preexistente en `.github/workflows/ci.yml` (comillas faltantes alrededor de `--only-binary :all:`), no relacionado con el contrato. |
| 3 | [`31350f1`](https://github.com/ISCOUTB/AS_202620_DinamikUTB/commit/31350f13569e9e9b958a112866a0aa707e9bc271) | Corrección de la sintaxis YAML en `ci.yml`. |  Verde — [run](https://github.com/ISCOUTB/AS_202620_DinamikUTB/actions/runs/35553215099). Con el contrato ya revertido y el YAML corregido, las 11 pruebas pasan. |

## Salida local del test que falló (paso 1)

```text
tests\test_contrato.py F..                                                                                       [ 27%]
tests\test_estudiantes.py ..                                                                                     [ 45%]
tests\test_main.py .                                                                                             [ 54%]
tests\test_requisitos.py .....                                                                                   [100%]

====================================================== FAILURES =======================================================
________________________________ test_el_contrato_versionado_coincide_con_la_api_real _________________________________

def test_el_contrato_versionado_coincide_con_la_api_real():
    contrato_guardado = json.loads(RUTA_CONTRATO.read_text(encoding="utf-8"))
    contrato_actual = app.openapi()

>   assert contrato_guardado == contrato_actual, (
        "El contrato en docs/api/openapi.json no coincide con la API actual. "
        "Corré 'python -m scripts.export_openapi' para regenerarlo."
    )
E       AssertionError: El contrato en docs/api/openapi.json no coincide con la API actual. Corré 'python -m scripts.export_openapi' para regenerarlo.

tests\test_contrato.py:19: AssertionError
=============================================== short test summary info ===============================================
FAILED tests/test_contrato.py::test_el_contrato_versionado_coincide_con_la_api_real
============================================ 1 failed, 10 passed in 4.05s =============================================

```

## Nota sobre el paso 2

El revert del cambio incompatible (paso 2) coincidió con un error de sintaxis YAML en
`ci.yml` que se corrigió en el mismo momento (paso 3), sin relación con la prueba de
contrato. Los tests de Pytest ya venían pasando en verde en corridas anteriores del pipeline
antes de este experimento; el ajuste del YAML fue una corrección de mantenimiento normal
del pipeline, independiente de la demostración del contrato.
