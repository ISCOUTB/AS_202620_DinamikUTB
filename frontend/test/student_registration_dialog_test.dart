import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/administracion/service/admin_service.dart';
import 'package:frontend/administracion/widgets/student_registration_dialog.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('coordinación registra estudiantes desde la API', (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var createRequestCount = 0;
    final api = ApiClient(
      baseUrl: 'https://example.test',
      tokenStorage: InMemoryTokenStorage(),
      client: MockClient((request) async {
        if (request.url.path == '/programas') {
          return http.Response(
            jsonEncode([
              {
                'id': 1,
                'codigo': 'IS-01',
                'nombre': 'Ingeniería de Sistemas',
                'facultad': 'Ingeniería',
                'duracion_semestres': 10,
                'activo': true,
                'estudiantes_asociados': 0,
              },
            ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path == '/estudiantes' && request.method == 'POST') {
          createRequestCount++;
          expect(
            jsonDecode(request.body),
            containsPair('email', 'estudiante@dinamikutb.dev'),
          );
          return http.Response(
            jsonEncode({
              'id': 2,
              'codigo_estudiantil': 'T1234567',
              'nombre': 'Estudiante Nuevo',
              'email': 'estudiante@dinamikutb.dev',
              'programa': 'Ingeniería de Sistemas',
              'semestre': 1,
              'activo': false,
            }),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('{}', 404);
      }),
    );

    var created = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                created =
                    await StudentRegistrationDialog.show(
                      context,
                      AdminService(api),
                    ) ??
                    false;
              },
              child: const Text('Nuevo registro'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Nuevo registro'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombres completos'),
      'Estudiante Nuevo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo institucional'),
      'estudiante@dinamikutb.dev',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Código estudiantil'),
      'T1234567',
    );
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    expect(created, isTrue);
    expect(createRequestCount, 1);
    expect(tester.takeException(), isNull);
  });
}
