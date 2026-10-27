import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token, {bool persist = true});
  Future<void> clear();
}

/// Usa el almacén seguro de la plataforma; en web, almacenamiento cifrado del navegador.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _clave = 'access_token';
  final FlutterSecureStorage _storage;
  String? _sessionToken;

  @override
  Future<String?> read() async => _sessionToken ?? await _storage.read(key: _clave);

  @override
  Future<void> write(String token, {bool persist = true}) async {
    if (persist) {
      _sessionToken = null;
      await _storage.write(key: _clave, value: token);
    } else {
      _sessionToken = token;
      await _storage.delete(key: _clave);
    }
  }

  @override
  Future<void> clear() async {
    _sessionToken = null;
    await _storage.delete(key: _clave);
  }
}

/// Almacén en memoria para pruebas.
class InMemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token, {bool persist = true}) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
