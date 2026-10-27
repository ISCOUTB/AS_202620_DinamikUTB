# DinamikUTB

Frontend web para consultar y gestionar requisitos de grado. Está desarrollado
con Flutter y consume la API del proyecto.

## Requisitos

- Flutter y Dart según las restricciones indicadas en `pubspec.yaml`.
- La API backend en ejecución para iniciar sesión y cargar información.

## Desarrollo local

Desde esta carpeta, en PowerShell:

```powershell
flutter pub get
flutter run -d chrome
```

La app usa `http://127.0.0.1:8000` como URL predeterminada del backend. Para usar
otra URL:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Verificación

```powershell
flutter analyze
flutter test
```

## Despliegue en el laboratorio (Dokploy)

El código fuente permanece en GitHub. Dokploy obtiene el repositorio y construye
el frontend y la API usando `deploy/compose.lab.yaml`; el sitio web se sirve
desde el contenedor Nginx definido en `frontend/Dockerfile`.

No necesitas crear registros DNS si el laboratorio ya asignó estos dominios al
proyecto. En Dokploy, vincula cada dominio al servicio y puerto interno
correspondiente:

| Servicio | Dominio | Puerto interno |
| --- | --- | --- |
| `web` | `dinamikutb.iscoutb.dev` | `80` |
| `api` | `api.dinamikutb.iscoutb.dev` | `8000` |

Confirma que el laboratorio haya provisionado ambos nombres. Un registro DNS
comodín `*.iscoutb.dev` por sí solo normalmente cubre
`dinamikutb.iscoutb.dev`, pero no garantiza
`api.dinamikutb.iscoutb.dev`; si Dokploy no acepta el dominio de la API, solicita
al laboratorio que lo asigne o usa el hostname que proporcione para ese
servicio.

Activa HTTPS en Dokploy para ambos dominios. No publiques el servicio `db`.

En las variables de entorno de Dokploy, configura como mínimo:

```env
API_BASE_URL=https://api.dinamikutb.iscoutb.dev
CORS_ORIGINS=https://dinamikutb.iscoutb.dev
```

Completa también las variables obligatorias de PostgreSQL y seguridad siguiendo
`deploy/.env.example`. Genera valores seguros para contraseñas y `SECRET_KEY`;
guárdalos en Dokploy, no en el repositorio. `API_BASE_URL` no es un secreto: se
incorpora al frontend durante la construcción de la imagen. Si cambia, vuelve a
construir y desplegar `web`.

### Pasos en Dokploy

1. Crea una aplicación Docker Compose conectada al repositorio de GitHub y a la
   rama de despliegue.
2. Indica como archivo Compose `deploy/compose.lab.yaml`.
3. Añade las variables de entorno necesarias, usando `deploy/.env.example`
   como referencia y sin copiar sus valores vacíos para los secretos.
4. Asigna `dinamikutb.iscoutb.dev` al servicio `web` en el puerto `80` y
   `api.dinamikutb.iscoutb.dev` al servicio `api` en el puerto `8000`.
5. Habilita HTTPS y despliega. Si el laboratorio ofrece despliegue automático,
   actívalo para que los cambios publicados en GitHub se reconstruyan.

### Verificación

- `https://api.dinamikutb.iscoutb.dev/health` debe responder con estado `ok`.
- `https://dinamikutb.iscoutb.dev/health` debe responder `ok`.
- Abre `https://dinamikutb.iscoutb.dev`, inicia sesión y confirma que las
  peticiones del navegador van a `https://api.dinamikutb.iscoutb.dev` sin
  errores de CORS.

El workflow `.github/workflows/deploy-pages.yml` pertenece a la configuración
anterior de GitHub Pages. No lo ejecutes para este despliegue en Dokploy.
