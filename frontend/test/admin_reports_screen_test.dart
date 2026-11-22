import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/administracion/admin_reports_screen.dart';
import 'package:frontend/administracion/service/admin_service.dart';

class ClienteReportesFalso extends http.BaseClient {
  bool fallarResumen;
  bool fallarExportacion;

  ClienteReportesFalso({
    this.fallarResumen = false,
    this.fallarExportacion = false,
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.path.contains('estadisticas/resumen')) {
      if (fallarResumen) {
        return http.StreamedResponse(
          Stream.value(utf8.encode('{"detail":"Error interno"}')),
          500,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.StreamedResponse(
        Stream.value(
          utf8.encode('''
          {
            "por_programa": {
              "Ingeniería de Sistemas": 20,
              "Ingeniería Industrial": 10
            },
            "por_semestre": {
              "1": 5,
              "2": 8,
              "3": 12
            },
            "estados_requisitos": {
              "Completado": 15,
              "Pendiente": 5
            },
            "total_estudiantes": 30,
            "porcentaje_cumplimiento": 75,
            "estudiantes_proximos_grado": 4
          }
          '''),
        ),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    if (request.url.path.contains('estudiantes.csv')) {
      if (fallarExportacion) {
        return http.StreamedResponse(
          Stream.value(utf8.encode('{"detail":"Error al exportar"}')),
          500,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.StreamedResponse(
        Stream.value(utf8.encode('id,nombre\n1,Ana')),
        200,
        headers: {'content-type': 'text/csv'},
      );
    }

    return http.StreamedResponse(
      Stream.value(utf8.encode('{}')),
      404,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  group('AdminReportsScreen', () {
    testWidgets('muestra las estadísticas del reporte', (tester) async {
      final cliente = ClienteReportesFalso();

      final servicio = AdminService(
        ApiClient(
          baseUrl: 'http://127.0.0.1:8000',
          tokenStorage: InMemoryTokenStorage(),
          client: cliente,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminReportsScreen(service: servicio),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Reportes y estadísticas'), findsOneWidget);
      expect(find.text('Estudiantes por programa'), findsOneWidget);
      expect(find.text('Distribución por semestre'), findsOneWidget);
      expect(find.text('Estado de requisitos'), findsOneWidget);
      expect(find.textContaining('Total: 30 estudiantes'), findsOneWidget);
      expect(find.textContaining('Cumplimiento: 75%'), findsOneWidget);
      expect(find.textContaining('Próximos a grado: 4'), findsOneWidget);
    });

    testWidgets('muestra un error cuando falla la consulta', (tester) async {
      final cliente = ClienteReportesFalso(fallarResumen: true);

      final servicio = AdminService(
        ApiClient(
          baseUrl: 'http://127.0.0.1:8000',
          tokenStorage: InMemoryTokenStorage(),
          client: cliente,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminReportsScreen(service: servicio),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('permite reintentar la consulta de estadísticas',
        (tester) async {
      final cliente = ClienteReportesFalso(fallarResumen: true);

      final servicio = AdminService(
        ApiClient(
          baseUrl: 'http://127.0.0.1:8000',
          tokenStorage: InMemoryTokenStorage(),
          client: cliente,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminReportsScreen(service: servicio),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Reintentar'), findsOneWidget);

      cliente.fallarResumen = false;

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Reportes y estadísticas'), findsOneWidget);
      expect(find.textContaining('Total: 30 estudiantes'), findsOneWidget);
    });

    testWidgets('muestra el aviso al descargar desde una plataforma no web',
        (tester) async {
      final cliente = ClienteReportesFalso();

      final servicio = AdminService(
        ApiClient(
          baseUrl: 'http://127.0.0.1:8000',
          tokenStorage: InMemoryTokenStorage(),
          client: cliente,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminReportsScreen(service: servicio),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Descargar reporte CSV'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'La descarga solo está disponible desde el navegador web.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('muestra un aviso cuando falla la exportación',
        (tester) async {
      final cliente = ClienteReportesFalso(fallarExportacion: true);

      final servicio = AdminService(
        ApiClient(
          baseUrl: 'http://127.0.0.1:8000',
          tokenStorage: InMemoryTokenStorage(),
          client: cliente,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminReportsScreen(service: servicio),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Descargar reporte CSV'));
      await tester.pumpAndSettle();

      expect(
        find.text('El servidor no está disponible. Intenta más tarde.'),
        findsOneWidget,
      );
    });
  });
}
