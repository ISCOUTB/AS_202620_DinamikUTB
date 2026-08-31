
# 6. Runtime View

Esta sección describe cómo colaboran los bloques definidos en `05-building-block-view.md` durante los escenarios de ejecución más relevantes para **DinamikUTB**. Se priorizaron los escenarios que sustentan directamente los escenarios de calidad **[Q-01](./10-quality-requirements.md/#escenario-q-01--exactitud-de-la-informacion-academica)**, **[Q-02](./10-quality-requirements.md/#escenario-q-02--seguridad-y-aislamiento-de-la-informacion)** y **[Q-03](./10-quality-requirements.md/#escenario-q-03--facilidad-de-comprension-de-la-informacion)** (`10-quality-requirements.md`), en lugar de documentar todos los casos de uso posibles.

---

## 6.1 Escenario: Estudiante consulta su progreso de graduación

Relacionado con **[RF-01](../arc42/01-introduction-and-goals.md/#funcionalidades-principales)**, **[RF-02](../arc42/01-introduction-and-goals.md/#funcionalidades-principales)** y los escenarios **Q-01** (exactitud) y **Q-03** (usabilidad).

1. El estudiante abre la aplicación (Flutter) e inicia sesión con correo y contraseña.
2. El módulo `usuarios/` del frontend envía las credenciales al backend.
3. El módulo `usuarios/` del backend valida las credenciales y devuelve un token de sesión.
4. El frontend redirige automáticamente a la pantalla principal del módulo `estudiantes/` (sin pasos intermedios, según la táctica de usabilidad de la sección 4.8.1).
5. El frontend solicita al backend el progreso del estudiante autenticado.
6. La petición pasa primero por la dependencia de autenticación de `usuarios/`, que resuelve el `student_id` a partir del token.
7. El módulo `requisitos/` del backend calcula el estado de cada requisito y el porcentaje de avance a partir de la información de `estudiantes/` y `programas/`.
8. El backend responde con el estado de los requisitos y el porcentaje de avance.
9. El frontend muestra el resultado en la pantalla principal, marcando explícitamente los estados de carga, error o listo (táctica de Q-03).

> Todo el cálculo del paso 7 ocurre en un único lugar (`requisitos/`), por lo que el frontend nunca recalcula el porcentaje de avance por su cuenta; esto es lo que permite verificar Q-01 con pruebas de backend únicamente.

---

## 6.2 Escenario: Control de acceso a información académica

Relacionado con **[RF-05](../arc42/01-introduction-and-goals.md/#funcionalidades-principales)** y el escenario **Q-02** (seguridad).

1. Un usuario autenticado solicita la información de un estudiante específico (por ejemplo, `GET /estudiantes/{id}/requisitos`).
2. La dependencia de autenticación de `usuarios/` verifica que el token sea válido; si no lo es, el backend responde `401` sin llegar a `requisitos/`.
3. Si el token es válido, la dependencia de autorización dentro de `requisitos/` compara el `id` solicitado contra el `student_id` del token (si el solicitante es un estudiante) o contra el programa asignado (si es coordinador).
4. Si el solicitante no tiene permiso sobre ese recurso, el backend responde `403` (o `404`, según lo que se decida al implementar) sin exponer datos de otro estudiante.
5. Si el solicitante tiene permiso, la petición continúa hacia el cálculo descrito en el escenario 6.1.

> Este escenario es el que se verifica con los 20 intentos de acceso (autorizados y no autorizados) de Q-02, usando FastAPI TestClient.

---

## 6.3 Escenario: Coordinador corrige un requisito reportado por un estudiante

Relacionado con **[RF-07](../arc42/01-introduction-and-goals.md/#funcionalidades-principales)** 

1. El estudiante detecta una inconsistencia y envía una solicitud desde el módulo `ayuda/` del frontend.
2. El módulo `ayuda/` del backend registra la solicitud asociada al estudiante y su estado (`pendiente`).
3. El coordinador consulta las solicitudes pendientes de su programa desde `ayuda/`, filtradas por la dependencia de autorización de `usuarios/`.
4. El coordinador revisa la información en `requisitos/` y, si corresponde, actualiza uno o varios campos del requisito.
5. La actualización se ejecuta dentro de una única transacción en `requisitos/`; si alguna escritura falla a mitad de camino, la transacción se revierte y el requisito conserva su último estado válido (para no dejarlo a medio actualizar).
6. El módulo `ayuda/` marca la solicitud como `resuelta` y queda registrada en el historial de cambios (RF-08).



---

## 6.4 Notas sobre alcance

- Los tres escenarios anteriores cubren los flujos que sustentan Q-01, Q-02 y Q-03, en esta sección deberá ampliarse con los runtime scenarios correspondientes.
- Ningún escenario aquí descrito depende de un sistema externo, en línea con los límites definidos en `03-context-and-scope.md` .
 