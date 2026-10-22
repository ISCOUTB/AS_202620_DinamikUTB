import 'package:flutter/foundation.dart';

/// URL del backend, configurable durante la compilación:
///   flutter build web --dart-define=API_BASE_URL=https://dinamikutb-api.onrender.com
/// Por defecto apunta al backend local.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

/// Exige HTTPS en compilaciones de producción.
void validarConfiguracion() {
  if (kReleaseMode && !apiBaseUrl.startsWith('https://')) {
    throw StateError('API_BASE_URL debe usar https:// en builds de producción.');
  }
}
