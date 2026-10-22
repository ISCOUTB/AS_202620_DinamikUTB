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

## Build de producción y GitHub Pages

El backend de producción se configura con `API_BASE_URL`. Para publicar en la
ruta del repositorio definida por el proyecto:

```powershell
flutter build web --release --base-href /AS_202620_DinamikUTB/ --dart-define=API_BASE_URL=https://dinamikutb-api.onrender.com
```

El contenido generado queda en `build/web`. Para más contexto sobre variables
de entorno y despliegue, consulta la decisión
`../docs/adr/0006-plataforma-despliegue-frontend.md`.
