# 8. Cross-cutting Concepts

## 8.1 Lenguaje ubicuo

Términos del dominio compartidos entre el equipo, el código y la documentación, para que una palabra signifique lo mismo en todos los contextos. Complementa el glosario general (`docs/arc42/12-glossary.md`) con el vocabulario específico de contextos delimitados.

| Término | Significado dentro de DinamikUTB |
|---|---|
| **Contexto delimitado** (Bounded Context) | Frontera dentro de la cual un término del dominio tiene un significado único y consistente. En DinamikUTB, cada módulo (`usuarios/`, `estudiantes/`, `requisitos/`, `programas/`, `curriculo/`, `reportes/`, `ayuda/`) es un contexto delimitado. |
| **Núcleo compartido** (Shared Kernel) | Contexto cuya funcionalidad es consumida directamente por todos los demás, sin que ellos dupliquen su lógica. `usuarios/` cumple este rol: resuelve autenticación y rol una sola vez, reutilizada por el resto. |
| **Cliente / Proveedor** (Customer/Supplier) | Relación donde un contexto (cliente) consume datos o servicios de otro (proveedor), sin que el proveedor conozca al cliente. `requisitos/` es cliente de `estudiantes/` y `programas/`. |
| **Dueño único de datos** | Cada entidad de datos pertenece a exactamente un módulo, que es el único autorizado a escribirla. Los demás módulos que necesiten esa información la consultan a través del servicio del módulo dueño, nunca accediendo directo a su tabla. |

## 8.2 Mapa de contextos

```text
                         ┌────────────────┐
                         │   usuarios/    │
                         │ (núcleo        │
                         │  compartido)   │
                         └───────┬────────┘
                    consumido por│ (autenticación y rol)
              ┌──────────────────┼──────────────────┬──────────────┐
              ▼                  ▼                  ▼              ▼
     ┌────────────────┐ ┌────────────────┐ ┌────────────────┐ ┌──────────┐
     │  estudiantes/  │ │   programas/   │ │  requisitos/   │ │  ayuda/  │
     │  (proveedor)   │ │  (proveedor)   │ │   (cliente)    │ │          │
     └───────┬────────┘ └───────┬────────┘ └────────────────┘ └────┬─────┘
             │  cliente/proveedor │                                │
             └───────────────────┴───────────────►  requisitos/    │
                                                                    │
                                            consume datos de ───────┘
                                            estudiantes/ (solicitudes)
```

## 8.3 Estado de implementación por contexto

| Contexto | Diseñado desde | Código real |
|---|---|---|
| usuarios/ | S2 (ADR-0001) | Sí — modelo Usuario, PasswordResetToken, servicio (Argon2id, recuperación con token de un solo uso), routers y dependencias RBAC. |
| requisitos/ | S2 (ADR-0001) | Sí — modelo Requisito, catálogo por programa, servicio con with_for_update=True, historial transaccional RequisitoHistorial (ADR-0011). |
| estudiantes/ | S2 (ADR-0001) | Sí — modelo Estudiante, EstudianteHistorial (ADR-0014), servicios de consulta y actualización con auditoría. |
| programas/ | S2 (ADR-0001) | Sí — modelo Programa, administración de carreras y sincronización de renombre con estudiantes/. |
| curriculo/ | S2 (ADR-0001) | Sí — modelos PlanEstudio, Curso, prerrequisitos y servicio de carga curricular. |
| reportes/ | S2 (ADR-0001) | Sí — router de exportación CSV con saneamiento de celdas contra inyección de fórmulas. |
| ayuda/ | S2 (ADR-0001) | Pendiente — estructura de carpetas definida. |

## 8.4 Propiedad de datos por módulo

