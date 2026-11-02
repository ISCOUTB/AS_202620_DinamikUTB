import 'package:flutter/foundation.dart';

/// URL del backend, configurable durante la compilación:
///   flutter build web --dart-define=API_BASE_URL=https://api.dinamikutb.iscoutb.dev
/// Por defecto apunta al dominio público del API del Plan A.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.dinamikutb.iscoutb.dev',
);

/// Exige HTTPS en compilaciones de producción.
void validarConfiguracion() {
  if (kReleaseMode && !apiBaseUrl.startsWith('https://')) {
    throw StateError('API_BASE_URL debe usar https:// en builds de producción.');
  }
}
