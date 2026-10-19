import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class RequisitosService {
  RequisitosService({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 25),
    this.maxIntentos = 3,
    this.esperaBase = const Duration(seconds: 2),
  }) : client = client ?? http.Client();

  final String baseUrl;
  final http.Client client;

  /// Tiempo máximo de espera por intento. Con el arranque en frío de Render
  /// (~1 min, ADR-0005), 3 intentos de 25 s cubren la reactivación.
  final Duration timeout;

  /// Número total de intentos (el primero más los reintentos).
  final int maxIntentos;

  /// Espera antes del primer reintento; se duplica en cada reintento (2 s, 4 s...).
  final Duration esperaBase;

  /// Consulta idempotente (GET): es seguro reintentarla.
  /// Reintenta ante timeout, falla de conexión y respuestas 5xx.
  /// No reintenta ante 4xx: un error del cliente no se arregla repitiendo.
  Future<List<Requisito>> obtenerRequisitos(String estudianteId) async {
    final uri = Uri.parse('$baseUrl/requisitos/$estudianteId');

    for (var intento = 1; intento <= maxIntentos; intento++) {
      try {
        final response = await client.get(uri).timeout(timeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as List<dynamic>;
          return data
              .map((item) => Requisito.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        if (response.statusCode < 500) {
          throw Exception('No se pudo cargar los requisitos');
        }
        // 5xx: cae al reintento.
      } on TimeoutException {
        // Sin respuesta a tiempo: cae al reintento.
      } on http.ClientException {
        // Falla de conexión: cae al reintento.
      }

      if (intento < maxIntentos) {
        await Future<void>.delayed(esperaBase * (1 << (intento - 1)));
      }
    }

    throw Exception('No se pudo cargar los requisitos');
  }
}
