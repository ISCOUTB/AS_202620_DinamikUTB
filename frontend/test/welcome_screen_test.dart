import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/usuarios/welcome_screen.dart';

void main() {
  testWidgets('la bienvenida muestra el título y avisa al pulsar el botón', (
    tester,
  ) async {
    var pulsado = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: WelcomeScreen(onIniciar: () => pulsado = true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DINA'), findsOneWidget);
    expect(find.text('MIK'), findsOneWidget);
    expect(find.text('UTB'), findsOneWidget);

    await tester.tap(find.text('Iniciar sesión'));
    expect(pulsado, isTrue);
    expect(tester.takeException(), isNull);
  });
}
