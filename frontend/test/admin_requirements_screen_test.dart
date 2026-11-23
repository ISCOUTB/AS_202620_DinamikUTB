
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/administracion/admin_requirements_screen.dart';
import 'package:frontend/administracion/service/admin_service.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';

import 'helpers/fake_admin_api.dart';

Map<String, dynamic> programa() => {
  'id': 1,
  'codigo': 'SIS',
  'nombre': 'Ingeniería de Sistemas',
  'facultad': 'Ingeniería',
  'duracion_semestres': 10,
  'activo': true,
  'estudiantes_asociados': 20,
};

Map<String, dynamic> requisito({
  int id = 1,
  String nombre = 'Prácticas profesionales',
  String descripcion = 'Completar las prácticas',
  bool obligatorio = true,
  bool activo = true,
}) => {
  'id': id,
  'programa_id': 1,
  'programa': 'Ingeniería de Sistemas',
  'nombre': nombre,
  'descripcion': descripcion,
  'semestre_recomendado': 8,
  'obligatorio': obligatorio,
  'activo': activo,
};

void main() {
  late FakeAdminApiClient client;
  late AdminService service;

  Future<void> abrirPantalla(
    WidgetTester tester, {
    required dynamic Function(dynamic request) handler,
  }) async {
    client = FakeAdminApiClient((request) => handler(request));

    final api = ApiClient(
      baseUrl: 'http://localhost',
      tokenStorage: InMemoryTokenStorage(),
      client: client,
    );

    service = AdminService(api);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminRequirementsScreen(service: service),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('muestra los requisitos del catálogo', (tester) async {
    await abrirPantalla(
      tester,
      handler: (request) {
        if (request.url.path == '/requisitos/catalogo') {
          return [requisito()];
        }
        return [];
      },
    );

    expect(find.text('Requisitos de grado'), findsOneWidget);
    expect(find.text('Prácticas profesionales'), findsOneWidget);
    expect(find.textContaining('Ingeniería de Sistemas'), findsOneWidget);
    expect(find.textContaining('Obligatorio'), findsOneWidget);
  });

  testWidgets('muestra estado vacío cuando no existen requisitos', (
    tester,
  ) async {
    await abrirPantalla(
      tester,
      handler: (request) => [],
    );

    expect(find.text('No hay requisitos en el catálogo'), findsOneWidget);
  });

  testWidgets('muestra error al fallar la consulta del catálogo', (
    tester,
  ) async {
    await abrirPantalla(
      tester,
      handler: (request) {
        if (request.url.path == '/requisitos/catalogo') {
          return const FakeApiResponse(
            {'detail': 'Error de catálogo'},
            statusCode: 500,
          );
        }
        return [];
      },
    );

    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('permite cancelar la creación de un requisito', (
    tester,
  ) async {
    await abrirPantalla(
      tester,
      handler: (request) {
        if (request.url.path == '/requisitos/catalogo') {
          return [];
        }
        if (request.url.path == '/programas/administracion') {
          return [programa()];
        }
        return [];
      },
    );

    await tester.tap(find.text('Crear requisito'));
    await tester.pumpAndSettle();

    expect(find.text('Nombre del requisito'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Crear requisito'), findsOneWidget);
    expect(
      client.requests.any((request) => request.method == 'POST'),
      isFalse,
    );
  });

  testWidgets('valida los campos obligatorios del formulario', (
    tester,
  ) async {
    await abrirPantalla(
      tester,
      handler: (request) {
        if (request.url.path == '/requisitos/catalogo') {
          return [];
        }
        if (request.url.path == '/programas/administracion') {
          return [];
        }
        return [];
      },
    );

    await tester.tap(find.text('Crear requisito'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Completa este campo.'), findsNWidgets(2));
    expect(find.text('Crea primero un programa.'), findsOneWidget);
  });

  testWidgets('crea un requisito y envía los datos al servidor', (
    tester,
  ) async {
    await abrirPantalla(
      tester,
      handler: (request) {
        if (request.url.path == '/requisitos/catalogo') {
          if (request.method == 'POST') {
            return requisito(nombre: 'Trabajo de grado');
          }
          return [];
        }
        if (request.url.path == '/programas/administracion') {
          return [programa()];
        }
        return [];
      },
    );

    await tester.tap(find.text('Crear requisito'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del requisito'),
      'Trabajo de grado',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descripción'),
      'Presentar el proyecto final',
    );

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final post = client.requests.firstWhere(
      (request) => request.method == 'POST',
    );

    expect(post.url.path, '/requisitos/catalogo');
    expect(post.body, contains('Trabajo de grado'));
    expect(post.body, contains('Presentar el proyecto final'));
  });

  testWidgets('permite editar un requisito existente', (tester) async {
    await abrirPantalla(
      tester,
      handler: (request) {
        if (request.url.path == '/requisitos/catalogo') {
          return [requisito()];
        }
        if (request.url.path == '/programas/administracion') {
          return [programa()];
        }
        if (request.url.path == '/requisitos/catalogo/1' &&
            request.method == 'PUT') {
          return requisito(nombre: 'Prácticas actualizadas');
        }
        return [];
      },
    );

    await tester.tap(find.byTooltip('Editar requisito'));
    await tester.pumpAndSettle();

    expect(find.text('Editar requisito'), findsOneWidget);
    expect(find.text('Requisito activo'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del requisito'),
      'Prácticas actualizadas',
    );

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(
      client.requests.any(
        (request) =>
            request.method == 'PUT' &&
            request.url.path == '/requisitos/catalogo/1',
      ),
      isTrue,
    );
  });

  testWidgets('muestra error si falla el guardado', (tester) async {
    await abrirPantalla(
      tester,
      handler: (request) {
        if (request.url.path == '/requisitos/catalogo') {
          if (request.method == 'POST') {
            return const FakeApiResponse(
              {'detail': 'No se pudo guardar'},
              statusCode: 400,
            );
          }
          return [];
        }
        if (request.url.path == '/programas/administracion') {
          return [programa()];
        }
        return [];
      },
    );

    await tester.tap(find.text('Crear requisito'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del requisito'),
      'Nuevo requisito',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descripción'),
      'Descripción de prueba',
    );

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Error al guardar'), findsOneWidget);
    expect(find.text('No se pudo guardar'), findsOneWidget);
  });
}
