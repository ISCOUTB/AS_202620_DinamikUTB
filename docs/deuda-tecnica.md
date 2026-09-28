# Deuda técnica reconocida

Este documento registra decisiones conscientes de posponer una mejora, con el motivo y
la evidencia de que fue una decisión informada, no un olvido.

| Ítem | Detectado por | Fecha | Motivo de posponer | Cómo resolverlo | Estado |
|---|---|---|---|---|---|
| Backend sin lock file con hashes (`backend/pyproject.toml`, hotspot de SonarCloud: "Dependency versions are not predictable") | SonarCloud | 20/09/2026 | No es criterio evaluado en la ficha de la semana en curso; el tiempo se priorizó para el contrato de API (S7). | Generar `requirements.lock.txt` con `pip-compile --generate-hashes`, o migrar a Poetry/uv. Verificar que `pytest` siga en verde después del cambio. | Pendiente |
| Gradle sin lock file (`frontend/android/build.gradle.kts`, hotspot similar) | SonarCloud | 20/09/2026 | Mismo motivo. | Correr `./gradlew dependencies --write-locks` para generar `gradle.lockfile`. | Pendiente |
| Migración de SQLite a PostgreSQL, recomendada por el docente | Docente (recomendación en clase) | 20/09/2026 | Requería ADR, actualización de C4, dependencias y configuración. | Ver [ADR-0007](adr/0007-persistencia-render-postgres.md): `backend/app/core/database.py` lee `DATABASE_URL` y el ambiente desplegado usa Render Postgres. | **Resuelta operativamente (27/09/2026)** para el ambiente desplegado. El CI y el desarrollo local siguen en SQLite; ver riesgo de divergencia en `arc42/11`. |
| Autenticación ausente (`usuarios/` sin código) con backend público | Revisión de riesgos S8 | 27/09/2026 | Fuera del alcance de la semana de despliegue. | Implementar A-05; hasta entonces, solo datos de seed en el ambiente desplegado (`arc42/11`, sección 11.1). | Pendiente |
