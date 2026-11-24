import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/estudiantes/dashboard_screen.dart';
import 'package:frontend/estudiantes/estudiantes_service.dart';
import 'package:frontend/estudiantes/widgets/astrolabio.dart';
import 'package:frontend/requisitos/requisitos_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

Map<String, dynamic> _curso(
  String codigo,
  int nivel,
  String estado, {
  bool desbloqueada = true,
  List<String> faltantes = const [],
}) => {
  'codigo': codigo,
  'nombre': 'Curso $codigo',
  'nivel': nivel,
  'creditos': 3,
  'prerequisitos': <String>[],
  'desbloquea': <String>[],
  'estado': estado,
  'desbloqueada': desbloqueada,
  'prerequisitos_faltantes': faltantes,
  'fecha_aprobacion': estado == 'aprobado' ? '2025-06-06' : null,
  'periodo': estado == 'pendiente' ? null : '2025-1',
  'nota': estado == 'aprobado' ? 4.0 : null,
};

http.Response _json(Object cuerpo) => http.Response(
  jsonEncode(cuerpo),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

ApiClient _api() => ApiClient(
  baseUrl: 'https://example.test',
  tokenStorage: InMemoryTokenStorage(),
  client: MockClient((request) async {
    final ruta = request.url.path;
    if (ruta == '/estudiantes/T000123456') {
      return _json({
        'id': 1,
        'codigo_estudiantil': 'T000123456',
        'nombre': 'Ana Pérez',
        'programa': 'Ingeniería de Sistemas y Computación',
        'semestre': 7,
      });
    }
    if (ruta == '/malla/progreso/T000123456') {
      return _json({
        'codigo_estudiantil': 'T000123456',
        'programa': 'Ingeniería de Sistemas y Computación',
        'plan': '201910',
        'periodo_actual': '2026-2',
        'resumen': {
          'creditos_totales': 162,
          'creditos_aprobados': 97,
          'creditos_en_curso': 17,
          'creditos_pendientes': 48,
          'porcentaje_global': 59.9,
          'promedio_acumulado': 4.05,
          'cursos_aprobados': 36,
          'cursos_total': 55,
          'semestres_restantes': 3,
          'periodo_grado_estimado': '2028-1',
        },
        'niveles': [
          for (var i = 1; i <= 4; i++)
            {
              'nivel': i,
              'creditos_totales': 16,
              'creditos_aprobados': i <= 2 ? 16 : 0,
              'porcentaje': i <= 2 ? 100.0 : 0.0,
            },
        ],
        'cursos': [
          _curso('AAAA-01', 1, 'aprobado'),
          _curso('AAAA-02', 2, 'aprobado'),
          _curso('AAAA-03', 3, 'en_curso'),
          _curso('AAAA-04', 4, 'pendiente'),
          _curso('AAAA-05', 4, 'pendiente', desbloqueada: false, faltantes: ['AAAA-03']),
        ],
      });
    }
    if (ruta == '/requisitos/T000123456/ruta') {
      return _json([
        {
          'id': 1,
          'nombre': 'Examen Saber Pro (ICFES)',
          'estado': 'pendiente',
          'categoria': 'Evaluacion',
          'porcentaje_creditos_requerido': 75,
          'creditos_requeridos': 122,
          'creditos_faltantes': 25,
          'habilitado': false,
          'guia_resumen': 'Necesitas el 75 % de los créditos.',
          'pasos_guia': [
            {'titulo': 'Verifica tus créditos', 'detalle': 'Revisa tu avance.', 'oficina': 'Registro'},
          ],
        },
        {
          'id': 2,
          'nombre': 'Bienestar y Cátedra UTB',
          'estado': 'cumplido',
          'categoria': 'Administrativo',
          'fecha_cumplimiento': '2024-06-06',
          'periodo': '2024-1',
          'pasos_guia': <Map<String, dynamic>>[],
        },
      ]);
    }
    return http.Response('{}', 404);
  }),
);

Widget _app(ApiClient api) => Provider<ApiClient>.value(
  value: api,
  child: MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: DashboardScreen(
        estudiantes: EstudiantesService(api),
        requisitos: RequisitosService(api),
        codigoEstudiantil: 'T000123456',
      ),
    ),
  ),
);

void main() {
  for (final tamano in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets('el panorama muestra avance, requisitos y bitácora (${tamano.width.toInt()} px)', (
      tester,
    ) async {
      tester.view.physicalSize = tamano;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(_api()));
      // Hay animaciones en bucle: no usar pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('Hola, Ana'), findsOneWidget);
      expect(find.byType(Astrolabio), findsOneWidget);
      expect(find.textContaining('Te faltan 25 créditos'), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Examen Saber Pro (ICFES)'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Examen Saber Pro (ICFES)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('muestra un error con opción de reintentar', (tester) async {
    final api = ApiClient(
      baseUrl: 'https://example.test',
      tokenStorage: InMemoryTokenStorage(),
      client: MockClient((_) async => http.Response('{}', 500)),
    );
    await tester.pumpWidget(_app(api));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Reintentar'), findsOneWidget);
  });
}
