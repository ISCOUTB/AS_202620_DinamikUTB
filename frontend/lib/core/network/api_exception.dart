class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  /// Mensaje que puede mostrarse al usuario.
  final String message;
  final int? statusCode;

  bool get esNoAutorizado => statusCode == 401;

  @override
  String toString() => message;
}
