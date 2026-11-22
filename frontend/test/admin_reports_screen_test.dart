
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/administracion/admin_reports_screen.dart';
import 'package:frontend/administracion/service/admin_service.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/token_storage.dart';
import 'package:http/http.dart' as http;

class ClienteReportesFalso extends http.BaseClient {
  final bool errorResumen;
  final bool errorExportacion;

  ClienteReportesFalso({
    this.errorResumen = false,
    this.errorExportacion = false,
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;

    if (path.contains('estadisticas/resumen')) {
      if (errorResumen) {
        return http.StreamedResponse(
          Stream.value(utf8.encode('{"detail":"Error del servidor"}')),
          500,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.StreamedResponse(
        Stream.value(
          utf8.encode(
            jsonEncode({
              'por_programa': {
                'Ingeniería de Sistemas': 20,
                'Ingeniería Industrial': 10,
              },
              'por_semestre': {
                '1': 10,
                '2': 20,
              },
              'estados_requisitos': {
                'completado': 15,
                'pendiente': 5,
              },
              'total_estudiantes': 30,
              'porcentaje_cumplimiento': 75,
              'estudiantes_proximos_grado': 4,
            }),
          ),
        ),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    if (path.contains('/reportes/estudiantes.csv')) {
      if (errorExportacion) {
        return http.StreamedResponse(
          Stream.value(utf8.encode('{"detail":"Error de exportación"}')),
          500,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.StreamedResponse(
        Stream.value(utf8.encode('codigo,nombre\n2024001,Ana Perez')),
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

class AlmacenTokensFalso implements TokenStorage {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> clear() async {}
}

AdminService crearServicio({
  bool errorResumen = false,
  bool errorExportacion = false,
}) {
  final api = ApiClient(
    tokenStorage: AlmacenTokensFalso(),
    client: ClienteReportesFalso(
      errorResumen: errorResumen,
      errorExportacion: errorExportacion,
    ),
  );

  return AdminService(api);
}

void main() {
  group('AdminReportsScreen', () {
    testWidgets('muestra los indicadores del reporte', (tester) async {
      await tester.view.setPhysicalSize(const Size(1400, 1200));
      await tester.view.setDevicePixelRatio(1);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminReportsScreen(service: crearServicio()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Reportes y estadísticas'), findsOneWidget);
      expect(find.text('Estudiantes por programa'), findsOneWidget);
      expect(find.text('Distribución por semestre'), findsOneWidget);
      expect(find.text('Estado de requisitos'), findsOneWidget);
      expect(find.textContaining('30 estudiantes'), findsOneWidget);
      expect(find.textContaining('75%'), findsOneWidget);
      expect(find.text('Descargar reporte CSV'), findsOneWidget);
    });

    testWidgets('muestra el indicador de carga inicialmente', (
      tester,
    ) async {
      final servicio = crearServicio();

      await tester.pumpWidget(
        MaterialApp(
          home: AdminReportsScreen(service: servicio),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('muestra el estado de error si falla el resumen', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminReportsScreen(
            service: crearServicio(errorResumen: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('permite reintentar la carga del reporte', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminReportsScreen(
            service: crearServicio(errorResumen: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Reintentar'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('permite solicitar la descarga del CSV', (
      tester,
    ) async {
      await tester.view.setPhysicalSize(const Size(1400, 1200));
      await tester.view.setDevicePixelRatio(1);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminReportsScreen(service: crearServicio()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Descargar reporte CSV'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('descarga'), findsOneWidget);
    });
  });
}
