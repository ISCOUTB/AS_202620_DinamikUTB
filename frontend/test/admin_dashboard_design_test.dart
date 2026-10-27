import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/administracion/admin_panel_screen.dart';
import 'package:frontend/administracion/service/admin_service.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/core/theme/app_theme.dart';

void main() {
  testWidgets('el panel admin muestra estudiantes reales sin desbordar móvil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = ApiClient(
      baseUrl: 'https://example.test',
      tokenStorage: InMemoryTokenStorage(),
      client: MockClient((request) async {
        if (request.url.path == '/estudiantes/estadisticas/resumen') {
          return http.Response(
            jsonEncode({
              'total_estudiantes': 12,
              'total_programas': 2,
              'estudiantes_proximos_grado': 3,
              'requisitos_pendientes': 4,
              'porcentaje_cumplimiento': 75,
              'por_programa': {'Sistemas': 8, 'Industrial': 4},
              'por_semestre': {'6': 5, '8': 7},
              'estados_requisitos': {'cumplido': 20, 'pendiente': 4},
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path == '/estudiantes') {
          return http.Response(
            jsonEncode([
              {
                'id': 1,
                'codigo_estudiantil': 'T00012345',
                'nombre': 'Estudiante reciente',
                'email': 'estudiante@dinamikutb.dev',
                'programa': 'Ingeniería de Sistemas',
                'semestre': 6,
                'activo': true,
              },
            ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('{}', 404);
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminPanelScreen(
          email: 'admin@dinamikutb.dev',
          onLogout: () {},
          service: AdminService(api),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Estudiantes recientes'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Estudiantes recientes'), findsOneWidget);
    expect(find.text('Estudiante reciente'), findsOneWidget);
    expect(find.textContaining('T00012345'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
