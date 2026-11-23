
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/administracion/service/admin_service.dart';
import 'package:frontend/administracion/widgets/student_edit_dialog.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const program = {
    'id': 1,
    'codigo': 'IS-01',
    'nombre': 'Ingeniería de Sistemas',
    'facultad': 'Ingeniería',
    'duracion_semestres': 10,
    'activo': true,
    'estudiantes_asociados': 1,
  };

  const student = AdminStudent(
    id: 1,
    codigo: 'T1234567',
    nombre: 'Estudiante Original',
    email: 'estudiante@dinamikutb.dev',
    programa: 'Ingeniería de Sistemas',
    semestre: 3,
    activo: true,
  );

  Map<String, dynamic> studentResponse({
    String nombre = 'Estudiante Actualizado',
    String email = 'estudiante@dinamikutb.dev',
    int semestre = 4,
    bool activo = false,
  }) {
    return {
      'id': 1,
      'codigo_estudiantil': 'T1234567',
      'nombre': nombre,
      'email': email,
      'programa': 'Ingeniería de Sistemas',
      'semestre': semestre,
      'activo': activo,
    };
  }

  Finder dialogTitle() {
    return find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Editar estudiante'),
    );
  }

  Future<void> openDialog(
    WidgetTester tester,
    AdminService service,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                StudentEditDialog.show(
                  context,
                  service: service,
                  student: student,
                );
              },
              child: const Text('Abrir edición'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir edición'));
    await tester.pumpAndSettle();
  }

  testWidgets('carga los datos y actualiza correctamente un estudiante', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var updateRequestCount = 0;

    final api = ApiClient(
      baseUrl: 'https://example.test',
      tokenStorage: InMemoryTokenStorage(),
      client: MockClient((request) async {
        if (request.url.path == '/programas') {
          return http.Response(
            jsonEncode([program]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (request.url.path ==
                '/estudiantes/T1234567/administrativo' &&
            request.method == 'PUT') {
          updateRequestCount++;

          final body = jsonDecode(request.body) as Map<String, dynamic>;

          expect(body['nombre'], 'Estudiante Actualizado');
          expect(body['email'], 'estudiante@dinamikutb.dev');
          expect(body['codigo_estudiantil'], 'T1234567');
          expect(body['programa'], 'Ingeniería de Sistemas');
          expect(body['semestre'], 4);
          expect(body['activo'], false);

          return http.Response(
            jsonEncode(
              studentResponse(
                semestre: 4,
                activo: false,
              ),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        return http.Response('{}', 404);
      }),
    );

    var updated = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                updated =
                    await StudentEditDialog.show(
                      context,
                      service: AdminService(api),
                      student: student,
                    ) ??
                    false;
              },
              child: const Text('Abrir edición'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir edición'));
    await tester.pumpAndSettle();

    expect(dialogTitle(), findsOneWidget);
    expect(find.text('Estudiante Original'), findsOneWidget);
    expect(find.text('T1234567'), findsOneWidget);
    expect(find.text('Ingeniería de Sistemas'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombres completos'),
      'Estudiante Actualizado',
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Semestre actual'),
      '4',
    );

    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();

    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(updated, isTrue);
    expect(updateRequestCount, 1);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra errores cuando los datos no son válidos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final api = ApiClient(
      baseUrl: 'https://example.test',
      tokenStorage: InMemoryTokenStorage(),
      client: MockClient((request) async {
        if (request.url.path == '/programas') {
          return http.Response(
            jsonEncode([program]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        return http.Response('{}', 404);
      }),
    );

    await openDialog(tester, AdminService(api));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombres completos'),
      'AB',
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Semestre actual'),
      '13',
    );

    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa el nombre completo.'), findsOneWidget);
    expect(find.text('Semestre entre 1 y 12.'), findsOneWidget);
    expect(dialogTitle(), findsOneWidget);
  });

  testWidgets('muestra el formulario sin selección si no hay programas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final api = ApiClient(
      baseUrl: 'https://example.test',
      tokenStorage: InMemoryTokenStorage(),
      client: MockClient((request) async {
        if (request.url.path == '/programas') {
          return http.Response(
            jsonEncode([]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        return http.Response('{}', 404);
      }),
    );

    await openDialog(tester, AdminService(api));

    expect(dialogTitle(), findsOneWidget);
    expect(find.text('Programa académico'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permite cancelar la edición', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final api = ApiClient(
      baseUrl: 'https://example.test',
      tokenStorage: InMemoryTokenStorage(),
      client: MockClient((request) async {
        if (request.url.path == '/programas') {
          return http.Response(
            jsonEncode([program]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        return http.Response('{}', 404);
      }),
    );

    var result = true;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result =
                    await StudentEditDialog.show(
                      context,
                      service: AdminService(api),
                      student: student,
                    ) ??
                    false;
              },
              child: const Text('Abrir edición'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir edición'));
    await tester.pumpAndSettle();

    expect(dialogTitle(), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('muestra el error cuando falla la actualización', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final api = ApiClient(
      baseUrl: 'https://example.test',
      tokenStorage: InMemoryTokenStorage(),
      client: MockClient((request) async {
        if (request.url.path == '/programas') {
          return http.Response(
            jsonEncode([program]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (request.method == 'PUT') {
          return http.Response(
            jsonEncode({'detail': 'No se pudo actualizar el estudiante'}),
            400,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        return http.Response('{}', 404);
      }),
    );

    await openDialog(tester, AdminService(api));

    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(dialogTitle(), findsOneWidget);
    expect(find.textContaining('No se pudo actualizar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
