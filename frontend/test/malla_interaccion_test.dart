import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/curriculo/malla_screen.dart';
import 'package:frontend/curriculo/malla_service.dart';
import 'package:frontend/curriculo/widgets/malla_areas.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Plan corto con las seis áreas representadas: básicas, lenguas,
/// humanidades, sistemas, proyecto y una sin prefijo reconocido.
final List<Map<String, dynamic>> _cursos = <Map<String, dynamic>>[
  _curso('CBAS-M01A', 'Cálculo Diferencial', 1, 4),
  _curso('CBAS-M02A', 'Matemáticas Básicas', 1, 2),
  _curso('CHUM-H01A', 'Taller de Comprensión Lectora', 1, 3),
  _curso('ECOU-U01A', 'Desarrollo Universitario', 1, 0),
  _curso('ISCO-C02A', 'Fundamentos de Programación', 1, 3),
  _curso('CBAS-F01A', 'Física Mecánica', 2, 4, ['CBAS-M01A', 'CBAS-M02A']),
  _curso('CHUL-LE1A', 'Lengua Extranjera I', 2, 2, ['CHUM-H01A']),
  _curso('ISCO-C03A', 'Programación', 2, 3, ['ISCO-C02A']),
  _curso('ISCO-P01A', 'Proyecto de Ingeniería', 5, 3, ['ISCO-C03A']),
];

Map<String, dynamic> _curso(
  String codigo,
  String nombre,
  int nivel,
  int creditos, [
  List<String> prerequisitos = const <String>[],
]) => <String, dynamic>{
  'codigo': codigo,
  'nombre': nombre,
  'nivel': nivel,
  'creditos': creditos,
  'prerequisitos': prerequisitos,
};

ApiClient _api() => ApiClient(
  baseUrl: 'https://example.test',
  tokenStorage: InMemoryTokenStorage(),
  client: MockClient((request) async {
    expect(request.url.path, '/malla');
    return http.Response(
      jsonEncode(<String, dynamic>{
        'programa': 'Ingeniería de Sistemas',
        'plan': '201910',
        'creditos_totales': 162,
        'cursos': _cursos,
      }),
      200,
      headers: <String, String>{
        'content-type': 'application/json; charset=utf-8',
      },
    );
  }),
);

/// Monta la pantalla y deja terminar todas las animaciones de entrada.
///
/// Hay animaciones en bucle (mascota, chispas y el punto «aquí»), así que
/// no se puede usar `pumpAndSettle`: se avanza el reloj a tramos.
Future<void> _montar(
  WidgetTester tester, {
  double ancho = 900,
  double alto = 1000,
  int? semestre = 2,
}) async {
  tester.view.physicalSize = Size(ancho, alto);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: MallaScreen(
          service: MallaService(_api()),
          programa: 'Ingeniería de Sistemas',
          semestreActual: semestre,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(seconds: 3));
}

/// Subárbol de la ficha inferior: es el único con desplazamiento propio.
Finder get _ficha => find.ancestor(
  of: find.text('Centrar en el tablero'),
  matching: find.byType(SingleChildScrollView),
);

