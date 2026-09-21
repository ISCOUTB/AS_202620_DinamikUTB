import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/requisitos/requisitos_screen.dart';
import 'package:frontend/requisitos/requisitos_service.dart';

class ClienteFalso extends http.BaseClient {
  ClienteFalso(this._respuesta, this._statusCode);

  final String _respuesta;
  final int _statusCode;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = utf8.encode(_respuesta);
    return http.StreamedResponse(
      Stream.value(bytes),
      _statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}

void main() {
  testWidgets('Muestra los requisitos del estudiante', (WidgetTester tester) async {
    final respuestaJson = jsonEncode([
      {'id': 1, 'nombre': 'Inglés B2', 'estado': 'pendiente'},
      {'id': 2, 'nombre': 'Práctica profesional', 'estado': 'cumplido'},
    ]);

    final service = RequisitosService(
      baseUrl: 'http://127.0.0.1:8000',
      client: ClienteFalso(respuestaJson, 200),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RequisitosScreen(service: service, estudianteId: 'T000123456'),
      ),
    );

    // Mientras carga, se muestra el indicador de progreso.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    // Una vez cargado, aparecen los dos requisitos con su estado.
    expect(find.text('Inglés B2'), findsOneWidget);
    expect(find.text('pendiente'), findsOneWidget);
    expect(find.text('Práctica profesional'), findsOneWidget);
    expect(find.text('cumplido'), findsOneWidget);
  });

  testWidgets('Muestra un mensaje cuando no hay requisitos', (WidgetTester tester) async {
    final service = RequisitosService(
      baseUrl: 'http://127.0.0.1:8000',
      client: ClienteFalso('[]', 200),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RequisitosScreen(service: service, estudianteId: 'T999999999'),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No tienes requisitos registrados.'), findsOneWidget);
  });
}
