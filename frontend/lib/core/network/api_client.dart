import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Centraliza las peticiones, la autenticación, el timeout y los errores HTTP.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required TokenStorage tokenStorage,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  })  : _tokens = tokenStorage,
        _client = client ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final TokenStorage _tokens;
  final http.Client _client;

  /// Se invoca cuando una petición autenticada recibe un 401.
  void Function()? onUnauthorized;

  Future<dynamic> get(String path) => _enviar('GET', path);

  Future<dynamic> post(String path, {Object? body, bool autenticado = true}) =>
      _enviar('POST', path, body: body, autenticado: autenticado);

  Future<dynamic> put(String path, {Object? body}) =>
      _enviar('PUT', path, body: body);

  Future<dynamic> _enviar(
    String metodo,
    String path, {
    Object? body,
    bool autenticado = true,
  }) async {
    final request = http.Request(metodo, Uri.parse('$baseUrl$path'))
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (autenticado) {
      final token = await _tokens.read();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
    }

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw const ApiException('No se pudo conectar con el servidor.');
    }
    return _procesar(response, autenticado);
  }

  dynamic _procesar(http.Response response, bool autenticado) {
    final cuerpo = response.bodyBytes.isEmpty ? null : _decodificar(response);
    if (response.statusCode >= 200 && response.statusCode < 300) return cuerpo;
    if (response.statusCode == 401 && autenticado) onUnauthorized?.call();
    throw ApiException(
      _mensaje(response.statusCode, cuerpo),
      statusCode: response.statusCode,
    );
  }

  dynamic _decodificar(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }

  String _mensaje(int status, dynamic cuerpo) {
    // Los errores 5xx usan un mensaje genérico.
    if (status < 500 && cuerpo is Map && cuerpo['detail'] is String) {
      return cuerpo['detail'] as String;
    }
    return switch (status) {
      401 => 'Tu sesión expiró. Inicia sesión de nuevo.',
      403 => 'No tienes permisos para esta acción.',
      404 => 'No se encontró la información solicitada.',
      422 => 'Los datos enviados no son válidos.',
      429 => 'Demasiados intentos. Espera un momento.',
      _ when status >= 500 => 'El servidor no está disponible. Intenta más tarde.',
      _ => 'No se pudo completar la solicitud.',
    };
  }
}
