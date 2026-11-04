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

## Despliegue

El frontend se publica exclusivamente con GitHub Pages mediante
`.github/workflows/deploy-pages.yml`.

La aplicación se despliega en:

```text
https://iscoutb.github.io/AS_202620_DinamikUTB/
```

El workflow compila Flutter con `--base-href /AS_202620_DinamikUTB/` y usa
`https://api.dinamikutb.iscoutb.dev` como backend.

Antes del primer despliegue, configura en GitHub
**Settings → Secrets and variables → Actions → Variables**:

```text
API_BASE_URL=https://api.dinamikutb.iscoutb.dev
```

La API se despliega por separado en Dokploy. Configura únicamente los servicios
`api` y `db` con `deploy/compose.lab.yaml`, vincula el dominio
`api.dinamikutb.iscoutb.dev` al puerto interno `8000` y habilita HTTPS.
No publiques el servicio `db`.

En Dokploy, configura como mínimo:

```env
CORS_ORIGINS=https://iscoutb.github.io
```

Completa las demás variables obligatorias de PostgreSQL y seguridad usando
`deploy/.env.example`. Los secretos deben permanecer en Dokploy.

### Verificación

- Abre `https://iscoutb.github.io/AS_202620_DinamikUTB/`.
- `https://api.dinamikutb.iscoutb.dev/health` debe responder con estado `ok`.
- Inicia sesión y confirma que el navegador usa el dominio API sin errores CORS.
