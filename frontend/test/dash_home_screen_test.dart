
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/estudiantes/dash_home_screen.dart';
import 'package:frontend/estudiantes/estudiantes_service.dart';
import 'package:frontend/estudiantes/progreso_service.dart';
import 'package:frontend/estudiantes/widgets/astrolabio.dart';
import 'package:frontend/estudiantes/widgets/dash_background.dart';
import 'package:frontend/estudiantes/widgets/dash_hero.dart';
import 'package:frontend/estudiantes/widgets/sello_x.dart';
import 'package:frontend/requisitos/requisitos_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _codigo = 'A00321654';

final Map<String, dynamic> _estudiante = <String, dynamic>{
  'id': 7,
  'codigo_estudiantil': _codigo,
  'nombre': 'Ana María Pérez',
  'programa': 'Ingeniería de Sistemas',
  'semestre': 5,
};

/// Avance del plan: 96 de 162 créditos (59,3 %) con cinco niveles.
final Map<String, dynamic> _progreso = <String, dynamic>{
  'codigo_estudiantil': _codigo,
  'programa': 'Ingeniería de Sistemas',
  'plan': '201910',
  'periodo_actual': '202620',
  'resumen': <String, dynamic>{
    'creditos_totales': 162,
    'creditos_aprobados': 96,
    'creditos_en_curso': 12,
    'creditos_pendientes': 54,
    'porcentaje_global': 59.3,
    'promedio_acumulado': 4.1,
    'cursos_aprobados': 32,
    'cursos_total': 54,
    'semestres_restantes': 4,
    'periodo_grado_estimado': '202810',
  },
  'niveles': <Map<String, dynamic>>[
    <String, dynamic>{
      'nivel': 1,
      'creditos_totales': 30,
      'creditos_aprobados': 30,
      'porcentaje': 100.0,
    },
    <String, dynamic>{
      'nivel': 2,
      'creditos_totales': 36,
      'creditos_aprobados': 34,
      'porcentaje': 94.4,
    },
    <String, dynamic>{
      'nivel': 3,
      'creditos_totales': 40,
      'creditos_aprobados': 32,
      'porcentaje': 80.0,
    },
    <String, dynamic>{
      'nivel': 4,
      'creditos_totales': 30,
      'creditos_aprobados': 0,
      'porcentaje': 0.0,
    },
    <String, dynamic>{
      'nivel': 5,
      'creditos_totales': 26,
      'creditos_aprobados': 0,
      'porcentaje': 0.0,
    },
  ],
  'cursos': <Map<String, dynamic>>[
    <String, dynamic>{
      'codigo': 'ISCO-C03A',
      'nombre': 'Programación',
      'nivel': 2,
      'creditos': 3,
      'prerequisitos': <String>['ISCO-C02A'],
      'desbloquea': <String>['ISCO-P01A'],
      'estado': 'aprobado',
      'desbloqueada': true,
      'prerequisitos_faltantes': <String>[],
      'fecha_aprobacion': '2025-06-12',
      'periodo': '202510',
      'nota': 4.3,
    },
    <String, dynamic>{
      'codigo': 'CBAS-F01A',
      'nombre': 'Física Mecánica',
      'nivel': 2,
      'creditos': 4,
      'prerequisitos': <String>['CBAS-M01A'],
      'desbloquea': <String>[],
      'estado': 'en_curso',
      'desbloqueada': true,
      'prerequisitos_faltantes': <String>[],
      'periodo': '202620',
    },
    <String, dynamic>{
      'codigo': 'ISCO-P01A',
      'nombre': 'Proyecto de Ingeniería',
      'nivel': 5,
      'creditos': 3,
      'prerequisitos': <String>['ISCO-C03A'],
      'desbloquea': <String>[],
      'estado': 'pendiente',
      'desbloqueada': false,
      'prerequisitos_faltantes': <String>['ISCO-C03A'],
    },
  ],
};

final Map<String, dynamic> _resumenRequisitos = <String, dynamic>{
  'total': 12,
  'cumplidos': 3,
  'en_proceso': 1,
  'pendientes': 8,
  'porcentaje_avance': 25.0,
};

final List<Map<String, dynamic>> _requisitos = <Map<String, dynamic>>[
  <String, dynamic>{
    'id': 1,
    'nombre': 'Certificado de notas',
    'estado': 'cumplido',
  },
  <String, dynamic>{
    'id': 2,
    'nombre': 'Curso de primeros auxilios',
    'estado': 'cumplido',
  },
  <String, dynamic>{
    'id': 3,
    'nombre': 'Suficiencia en inglés',
    'estado': 'cumplido',
  },
  <String, dynamic>{
    'id': 4,
    'nombre': 'Proyecto final de ingeniería',
    'estado': 'en_proceso',
  },
];

bool _nunca() => false;

/// Cliente de prueba: enruta cada endpoint del inicio y, si [falla]
/// devuelve true, contesta con un 500.
ApiClient _api({required bool Function() falla}) {
  const encabezados = <String, String>{
    'content-type': 'application/json; charset=utf-8',
  };

  http.Response ok(Object cuerpo) =>
      http.Response(jsonEncode(cuerpo), 200, headers: encabezados);

  return ApiClient(
    baseUrl: 'https://example.test',
    tokenStorage: InMemoryTokenStorage(),
    client: MockClient((request) async {
      if (falla()) {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'detail': 'El servidor no está disponible. Intenta más tarde.',
          }),
          500,
          headers: encabezados,
        );
      }

      final ruta = request.url.path;

      if (ruta.startsWith('/malla/progreso/')) return ok(_progreso);

      if (ruta.startsWith('/requisitos/') && ruta.endsWith('/resumen')) {
        return ok(_resumenRequisitos);
      }

      if (ruta.startsWith('/requisitos/')) return ok(_requisitos);

      if (ruta.startsWith('/estudiantes/')) return ok(_estudiante);

      return http.Response(
        jsonEncode(<String, dynamic>{
          'detail': 'No se encontró la información solicitada.',
        }),
        404,
        headers: encabezados,
      );
    }),
  );
}

