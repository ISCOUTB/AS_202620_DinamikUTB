/// Validaciones de entrada para los formularios de la aplicación.
abstract final class Validators {
  static final _email = RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$');
  static final _codigo = RegExp(r'^[A-Za-z0-9]{4,20}$');

  static String? email(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'Ingresa tu correo';
    if (texto.length > 254 || !_email.hasMatch(texto)) return 'Correo no válido';
    return null;
  }

  static String? password(String? valor) {
    final texto = valor ?? '';
    if (texto.isEmpty) return 'Ingresa tu contraseña';
    if (texto.length < 8) return 'Mínimo 8 caracteres';
    if (texto.length > 128) return 'Máximo 128 caracteres';
    return null;
  }

  static String? codigoEstudiantil(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'Ingresa el código estudiantil';
    if (!_codigo.hasMatch(texto)) return 'Solo letras y números (4 a 20 caracteres)';
    return null;
  }
}
