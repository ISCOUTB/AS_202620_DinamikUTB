---
id: ADR-0004
title: Autenticación con tokens y control de acceso por rol y propietario
status: Propuesto
date: 2026-11-01
deciders: Equipo de arquitectura DinamikUTB
---

# ADR-0004: Autenticación con tokens y control de acceso por rol y propietario

![Status: Propuesto](https://img.shields.io/badge/Status-Proposed-yellow?style=flat-square)
![Scope: Security](https://img.shields.io/badge/Scope-Security-orange?style=flat-square)

---

## 1. Contexto y descripción del problema

El modelado de amenazas de la semana 13 ([modelado-de-amenazas.md](../modelado-de-amenazas.md)) encontró que los endpoints actuales no tienen autenticación:

* **T-01:** `PUT /requisitos/{id}/estado` permite a cualquiera cambiar el estado de un requisito.
* **T-02:** `GET /requisitos/{estudiante_id}` y `GET /estudiantes/{codigo}` permiten leer datos de cualquier estudiante.
* **T-03:** el módulo `usuarios/` (previsto desde el [ADR-0001](0001-seleccion-monolito-modular.md)) no tiene código.

La táctica ya está descrita en `04-solution-strategy.md` §4.8.1 (Q-02): autenticación como dependencia inyectable de FastAPI, comparación de `student_id` contra el recurso y roles resueltos desde `usuarios/`. Este ADR formaliza los detalles porque **cambia la estructura**: añade una entidad, una dependencia compartida entre módulos y una configuración de secretos.

## 2. Factores de decisión

| Factor | Descripción |
| :--- | :--- |
| **Cierre de T-01/T-02** | Debe cubrir los dos riesgos de mayor prioridad con una sola pieza. |
| **Sin sistemas externos** | El alcance excluye integración con sistemas institucionales (`03-context-and-scope.md` §3.4): la autenticación es propia. |
| **Compatibilidad con el monolito modular** | Debe vivir en `usuarios/` y reutilizarse por los demás módulos sin duplicar lógica. |
| **Testabilidad** | Debe poder probarse con FastAPI TestClient (Q-02: 20 intentos). |
| **Secretos fuera del repositorio** | La clave de firma no puede estar versionada. |

## 3. Alternativas consideradas

### 3.1 Tokens JWT firmados (bearer)
* **Ventajas:** sin estado en el servidor, encaja con el frontend Flutter y con una dependencia `Depends(...)`; fácil de probar.
* **Desventajas:** la revocación es más difícil; exige expiración corta y gestión de la clave.

### 3.2 Sesiones en servidor (cookie)
* **Ventajas:** revocación inmediata.
* **Desventajas:** requiere almacén de sesiones y manejo de CSRF; menos natural para un cliente Flutter multiplataforma.

### 3.3 Inicio de sesión institucional (OAuth/SSO de la UTB)
* **Ventajas:** no se almacenan contraseñas.
* **Desventajas:** contradice la restricción de no integrar sistemas institucionales en la primera versión y el proyecto no tiene acceso a ellos.

### 3.4 Clave de API compartida
* **Desventajas:** no identifica al usuario, por lo que no puede resolver T-02; descartada.

## 4. Decisión

Se adopta **JWT bearer con contraseñas almacenadas con hash adaptativo (argon2 o bcrypt)**, implementado en `backend/app/usuarios/`:

1. **Entidad `Usuario`** (correo, hash de contraseña, rol, y para estudiantes su `codigo_estudiantil`) en `usuarios/models.py`. Las cuentas las crea el administrador, sin registro público (`02-architecture-constraints.md` §2.2).
2. **Dependencia `usuario_actual`** (`usuarios/dependencies.py`) que valida el token y devuelve identidad y rol; responde 401 si falta o es inválido.
3. **Dependencias de autorización:**
   * `requerir_rol("coordinador", "administrador")` para `PUT /requisitos/{id}/estado` (cierra T-01).
   * `requerir_propietario` para los `GET` por estudiante: el estudiante solo accede a su propio código; el coordinador, a estudiantes de su programa (cierra T-02). Respuesta 403, o 404 para no revelar la existencia del recurso.
4. **Secreto de firma** en variable de entorno (`DINAMIK_JWT_SECRET`), nunca en el repositorio; expiración corta del token (por ejemplo, 30 minutos).
5. **Regla de módulos:** los demás módulos solo importan las dependencias de `usuarios/`, nunca su tabla (coherente con `08-cross-cutting-concepts.md` §8.1 y §8.5).

## 5. Consecuencias

### Positivas
* Cierra T-01, T-02 y T-03, y da base a Q-02 y A-05.
* La autorización queda en un único punto reutilizable.
* Permite que el historial (A-08, futuro ADR-0005) registre el usuario responsable de cada cambio.

### Negativas
* Se añade una dependencia criptográfica (que debe pasar por `pip-audit`).
* Se debe gestionar la clave de firma en cada entorno.
* Los tests existentes de `requisitos/` y `estudiantes/` deberán enviar un token.
* La revocación inmediata de tokens no está soportada en esta primera versión.

## 6. Relación con atributos de calidad

| Atributo | Relación |
| :--- | :--- |
| **Seguridad** | Principal beneficiado: Q-02. |
| **Exactitud / Consistencia** | Solo roles autorizados modifican el estado de un requisito (Q-01). |
| **Trazabilidad** | Habilita identificar al autor de un cambio (Q-08). |
| **Usabilidad** | El inicio de sesión añade un paso; se mantiene la táctica de redirigir directamente a la pantalla de progreso (§4.8.1, Q-03). |
| **Rendimiento** | Verificar un JWT es una operación local y barata. |

## 7. Estado de la decisión

**Propuesto.** Pasa a **Aceptado** cuando el equipo lo revise. La implementación está **pendiente**; hasta entonces T-01 y T-02 permanecen abiertas en el modelo de amenazas.

## 8. Trazabilidad

| Elemento | Referencia |
| :--- | :--- |
| **Aspectos que sustenta** | [A-05](../aspectos.md#a-05--protección-y-control-de-acceso-a-la-información-académica), [A-08](../aspectos.md#a-08--historial-de-cambios-sobre-la-información-académica) (parcial) |
| **Escenarios de calidad** | [Q-02](../arc42/10-quality-requirements.md#escenario-q-02--seguridad-y-aislamiento-de-la-información) |
| **Amenazas que mitiga** | T-01, T-02, T-03, T-11 |
| **Elemento C4** | Contenedor `Backend API` en `docs/c4/contenedores.puml` |
| **Commits / pruebas** | Pendientes; las pruebas esperadas son los 20 intentos de Q-02 con TestClient. |
