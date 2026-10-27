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

El código fuente permanece en GitHub. GitHub Actions construye la aplicación
Flutter y publica la imagen estática de Nginx en GitHub Container Registry
(GHCR). Dokploy descarga esa imagen y construye únicamente la API con
`deploy/compose.lab.yaml`; así el servidor del laboratorio no necesita descargar
ni compilar el SDK de Flutter.

El workflow `.github/workflows/publish-frontend-image.yml` publica una imagen
al hacer push a `master` cuando cambian archivos de `frontend/`. También puede
ejecutarse manualmente desde **GitHub → Actions → Publish frontend image →
Run workflow**.

Antes del primer build, crea en **GitHub → Settings → Secrets and variables →
Actions → Variables** la variable de repositorio:

```text
API_BASE_URL=https://api.dinamikutb.iscoutb.dev
```

La URL se incorpora al frontend compilado. Después de la primera publicación,
configura el paquete `as_202620_dinamikutb-frontend` de GHCR como **público**,
para que Dokploy pueda descargarlo sin credenciales. Si debe ser privado,
configura en Dokploy las credenciales de GHCR con permiso de solo lectura.

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
FRONTEND_IMAGE=ghcr.io/iscoutb/as_202620_dinamikutb-frontend:latest
CORS_ORIGINS=https://dinamikutb.iscoutb.dev
```

Completa también las variables obligatorias de PostgreSQL y seguridad siguiendo
`deploy/.env.example`. Genera valores seguros para contraseñas y `SECRET_KEY`;
guárdalos en Dokploy, no en el repositorio. `API_BASE_URL` se configura como
variable de GitHub Actions, no en Dokploy. `FRONTEND_IMAGE` indica qué imagen
descarga Dokploy.

### Pasos en Dokploy

1. Crea una aplicación Docker Compose conectada al repositorio de GitHub y a la
   rama de despliegue.
2. Indica como archivo Compose `deploy/compose.lab.yaml`.
3. Añade las variables de entorno necesarias, usando `deploy/.env.example`
   como referencia y sin copiar sus valores vacíos para los secretos.
4. Asigna `dinamikutb.iscoutb.dev` al servicio `web` en el puerto `80` y
   `api.dinamikutb.iscoutb.dev` al servicio `api` en el puerto `8000`.
5. Habilita HTTPS y despliega. Dokploy construirá la API y descargará el
   frontend publicado en GHCR.
6. Para cada actualización del frontend, espera a que el workflow
   **Publish frontend image** termine correctamente en GitHub Actions y luego
   pulsa **Redeploy** en Dokploy para descargar `latest`. No actives el
   despliegue automático de Dokploy por cada push: podría descargar la imagen
   anterior mientras GitHub Actions aún la está construyendo.
7. Si modificas `API_BASE_URL` en las variables de GitHub, ejecuta también
   manualmente **Publish frontend image** y después redepliega en Dokploy.

### Verificación

- `https://api.dinamikutb.iscoutb.dev/health` debe responder con estado `ok`.
- `https://dinamikutb.iscoutb.dev/health` debe responder `ok`.
- Abre `https://dinamikutb.iscoutb.dev`, inicia sesión y confirma que las
  peticiones del navegador van a `https://api.dinamikutb.iscoutb.dev` sin
  errores de CORS.

El workflow `.github/workflows/deploy-pages.yml` pertenece a la configuración
anterior de GitHub Pages. No lo ejecutes para este despliegue en Dokploy.
