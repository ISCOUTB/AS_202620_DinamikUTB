
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/administracion/admin_programs_screen.dart';
import 'package:frontend/administracion/service/admin_service.dart';

class ClienteProgramasFalso extends http.BaseClient {
  ClienteProgramasFalso(this.respuesta, [this.statusCode = 200]);

  final String respuesta;
  final int statusCode;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode(respuesta)),
      statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}

ApiClient crearApi(String respuesta, [int status = 200]) {
  return ApiClient(
    baseUrl: 'http://127.0.0.1:8000',
    tokenStorage: InMemoryTokenStorage(),
    client: ClienteProgramasFalso(respuesta, status),
  );
}

const programaJson = '''
[
  {
    "id": 1,
    "codigo": "ISC",
    "nombre": "Ingeniería de Sistemas",
    "facultad": "Facultad de Ingeniería",
    "duracion_semestres": 10,
    "activo": true,
    "estudiantes_asociados": 120
  }
]
''';

void main() {
  testWidgets('Muestra los programas académicos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminProgramsScreen(
            service: AdminService(crearApi(programaJson)),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ingeniería de Sistemas'), findsOneWidget);
    expect(find.text('ISC'), findsOneWidget);
    expect(find.text('Facultad de Ingeniería'), findsOneWidget);
    expect(find.text('Activo'), findsOneWidget);
    expect(find.text('Crear programa'), findsOneWidget);
  });

  testWidgets('Muestra un mensaje cuando el catálogo está vacío', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminProgramsScreen(
            service: AdminService(crearApi('[]')),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('El catálogo está vacío'), findsOneWidget);
  });

  testWidgets('Muestra un error cuando falla la consulta', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminProgramsScreen(
            service: AdminService(crearApi('{"detail":"Error de prueba"}', 500)),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('Abre el formulario para crear un programa', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminProgramsScreen(
            service: AdminService(crearApi('[]')),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear programa'));
    await tester.pumpAndSettle();

    expect(find.text('Nombre del programa'), findsOneWidget);
    expect(find.text('Código del programa'), findsOneWidget);
    expect(find.text('Facultad o departamento'), findsOneWidget);
    expect(find.text('Duración en semestres'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
  });

  testWidgets('Abre el formulario para editar un programa', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminProgramsScreen(
            service: AdminService(crearApi(programaJson)),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar programa'));
    await tester.pumpAndSettle();

    expect(find.text('Editar programa'), findsOneWidget);
    expect(find.text('Programa activo'), findsOneWidget);
    expect(find.text('Ingeniería de Sistemas'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
  });
}
