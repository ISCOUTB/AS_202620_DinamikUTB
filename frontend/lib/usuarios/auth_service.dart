import '../core/network/api_client.dart';
import 'models.dart';

class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  /// Inicia sesión y devuelve el token de acceso.
  Future<String> login(String email, String password) async {
    final data = await _api.post(
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
      autenticado: false,
    ) as Map<String, dynamic>;
    return data['access_token'] as String;
  }

  Future<Usuario> perfil() async {
    final data = await _api.get('/auth/me') as Map<String, dynamic>;
    return Usuario.fromJson(data);
  }
}
