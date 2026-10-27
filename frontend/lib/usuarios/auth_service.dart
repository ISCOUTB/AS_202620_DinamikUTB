import 'package:frontend/core/network/api_client.dart';
import 'models.dart';

class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  /// Inicia sesión y devuelve el token de acceso.
  Future<String> login(String email, String password) async {
    final data =
        await _api.post(
              '/auth/login',
              body: {'email': email.trim(), 'password': password},
              autenticado: false,
            )
            as Map<String, dynamic>;
    return data['access_token'] as String;
  }

  Future<Usuario> perfil() async {
    final data = await _api.get('/auth/me') as Map<String, dynamic>;
    return Usuario.fromJson(data);
  }

  Future<void> solicitarRecuperacion(String email) async {
    await _api.post(
      '/auth/password/recuperar',
      body: {'email': email.trim()},
      autenticado: false,
    );
  }

  Future<void> restablecerPassword(String token, String nueva) async {
    await _api.post(
      '/auth/password/restablecer',
      body: {'token': token, 'new_password': nueva},
      autenticado: false,
    );
  }

  Future<Usuario> actualizarPerfil({
    required String nombre,
    required String programa,
    required int semestre,
  }) async {
    final data =
        await _api.put(
              '/auth/mi-perfil',
              body: {
                'nombre': nombre,
                'programa': programa,
                'semestre': semestre,
              },
            )
            as Map<String, dynamic>;
    return Usuario.fromJson(data);
  }

  Future<void> cambiarPassword({
    required String actual,
    required String nueva,
  }) async {
    await _api.put(
      '/auth/password',
      body: {'current_password': actual, 'new_password': nueva},
    );
  }
}