/// Avanza el reloj lo justo para que un bottom sheet entre o salga.
Future<void> _transicion(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

void main() {
  test('las áreas se derivan del código de cada curso', () {
    expect(MallaAreas.deCodigo('CBAS-M01A').id, 'basicas');
    expect(MallaAreas.deCodigo('CHUL-LE1A').id, 'lenguas');
    expect(MallaAreas.deCodigo('CHUM-H01A').id, 'humanidades');
    expect(MallaAreas.deCodigo('ISCO-C03A').id, 'sistemas');
    expect(MallaAreas.deCodigo('ISCO-C02A').id, 'sistemas');
    expect(MallaAreas.deCodigo('ISCO-P01A').id, 'proyectos');
    expect(MallaAreas.deCodigo('ECOU-U01A').id, 'empresariales');
    expect(MallaAreas.todas, hasLength(6));
  });

  test('los niveles se escriben en romanos', () {
    expect(MallaAreas.romano(1), 'I');
    expect(MallaAreas.romano(2), 'II');
    expect(MallaAreas.romano(4), 'IV');
    expect(MallaAreas.romano(5), 'V');
    expect(MallaAreas.romano(9), 'IX');
    expect(MallaAreas.romano(10), 'X');
  });

  testWidgets('la malla y sus controles se adaptan a pantalla de escritorio', (
    tester,
  ) async {
    await _montar(tester, ancho: 1200, alto: 900);

    expect(tester.takeException(), isNull);
    expect(find.text('Malla curricular'), findsOneWidget);
    expect(find.text('Ruta de la malla'), findsOneWidget);
    expect(find.text('Física Mecánica'), findsOneWidget);
    expect(find.text('Proyecto de Ingeniería'), findsOneWidget);
  });

  testWidgets('al tocar un curso se abre su ficha con prerrequisitos y '
      'desbloqueos', (tester) async {
    await _montar(tester);

    final prerrequisitosEnPantalla = tester
        .widgetList(find.text('CBAS-M01A'))
        .length;

    await tester.tap(find.text('Física Mecánica'));
    await _transicion(tester);

    expect(tester.takeException(), isNull);
    // Los títulos de sección se pintan en versalitas (toUpperCase).
    expect(find.text('NECESITAS APROBAR ANTES'), findsOneWidget);
    expect(find.text('ESTO DESBLOQUEA'), findsOneWidget);
    expect(
      find.text('Curso terminal: no habilita otros de la malla.'),
      findsOneWidget,
    );
    expect(find.text('4 créditos'), findsOneWidget);
    expect(find.text('Centrar en el tablero'), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);

    // Los prerrequisitos aparecen también dentro de la ficha, además de en
    // la tarjeta del curso y en la del que los necesita.
    expect(
      tester.widgetList(find.text('CBAS-M01A')).length,
      greaterThan(prerrequisitosEnPantalla),
    );
  });

  testWidgets('un curso sin prerrequisitos avisa que puede tomarse desde el '
      'primer día', (tester) async {
    await _montar(tester);

    await tester.tap(find.text('Desarrollo Universitario'));
    await _transicion(tester);

    expect(tester.takeException(), isNull);
    expect(
      find.text('Sin prerrequisitos: puedes tomarlo desde el primer día.'),
      findsOneWidget,
    );
    expect(find.text('0 créditos'), findsOneWidget);
  });

  testWidgets('desde la ficha se salta al prerrequisito y la ruta se '
      'recalcula', (tester) async {
    await _montar(tester);

    await tester.tap(find.text('Física Mecánica'));
    await _transicion(tester);
    expect(find.text('NECESITAS APROBAR ANTES'), findsOneWidget);

    final salto = find.descendant(of: _ficha, matching: find.text('CBAS-M01A'));
    expect(salto, findsOneWidget);

    await tester.tap(salto);
    await _transicion(tester);
    await _transicion(tester);

    expect(tester.takeException(), isNull);
    // La ficha ahora muestra Cálculo Diferencial, que no tiene previos.
    expect(
      find.text('Sin prerrequisitos: puedes tomarlo desde el primer día.'),
      findsOneWidget,
    );
    expect(find.text('NECESITAS APROBAR ANTES'), findsOneWidget);
    expect(
      find.text('Cálculo Diferencial'),
      findsNWidgets(2),
      reason: 'la tarjeta del tablero y la ficha abierta',
    );
  });

  testWidgets('centrar desde la ficha cierra el panel y deja la ruta '
      'encendida', (tester) async {
    await _montar(tester);

    await tester.tap(find.text('Física Mecánica'));
    await _transicion(tester);
    // Al abrir la ficha el tablero ya marca la ruta del curso, así que el
    // control de limpiar aparece desde ese momento.
    expect(find.byTooltip('Limpiar ruta'), findsOneWidget);

    await tester.tap(find.text('Centrar en el tablero'));
    await _transicion(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Centrar en el tablero'), findsNothing);
    expect(find.byTooltip('Limpiar ruta'), findsOneWidget);

    // Limpiar la ruta vuelve a ocultar el control.
    await tester.tap(find.byTooltip('Limpiar ruta'));
    await _transicion(tester);
    expect(find.byTooltip('Limpiar ruta'), findsNothing);
  });

  testWidgets('el filtro de áreas atenúa el resto de la malla', (tester) async {
    await _montar(tester);

    BoxDecoration decoracion() {
      final contenedor = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text('Básicas'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      return contenedor.decoration! as BoxDecoration;
    }

    expect(decoracion().color, Colors.white);

    await tester.tap(find.text('Básicas'));
    await _transicion(tester);

    expect(tester.takeException(), isNull);
    expect(decoracion().color, MallaAreas.basicas.color);

    await tester.tap(find.text('Básicas'));
    await _transicion(tester);

    expect(decoracion().color, Colors.white);
  });

  testWidgets('los controles del tablero amplían, ajustan y enfocan sin '
      'errores', (tester) async {
    await _montar(tester);

    for (final control in const ['Acercar', 'Alejar', 'Ajustar', 'Tu nivel']) {
      await tester.tap(find.byTooltip(control));
      await _transicion(tester);
    }

    expect(tester.takeException(), isNull);
    expect(find.text('Malla curricular'), findsOneWidget);
  });

  testWidgets('la leyenda lista las áreas con su conteo de cursos', (
    tester,
  ) async {
    // La leyenda es un ListView horizontal: en pantalla angosta las últimas
    // chips no se construyen, así que se usa un ancho de escritorio.
    await _montar(tester, ancho: 1400, alto: 900, semestre: null);

    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('Básicas'), findsOneWidget);
    expect(find.text('Lenguas'), findsOneWidget);
    expect(find.text('Humanidades'), findsOneWidget);
    expect(find.text('Sistemas'), findsOneWidget);
    expect(find.text('Proyectos'), findsOneWidget);
    expect(find.text('Empresariales'), findsOneWidget);

    // 5 básicas, 1 lenguas, 1 humanidades, 3 sistemas (ISCO-C02A,
    // ISCO-C03A e ISCO-P01A es proyecto), 1 proyecto y 1 empresarial.
    expect(find.text('Todas').evaluate(), isNotEmpty);
    expect(tester.takeException(), isNull);
    expect(AppColors.navy, isNotNull);
  });
}
