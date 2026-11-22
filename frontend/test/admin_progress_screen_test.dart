
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/administracion/admin_progress_screen.dart';
import 'package:frontend/administracion/service/admin_service.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/requisitos/requisitos_service.dart';

import 'helpers/fake_admin_api.dart';

Map<String, dynamic> estudiante({
  String codigo = '2026001',
  String nombre = 'Ana Pérez',
}) => {
  'id': 1,
  'codigo_estudiantil': codigo,
  'nombre': nombre,
  'email': 'ana@test.com',
  'programa': 'Ingeniería de Sistemas',
  'semestre': 5,
  'activo': true,
};

Map<String, dynamic> programa() => {
  'id': 1,
  'codigo': 'SIS',
  'nombre': 'Ingeniería de Sistemas',
  'facultad': 'Ingeniería',
  'duracion_semestres': 10,
  'activo': true,
  'estudiantes_asociados': 20,
};

Map<String, dynamic> resumen(double porcentaje) => {
  'total': 10,
  'cumplidos': 5,
  'en_proceso': 2,
  'pendientes': 3,
  'porcentaje_avance': porcentaje,
};

void main() {
  late FakeAdminApiClient client;
  late AdminService adminService;
  late RequisitosService requisitosService;

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

    adminService = AdminService(api);
    requisitosService = RequisitosService(
      api,
      maxIntentos: 1,
      esperaBase: Duration.zero,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<RequisitosService>.value(value: requisitosService),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AdminProgressScreen(service: adminService),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('muestra estudiantes y su resumen académico', (tester) async {
    await abrirPantalla(
      tester,
      handler: (request) {
        if (request.url.path == '/estudiantes') {
          return [estudiante()];
        }
        if (request.url.path == '/programas') {
          return [programa()];
        }
        if (request.url.path == '/requisitos/2026001/resumen') {
          return resumen(65);
        }
        return [];
      },
    );

    expect(find.text('Seguimiento académico'), findsOneWidget);
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('65%'), findsOneWidget);
    expect(find.textContaining('5 cumplidos'), findsOneWidget);
  });

  testWidgets('muestra el estado vacío cuando no hay estudiantes', (
    tester,
  ) async {
    await abrirPantalla(
      tester,
      handler: (request) => [],
    );

    expect(find.text('Sin estudiantes para mostrar'), findsOneWidget);
    expect(
      find.text('Registra estudiantes para iniciar el seguimiento.'),
      findsOneWidget,
    );
  });

  testWidgets('muestra error al fallar la carga de estudiantes', (
    tester,
  ) async {
    await abrirPantalla(
      tester,
      handler: (request) {
        if (request.url.path == '/estudiantes') {
          return const FakeApiResponse(
            {'detail': 'Error de prueba'},
            statusCode: 500,
          );
        }
        return [];
      },
    );

    expect(find.textContaining('servidor'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('permite filtrar por nivel de avance', (tester) async {
    await abrirPantalla(
      tester,
      handler: (request) {
        if (request.url.path == '/estudiantes') {
          return [
            estudiante(),
            estudiante(codigo: '2026002', nombre: 'Luis Gómez'),
          ];
        }
        if (request.url.path == '/programas') {
          return [programa()];
        }
        if (request.url.path.endsWith('/resumen')) {
          return request.url.path.contains('2026001')
              ? resumen(30)
              : resumen(90);
        }
        return [];
      },
    );

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Luis Gómez'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>).at(2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Atención (<50%)').last);
    await tester.pumpAndSettle();

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Luis Gómez'), findsNothing);
  });

  testWidgets('permite filtrar por programa y semestre', (tester) async {
    await abrirPantalla(
      tester,
      handler: (request) {
        if (request.url.path == '/estudiantes') {
          return [estudiante()];
        }
        if (request.url.path == '/programas') {
          return [programa()];
        }
        if (request.url.path.endsWith('/resumen')) {
          return resumen(65);
        }
        return [];
      },
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ingeniería de Sistemas').last);
    await tester.pumpAndSettle();

    expect(
      client.requests.any(
        (request) => request.url.queryParameters['programa'] ==
            'Ingeniería de Sistemas',
      ),
      isTrue,
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semestre 5').last);
    await tester.pumpAndSettle();

    expect(
      client.requests.any(
        (request) => request.url.queryParameters['semestre'] == '5',
      ),
      isTrue,
    );
  });

  testWidgets('muestra error cuando falla el resumen de un estudiante', (
    tester,
  ) async {
    await abrirPantalla(
      tester,
      handler: (request) {
        if (request.url.path == '/estudiantes') {
          return [estudiante()];
        }
        if (request.url.path.endsWith('/resumen')) {
          return const FakeApiResponse(
            {'detail': 'Error de resumen'},
            statusCode: 500,
          );
        }
        return [];
      },
    );

    expect(find.text('Reintentar'), findsOneWidget);
  });
}
