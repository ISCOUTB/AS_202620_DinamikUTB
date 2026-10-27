import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/curriculo/malla_screen.dart';
import 'package:frontend/curriculo/malla_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('la malla y sus prerrequisitos se adaptan a móvil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = ApiClient(
      baseUrl: 'https://example.test',
      tokenStorage: InMemoryTokenStorage(),
      client: MockClient((request) async {
        expect(request.url.path, '/malla');
        expect(
          request.url.queryParameters['programa'],
          'Ingeniería de Sistemas',
        );
        return http.Response(
          jsonEncode({
            'programa': 'Ingeniería de Sistemas',
            'plan': '201910',
            'creditos_totales': 162,
            'cursos': [
              {
                'codigo': 'CBAS-F01A',
                'nombre': 'Física Mecánica',
                'nivel': 2,
                'creditos': 4,
                'prerequisitos': ['CBAS-M01A', 'CBAS-M02A'],
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    final result = await MallaService(api).obtener('Ingeniería de Sistemas');
    expect(result.cursos, hasLength(1));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: MallaScreen(
            service: MallaService(api),
            programa: 'Ingeniería de Sistemas',
            semestreActual: 2,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Malla curricular'), findsOneWidget);
    expect(find.text('Física Mecánica'), findsOneWidget);
    expect(find.text('CBAS-M01A'), findsOneWidget);
    expect(find.text('CBAS-M02A'), findsOneWidget);
  });
}
