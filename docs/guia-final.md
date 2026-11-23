# Guia final — DinamikUTB

## 1. Sistema entregado

DinamikUTB es un sistema integrado para consultar y gestionar el proceso de graduacion
universitaria. El backend es un monolito modular en FastAPI y el frontend es una
aplicacion Flutter desplegada en GitHub Pages. PostgreSQL 16 corre en el servidor
institucional mediante Dokploy y persiste datos en un volumen `pgdata`.

La demostracion debe recorrer al menos:

1. Inicio de sesion con estudiante y con gestor.
2. Consulta de progreso curricular y requisitos.
3. Actualizacion de un requisito o curso por el gestor.
4. Consulta de una solicitud de ayuda.
5. Validacion de una ruta protegida sin credenciales.
6. Consulta de `/health` y comportamiento ante una ruta inexistente.

URLs actuales:

- Frontend: https://iscoutb.github.io/AS_202620_DinamikUTB/
- API: https://api-dinamikutb.iscoutb.dev
- Health: https://api-dinamikutb.iscoutb.dev/health

En produccion la documentacion interactiva y OpenAPI no se publican. `/metrics`
tambien esta protegido o deshabilitado segun `METRICS_TOKEN`; no debe presentarse
como una ruta publica.

## 2. Alcance y respuesta al desafio

No existe un desafio final nuevo asignado al equipo en el repositorio. Por ello no
se afirma una implementacion cuantificada de un reto que no fue asignado.

El alcance actual sigue cuatro ejes:

- Seguimiento de requisitos y progreso curricular.
- Autenticacion, roles y trazabilidad historica.
- Gestion de programas, reportes y solicitudes de ayuda.
- Despliegue integrado y observabilidad basica.

Aspectos declarados pero limitados:

- Las alertas tempranas no tienen todavia disparo ni implementacion completa.
- El catalogo completo cubre la malla real de Ingenieria de Sistemas; los demas
  programas requieren completar sus datos.
- El historial transaccional esta implementado, pero no existe un endpoint general
  para consultar todo el historial.
- El volumen PostgreSQL requiere una tarea automatica de respaldo antes de
  considerar el despliegue apto para produccion institucional.

## 3. Evidencias para la sustentacion

| Tema | Evidencia |
|---|---|
| Arquitectura | ARC42 secciones 1 a 12 y C4 contexto, contenedores y componentes |
| Evolucion | ADR 0001 a 0016 |
| Calidad | Pruebas backend 101 casos en la revision local |
| Seguridad | RBAC, JWT, validacion Pydantic, pruebas de aislamiento y STRIDE |
| Despliegue | Dokploy, PostgreSQL 16, GitHub Pages y `/health` |
| Trazabilidad | `docs/aspectos.md` y contratos OpenAPI versionados |
| Riesgos | `docs/arc42/11-risks-and-technical-debt.md` |

El equipo debe reconocer que el cierre aun tiene el job SonarCloud en rojo.
Las pruebas backend y frontend pasaron, pero no se presenta el proyecto como
100 % verde hasta resolver el Quality Gate y registrar el run exitoso.

## 4. Preguntas contrafactuales

- ¿Que ocurre si PostgreSQL deja de responder cinco minutos?
- ¿Que pasa si multiplicamos la carga por diez o llegan 100 usuarios simultaneos?
- ¿Que cambiaria si se reemplaza Dokploy por otro proveedor?
- ¿Como se recuperarian los datos si el volumen `pgdata` se pierde sin respaldo?
- ¿Que ocurre si SMTP falla durante una recuperacion de contraseña?
- ¿Que pasa si el modulo de ayuda se usa con coordinadores de varios programas?
