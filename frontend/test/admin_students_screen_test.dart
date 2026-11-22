import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/administracion/admin_students_screen.dart';
import 'package:frontend/administracion/service/admin_service.dart';
import 'package:frontend/requisitos/requisitos_service.dart';

class ClienteFalso extends http.BaseClient {
  ClienteFalso(this.respuesta, [this.statusCode = 200]);

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
    client: ClienteFalso(respuesta, status),
  );
}

Widget crearPantalla({
  required AdminService adminService,
  required RequisitosService requisitosService,
}) {
  return MultiProvider(
    providers: [
      Provider<RequisitosService>.value(value: requisitosService),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Material(
          child: AdminStudentsScreen(
            service: adminService,
            initialSearch: '',
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('AdminStudentsScreen', () {
    // Función auxiliar para configurar una pantalla grande antes de cada test
    Future<void> configurarPantallaGrande(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset); // Restablece el tamaño al terminar
    }

    testWidgets('muestra el estado vacío cuando no hay estudiantes', (tester) async {
      await configurarPantallaGrande(tester);
      
      final api = crearApi('[]');
      final admin = AdminService(api);
      final requisitos = RequisitosService(
        crearApi('{"total":0,"cumplidos":0,"en_proceso":0,"pendientes":0,"porcentaje_avance":0}'),
      );

      await tester.pumpWidget(
        crearPantalla(adminService: admin, requisitosService: requisitos),
      );
      await tester.pumpAndSettle();

      expect(find.text('No se encontraron estudiantes'), findsOneWidget);
      expect(find.text('Ajusta los filtros o registra un nuevo estudiante.'), findsOneWidget);
    });

    testWidgets('muestra los estudiantes recibidos del servicio', (tester) async {
      await configurarPantallaGrande(tester);

      final api = crearApi('''
[
  {
    "id": 1,
    "codigo_estudiantil": "2024001",
    "nombre": "Ana Pérez",
    "email": "ana@utb.edu.co",
    "programa": "Ingeniería de Sistemas",
    "semestre": 5,
    "activo": true
  }
]
''');

      final admin = AdminService(api);
      final requisitos = RequisitosService(
        crearApi('{"total":0,"cumplidos":0,"en_proceso":0,"pendientes":0,"porcentaje_avance":0}'),
      );

      await tester.pumpWidget(
        crearPantalla(adminService: admin, requisitosService: requisitos),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('2024001'), findsOneWidget);
      expect(find.text('ana@utb.edu.co'), findsOneWidget);
      expect(find.textContaining('Ingeniería de Sistemas'), findsWidgets);
    });

    testWidgets('permite escribir en el buscador', (tester) async {
      await configurarPantallaGrande(tester);

      final api = crearApi('[]');
      final admin = AdminService(api);
      final requisitos = RequisitosService(
        crearApi('{"total":0,"cumplidos":0,"en_proceso":0,"pendientes":0,"porcentaje_avance":0}'),
      );

      await tester.pumpWidget(
        crearPantalla(adminService: admin, requisitosService: requisitos),
      );
      await tester.pumpAndSettle();

      final buscador = find.byType(TextField);
      expect(buscador, findsOneWidget);

      await tester.enterText(buscador, 'Ana');
      expect(find.text('Ana'), findsOneWidget);
    });

    testWidgets('muestra el botón para registrar estudiantes', (tester) async {
      await configurarPantallaGrande(tester);

      final api = crearApi('[]');
      final admin = AdminService(api);
      final requisitos = RequisitosService(
        crearApi('{"total":0,"cumplidos":0,"en_proceso":0,"pendientes":0,"porcentaje_avance":0}'),
      );

      await tester.pumpWidget(
        crearPantalla(adminService: admin, requisitosService: requisitos),
      );
      await tester.pumpAndSettle();

      expect(find.text('Registrar estudiante'), findsOneWidget);
    });

    testWidgets('muestra error cuando falla la consulta de estudiantes', (tester) async {
      await configurarPantallaGrande(tester);

      final api = crearApi('{"detail":"Error interno"}', 500);
      final admin = AdminService(api);
      final requisitos = RequisitosService(
        crearApi('{"total":0,"cumplidos":0,"en_proceso":0,"pendientes":0,"porcentaje_avance":0}'),
      );

      await tester.pumpWidget(
        crearPantalla(adminService: admin, requisitosService: requisitos),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reintentar'), findsOneWidget);
    });
  });
}
