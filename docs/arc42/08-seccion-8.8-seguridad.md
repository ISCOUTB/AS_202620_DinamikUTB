
## 8.8 Arquitectura de seguridad

Esta sección describe cómo se protege DinamikUTB, indicando qué existe hoy y qué está planificado. Se agrega al final de `08-cross-cutting-concepts.md`. El detalle de amenazas está en [`docs/modelado-de-amenazas.md`](../modelado-de-amenazas.md).

### Límites de confianza (según el C4 Nivel 2)

```text
 [Usuario] ──HTTP/JSON──▶ [Frontend Flutter] ──HTTP/JSON──▶ [Backend API FastAPI] ──SQLAlchemy──▶ [SQLite]
   (no confiable)              (no confiable)            ▲ frontera de confianza principal         (confiable)
```

El **Backend API** es la única frontera de confianza: todo lo que llega desde el frontend se considera no confiable y se valida y autoriza ahí, nunca en el cliente.

### Controles por capa

| Control | Mecanismo | Amenazas que cubre | Estado |
|---|---|---|---|
| Validación de entrada | Pydantic (`Literal` para el estado de un requisito) en `requisitos/schemas.py` | T-10 | **Implementado** |
| Consultas seguras | SQLAlchemy ORM con parámetros, sin SQL concatenado | T-10 | **Implementado** |
| Autenticación | JWT bearer; contraseñas con hash adaptativo ([ADR-0004](../adr/0004-autenticacion-y-control-de-acceso.md)) | T-03 | Planificado |
| Autorización | Dependencias por rol y por propietario del recurso en `usuarios/` | T-01, T-02 | Planificado |
| Cifrado en tránsito | HTTPS en el despliegue | T-04 | Aceptado en desarrollo |
| Política CORS | Orígenes explícitos por variable de entorno | T-07 | Pendiente |
| Gestión de secretos | Variables de entorno; ningún secreto en el repositorio | T-03 | Planificado |
| Protección de datos en reposo | `*.db` fuera del control de versiones; permisos mínimos | T-05 | Pendiente de verificar |
| Auditoría | Historial de cambios (A-08) | T-06 | Planificado (ADR-0005) |
| Dependencias | `pip-audit` en CI y Dependabot | T-08 | **Implementado** al fusionar el workflow |

### Reglas que deben mantenerse

* Ningún endpoint que lea o modifique datos académicos se publica sin la dependencia de autenticación.
* La comparación entre el usuario del token y el recurso solicitado ocurre en el backend, nunca en Flutter.
* Los secretos (clave de firma, futuras credenciales de base de datos) nunca se versionan; si se filtra uno, se rota de inmediato porque el historial de Git es público.
* Los datos personales tratados y su base se documentan en la sección 5 del modelo de amenazas.