| Módulo (dueño) | Entidad | Ubicación en código | Lectura cruzada legítima |
|---|---|---|---|
| usuarios/ | Usuario, PasswordResetToken | backend/app/usuarios/ | Consumido vía dependencia CurrentUser. |
| requisitos/ | Requisito, RequisitoHistorial | backend/app/requisitos/ | Ninguno: operaciones internas del módulo. |
| estudiantes/ | Estudiante, EstudianteHistorial | backend/app/estudiantes/ | Leído por reportes/ y programas/ vía consultas específicas. |
| programas/ | Programa | backend/app/programas/ | Leído por curriculo/ y validadores de alta de estudiantes. |
| curriculo/ | PlanEstudio, Curso, curso_prerrequisitos | backend/app/curriculo/ | Solo lectura curricular vía servicio. |

## 8.5 Auditoría de propiedad de datos en el código

Verificación de operaciones de escritura (add, commit, .update) en el código de la aplicación:

- requisitos/service.py: Agrega y confirma Requisito y RequisitoHistorial en una sola transacción atómica.
- usuarios/service.py: Escribe Usuario y marca el uso atómico de PasswordResetToken.
- estudiantes/service.py: Escribe Estudiante y EstudianteHistorial atómicamente.
- programas/router.py: Escribe Programa. Ante renombre de programa, delega la actualización de los estudiantes al servicio dueño (actualizar_programa_masivo).
- curriculo/service.py: Puebla mallas curriculares y cursos pertenecientes a su catálogo.
- seed.py: Carga idempotente de datos demo para desarrollo.

## 8.6 C4 nivel 3 y ADR de reajuste

No aplica: los límites modulares se mantuvieron estables según lo definido en ADR-0001 y refinado en ADR-0014.

## 8.7 Correspondencia entre aspectos y contextos

- A-01 (Seguimiento de requisitos) → requisitos/
- A-02 (Cálculo de graduación) → requisitos/ (cliente), estudiantes/ y curriculo/ (proveedores)
- A-03 (Alertas tempranas) → requisitos/ (regla determinista en evaluación)
- A-04 (Disponibilidad) → Transversal (infraestructura y observabilidad)
- A-05 (Seguridad y control de acceso) → usuarios/
- A-06 (Extensibilidad multi-programa) → programas/ y curriculo/
- A-07 (Centro de ayuda) → ayuda/
- A-08 (Historial de cambios) → requisitos/ (ADR-0011) y estudiantes/ (ADR-0014)

## 8.8 Estrategia de consistencia

