import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/storage/token_storage.dart';
import 'auth_service.dart';
import 'models.dart';

enum AuthStatus { desconocido, noAutenticado, autenticado }

class AuthController extends ChangeNotifier {
  AuthController({required this._service, required this._storage});

  final AuthService _service;
  final TokenStorage _storage;

  AuthStatus status = AuthStatus.desconocido;
  Usuario? usuario;

  /// Valida el token guardado al iniciar la aplicación.
  Future<void> restaurarSesion() async {
    final token = await _storage.read();
    if (token == null) {
      _cambiar(AuthStatus.noAutenticado, null);
      return;
    }
    try {
      _cambiar(AuthStatus.autenticado, await _service.perfil());
    } on ApiException catch (e) {
      if (e.esNoAutorizado) await _storage.clear();
      _cambiar(AuthStatus.noAutenticado, null);
    }
  }

  /// Lanza [ApiException] si el inicio de sesión falla.
  Future<void> iniciarSesion(String email, String password) async {
    final token = await _service.login(email, password);
    await _storage.write(token);
    try {
      _cambiar(AuthStatus.autenticado, await _service.perfil());
    } on ApiException {
      await _storage.clear();
      rethrow;
    }
  }

  Future<void> cerrarSesion() async {
    await _storage.clear();
    _cambiar(AuthStatus.noAutenticado, null);
  }

  void _cambiar(AuthStatus nuevo, Usuario? usuarioNuevo) {
    status = nuevo;
    usuario = usuarioNuevo;
    notifyListeners();
  }
}
