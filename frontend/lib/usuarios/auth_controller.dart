import 'package:flutter/foundation.dart';

import 'package:frontend/core/network/api_exception.dart';
import 'package:frontend/core/storage/token_storage.dart';
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
  Future<void> iniciarSesion(
    String email,
    String password, {
    bool recordar = false,
  }) async {
    final token = await _service.login(email, password);
    await _storage.write(token, persist: recordar);
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

  Future<void> solicitarRecuperacion(String email) =>
      _service.solicitarRecuperacion(email);

  Future<void> restablecerPassword(String token, String password) =>
      _service.restablecerPassword(token, password);

  Future<void> actualizarPerfil({
    required String nombre,
    required String programa,
    required int semestre,
  }) async {
    _cambiar(
      AuthStatus.autenticado,
      await _service.actualizarPerfil(
        nombre: nombre,
        programa: programa,
        semestre: semestre,
      ),
    );
  }

  Future<void> cambiarPassword({
    required String actual,
    required String nueva,
  }) async {
    await _service.cambiarPassword(actual: actual, nueva: nueva);
    await cerrarSesion();
  }

  void _cambiar(AuthStatus nuevo, Usuario? usuarioNuevo) {
    status = nuevo;
    usuario = usuarioNuevo;
    notifyListeners();
  }
}