| # | Operación | Garantía | Mecanismo en código | Desfase aceptado y reconciliación | Prueba |
|---|---|---|---|---|---|
| 1 | PUT /requisitos/{id}/estado | Fuerte | with_for_update=True serializa escrituras por fila en PostgreSQL; un solo db.commit() confirma el estado y la fila de RequisitoHistorial (ADR-0011) | Última escritura gana; serializado por fila en la base (la prueba actual es secuencial) | test_idempotencia.py, test_historial.py |
| 2 | Historial de ese cambio (requisitos_historial) | Fuerte, atómico con la fila 1 | Misma transacción | Si falla el historial, el cambio no se aplica | test_historial.py::test_si_falla_el_historial... |
| 3 | Log auditoria_cambio_estado | Mejor esfuerzo (como máximo una vez) | logger.info después del commit | Puede perderse si el proceso muere entre commit y log; telemetría operativa | Sin prueba (telemetría) |
| 4 | GET /requisitos/{id} y GET /estudiantes/{codigo} | Fuerte por petición | Consulta directa a la base primaria | Ninguno | test_requisitos.py, test_estudiantes.py |
| 5 | GET /requisitos/{id}/resumen | Fuerte por petición | Un único GROUP BY (calcular_resumen) | Ninguno dentro de la petición | test_requisitos.py::test_resumen_... |
| 6 | Pantalla de inicio del estudiante (3 GET en paralelo) | Fuerte por petición, eventual entre peticiones | Future.wait en dashboard_screen.dart | Desfase transitorio si coincide con un PUT; se reconcilia al deslizar para recargar | Sin prueba (descrito) |
| 7 | POST /auth/login | Fuerte por fila | autenticar actualiza intentos_fallidos y confirma | intentos_fallidos += 1 acotado por limitador IP | test_auth.py |
| 8 | Limitador de login por IP | Mejor esfuerzo, volátil | LimitadorVentana en memoria | Se reinicia ante reinicio de instancia | test_auth.py::test_login_limita_el_ritmo_por_ip |
| 9 | Autorización en cada petición | Fuerte | get_current_user lee Usuario de la base en cada request | Desactivar un usuario es inmediato. El cambio de contraseña invalida sesiones anteriores de inmediato (/auth/me devuelve 401). Cerrar sesión solo destruye el token local en el cliente (JWT expira en 30 min) | test_auth.py, test_account_management.py |
| 10 | Creación de usuarios y arranque (seed.py) | Idempotente por tabla | Inserta solo si las tablas están vacías | Fallo a medias se completa en el siguiente arranque | seed.py |
| 11 | Referencias entre módulos (Requisito.estudiante_id → Estudiante) | Por convención | Sin FK entre módulos; el endpoint POST /estudiantes valida existencia de programa y dominio de correo | Reconciliado por validación administrativa en la creación | test_account_management.py |
| 12 | GET /metrics | Mejor esfuerzo, volátil | Contadores en memoria con cerrojo | Se reinician con el proceso | test_health.py |
| 13 | POST /estudiantes | Fuerte por fila, eventual entre ambas | Crea Estudiante y Usuario (inactivo) en dos inserciones | Si la segunda falla, puede quedar un estudiante sin usuario; la exportación CSV lo mitiga con INNER JOIN | test_account_management.py |
| 14 | PUT /programas/{id} (con renombre) | Fuerte | Un solo commit actualiza Programa, ejecuta actualizar_programa_masivo y genera EstudianteHistorial | Consistencia inmediata en la misma transacción; referencia por nombre reconciliada atómicamente | test_account_management.py |
| 15 | POST /requisitos/catalogo | Fuerte | Crea el requisito en catálogo y lo asocia a los estudiantes del programa en un solo commit | Todo o nada en la asignación masiva | test_account_management.py |
| 16 | POST /auth/password/restablecer | Fuerte | update(usado_en=ahora).filter(usado_en.is_(None)) atómico | Previene doble consumo concurrente del enlace; falla con error si ya fue usado | test_account_management.py |
| 17 | GET /reportes/estudiantes.csv | Fuerte por petición | INNER JOIN entre Estudiante, Usuario y Requisito | Refleja el estado de la base al momento de ejecutar la consulta | test_account_management.py |

## 8.9 Estrategia de caché

Decisión: no hay caché de datos de dominio en el servidor.

Respuestas HTTP marcadas con Cache-Control: no-store para proteger datos académicos personales.

La latencia en la base local o del laboratorio es menor a 5 ms; el cuello de botella previo era el spin down de Render, el cual quedó eliminado al migrar al laboratorio (ADR-0012).

Inventario de copias en el cliente e invalidación:

- Escritura propia vía gestión de requisitos: GestionRequisitosScreen reemplaza el item modificado con el payload de respuesta del PUT.
- Escritura propia vía edición de perfil: Al actualizar nombre, programa o semestre (PUT /auth/mi-perfil), AuthGate detecta la mutación mediante una ValueKey('${usuario.nombre}|${usuario.programa}|${usuario.semestre}') que destruye y recrea DashboardScreen y MallaScreen, forzando la recarga inmediata de los datos.
- Escritura ajena (otro coordinador actualiza): El estudiante ve los datos anteriores en memoria hasta que desliza hacia abajo para refrescar (pull-to-refresh) o reabre la aplicación.

## 8.10 Eventos y mensajería

La integración es síncrona vía HTTP/JSON (ADR-0004).

No existe broker de mensajería (sin Kafka ni RabbitMQ).

Efectos externos (SMTP): El servicio de correo de recuperación actúa bajo garantía de mejor esfuerzo / como máximo una vez. Si el host SMTP no responde o no está configurado, la API responde inmediatamente HTTP 503 y no encola reintentos en segundo plano.

## 8.11 Decisión de datos más costosa de revertir

El mecanismo de historial de cambios transaccional (ADR-0011), extendido a los datos académicos del estudiante en el ADR-0014, dado que el pasado no se puede reconstruir si no se captura atómicamente en el instante de la mutación.
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

