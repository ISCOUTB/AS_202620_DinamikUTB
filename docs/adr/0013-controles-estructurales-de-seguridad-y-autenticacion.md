---
id: ADR-0013
title: Controles estructurales de seguridad, autenticación y control de acceso
status: Aceptado
date: 2026-11-01
deciders: Equipo de arquitectura DinamikUTB
---

# ADR-0013: Controles estructurales de seguridad, autenticación y control de acceso

![Status: Aceptado](https://img.shields.io/badge/Status-Accepted-brightgreen?style=flat-square)
![Date: 2026--11--01](https://img.shields.io/badge/Date-2026--11--01-blue?style=flat-square)
![Scope: Security](https://img.shields.io/badge/Scope-Security-orange?style=flat-square)

---

## 1. Contexto y descripción del problema

DinamikUTB administra información académica personal de estudiantes universitarios y estados de cumplimiento de requisitos de grado. En fases tempranas ([ADR-0005](0005-plataforma-despliegue-backend.md)), la API operaba sin autenticación en endpoints de lectura y actualización.

Con el despliegue del sistema y la exposición pública de la API ([ADR-0012](0012-despliegue-en-servidor-del-laboratorio.md)), se identificaron amenazas críticas de suplantación de identidad (T-01), escalamiento de privilegios (T-03) y fuerza bruta (T-05), que amenazaban el atributo de calidad [Q-02](../arc42/10-quality-requirements.md) (seguridad y aislamiento). Se requería una solución estructural e integrada en el monolito modular.

---

## 2. Factores de decisión

| Factor | Justificación |
|---|---|
| **Aislamiento por rol (RBAC)** | Los estudiantes solo deben ver su propio avance; coordinadores y administradores tienen alcances diferenciados. |
| **Resistencia criptográfica** | Contraseñas protegidas contra ataques de diccionario y colisiones mediante algoritmos modernos resistentes a GPUs. |
| **Invalidación inmediata de sesiones** | Cambiar la contraseña debe revocar de inmediato tokens activos previos. |
| **Defensa contra fuerza bruta** | Mitigar ataques automatizados sin comprometer la disponibilidad en despliegues con recursos acotados. |
| **Compatibilidad con arquitectura modular** | Inyección de dependencias transversal sin acoplar la lógica de dominio de cada módulo. |

---

## 3. Alternativas consideradas

### 3.1 Sesiones tradicionales con cookies de servidor y almacenamiento en Redis
- *Desventajas:* Requiere desplegar y mantener un contenedor Redis adicional, rompiendo el presupuesto de memoria de 512 MB del laboratorio.

### 3.2 Servicio de identidad externo (OAuth2 / Auth0 / Firebase Auth)
- *Desventajas:* Dependencia de terceros con costos asociados y salida de datos personales fuera de la infraestructura universitaria.

### 3.3 Autenticación stateless por JWT con firma de contraseña e inyección de dependencias FastAPI
- *Ventajas:* Sin infraestructura adicional; validación descentralizada; firma de token ligada al hash de contraseña para invalidación instantánea; control de roles reutilizable vía dependencias.
- *Seleccionada.*

---

## 4. Decisión

Se implementa una arquitectura estructural de seguridad con los siguientes componentes:

1. **Hash de contraseñas:** Implementación de **Argon2id** (RFC 9106) en `backend/app/core/security.py`, exigiendo contraseñas de al menos 12 caracteres.
2. **Tokens de acceso JWT stateless con revocación:** Tokens firmados con clave simétrica HS256 (mínimo 32 caracteres) y expiración de 30 minutos. El payload incluye la firma `sig` calculada con los últimos 16 caracteres del hash de la contraseña (`usuario.password_hash[-16:]`). Si el usuario cambia la contraseña, el token previo queda revocado de inmediato.
3. **Control de acceso por roles (RBAC):** Dependencias inyectables en FastAPI (`CurrentUser`, `GestorUser`, `AdminUser`) y función `verificar_acceso_estudiante` que impide que un estudiante consulte datos ajenos.
4. **Limitador de tasa (Rate Limiting):** Clase `LimitadorVentana` en memoria que restringe el inicio de sesión a 10 intentos por minuto por dirección IP, combinado con bloqueo temporal de cuenta tras 5 fallos.
5. **Cabeceras de protección HTTP:** Middleware en `backend/app/main.py` inyectando `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Cache-Control: no-store` y `Strict-Transport-Security`.
6. **Defensa contra inyección de fórmulas CSV:** Sanitización de caracteres peligrosos (`=`, `+`, `-`, `@`) en la exportación de reportes.

---

## 5. Consecuencias

### Positivas
- Se mitigan las amenazas críticas T-01, T-02, T-03, T-04 y T-05 sin añadir dependencias de infraestructura como Redis.
- Cumplimiento total de Q-02 (100 % de accesos no autorizados rechazados).
- Los tokens antiguos no sobreviven a cambios de credenciales.

### Negativas
- El limitador de tasa reside en memoria: si el contenedor se reinicia, el contador de intentos por IP se reinicia (riesgo aceptado en arc42 §11.1).

---

## 6. Trazabilidad

| Elemento | Referencia |
|---|---|
| **Aspectos sustentados** | [A-05](../aspectos.md#a-05--protección-y-control-de-acceso-a-la-información-académica) |
| **Escenario de calidad** | [Q-02](../arc42/10-quality-requirements.md#escenario-q-02--seguridad-y-aislamiento-de-la-información) |
| **Código** | `backend/app/core/security.py`, `backend/app/usuarios/dependencies.py`, `backend/app/core/rate_limit.py` |
| **Pruebas** | `backend/tests/test_auth.py`, `backend/tests/test_seguridad.py`, `backend/tests/test_account_management.py` |
