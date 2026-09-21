# Deuda técnica reconocida

Este documento registra decisiones conscientes de posponer una mejora, con el motivo y
la evidencia de que fue una decisión informada, no un olvido.

| Ítem | Detectado por | Fecha | Motivo de posponer | Cómo resolverlo |
|---|---|---|---|---|
| Backend sin lock file con hashes (`backend/pyproject.toml`, hotspot de SonarCloud: "Dependency versions are not predictable") | SonarCloud | 20/09/2026 | No es criterio evaluado en la ficha de la semana en curso; el tiempo se priorizó para el contrato de API (S7). | Generar `requirements.lock.txt` con `pip-compile --generate-hashes`, o migrar a Poetry/uv. Verificar que `pytest` siga en verde después del cambio. |
| Gradle sin lock file (`frontend/android/build.gradle.kts`, hotspot similar) | SonarCloud | 20/09/2026 | Mismo motivo. | Correr `./gradlew dependencies --write-locks` para generar `gradle.lockfile`. |