/// Monta el inicio del estudiante.
/// Hay animaciones en bucle, así que no se usa pumpAndSettle.
Future<void> _montar(
  WidgetTester tester, {
  bool Function() falla = _nunca,
  double ancho = 1000,
  double alto = 1500,
}) async {
  tester.view.physicalSize = Size(ancho, alto);
  tester.view.devicePixelRatio = 1;

  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final api = _api(falla: falla);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: DashHomeScreen(
          estudiantes: EstudiantesService(api),
          requisitos: RequisitosService(
            api,
            maxIntentos: 1,
            esperaBase: Duration.zero,
          ),
          progreso: ProgresoService(api),
          codigoEstudiantil: _codigo,
        ),
      ),
    ),
  );

  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(seconds: 1));
}

/// Busca una imagen por su ruta de asset.
Finder _asset(String ruta) => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName == ruta,
);

/// Degradado que tiñe el fondo de la pantalla.
LinearGradient _gradiente(WidgetTester tester) {
  final cajas = tester.widgetList<DecoratedBox>(
    find.descendant(
      of: find.byType(DashBackground),
      matching: find.byType(DecoratedBox),
    ),
  );

  for (final caja in cajas) {
    final decoracion = caja.decoration;

    if (decoracion is BoxDecoration &&
        decoracion.gradient is LinearGradient) {
      return decoracion.gradient! as LinearGradient;
    }
  }

  throw StateError('No se encontró el degradado del fondo.');
}

void main() {
  testWidgets('muestra el saludo, la brújula y la cara sobre el reloj', (
    tester,
  ) async {
    await _montar(tester);

    // El contenido se crea después de resolver las peticiones asíncronas.
    // Se deja terminar la animación del contador del Astrolabio (1.6 s).
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.byType(DashBackground), findsOneWidget);
    expect(find.byType(DashHero), findsOneWidget);
    expect(find.text('Hola, Ana'), findsOneWidget);
    expect(find.text('Código A00321654'), findsOneWidget);
    expect(find.text('Semestre 5'), findsOneWidget);
    expect(find.text('Periodo 202620'), findsOneWidget);

    expect(
      find.text('Vas al 59,3 % del plan: 96 de 162 créditos.'),
      findsOneWidget,
    );

    expect(find.byType(Astrolabio), findsOneWidget);
    expect(find.text('Tu brújula académica'), findsOneWidget);
    expect(find.text('59,3'), findsOneWidget);
    expect(find.text('96 / 162 cr'), findsOneWidget);
    expect(_asset('assets/images/dash_head.png'), findsOneWidget);
  });

  testWidgets('despliega cifras, niveles, logros y el pie de la promoción', (
    tester,
  ) async {
    await _montar(tester, alto: 3000);

    expect(tester.takeException(), isNull);
    expect(find.text('Avance en números'), findsOneWidget);
    expect(find.text('Créditos aprobados'), findsOneWidget);
    expect(find.text('Cursos aprobados'), findsOneWidget);
    expect(find.text('Requisitos cumplidos'), findsOneWidget);
    expect(find.text('Último avance registrado'), findsOneWidget);
    expect(find.text('Programación · 12/06/2025'), findsOneWidget);
    expect(find.text('Niveles del plan'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(5));
    expect(find.text('Logros de grado'), findsOneWidget);
    expect(find.byType(SelloX), findsNWidgets(3));
    expect(find.text('1 requisito en proceso.'), findsOneWidget);
    expect(_asset('assets/images/dash_siluetas.png'), findsOneWidget);

    expect(
      find.text('Cada crédito te acerca a cruzar ese escenario.'),
      findsOneWidget,
    );

    expect(find.text('Plan 201910 · periodo 202620'), findsOneWidget);
  });

  testWidgets('un fallo del servidor ofrece reintentar y recupera los datos', (
    tester,
  ) async {
    var caer = true;

    await _montar(tester, falla: () => caer);

    expect(tester.takeException(), isNull);

    expect(
      find.text('El servidor no está disponible. Intenta más tarde.'),
      findsOneWidget,
    );

    expect(find.text('Reintentar'), findsOneWidget);

    caer = false;

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.text('Hola, Ana'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('al bajar, el fondo se tiñe de naranja', (tester) async {
    await _montar(tester, alto: 1100);

    final fondo = tester.widget<DashBackground>(
      find.byType(DashBackground),
    );

    expect(fondo.scroll.value, 0);

    final coloresAntes = _gradiente(tester).colors;

    await tester.drag(
      find.byType(ListView).first,
      const Offset(0, -600),
    );

    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);

    final traslado = tester.widget<DashBackground>(
      find.byType(DashBackground),
    );

    expect(traslado.scroll.value, greaterThan(0));
    expect(_gradiente(tester).colors, isNot(coloresAntes));
  });

  testWidgets('tocar la leyenda resalta el anillo correspondiente', (
    tester,
  ) async {
    await _montar(tester);

    BoxDecoration decoracion() =>
        tester
                .widget<AnimatedContainer>(
                  find
                      .ancestor(
                        of: find.text('Créditos del plan'),
                        matching: find.byType(AnimatedContainer),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration;

    final antes = decoracion().color;

    await tester.tap(find.text('Créditos del plan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(decoracion().color, isNot(antes));

    await tester.tap(find.text('Créditos del plan'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(decoracion().color, antes);
  });
}
