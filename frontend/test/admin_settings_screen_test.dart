import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/administracion/admin_settings_screen.dart';
import 'package:frontend/usuarios/account_screen.dart';

void main() {
  group('AdminSettingsScreen', () {
    testWidgets('muestra la información de la cuenta actual', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminSettingsScreen(email: 'admin@test.com'),
          ),
        ),
      );

      expect(find.text('Configuración'), findsOneWidget);
      expect(find.text('Cuenta actual'), findsOneWidget);
      expect(find.text('Administrador institucional'), findsOneWidget);
      expect(find.text('admin@test.com'), findsOneWidget);
      expect(find.text('Actualizar contraseña'), findsOneWidget);
    });

    testWidgets('permite abrir la pantalla de actualización de contraseña',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminSettingsScreen(email: 'admin@test.com'),
          ),
        ),
      );

      await tester.tap(find.text('Actualizar contraseña'));
      await tester.pumpAndSettle();

      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.text('Actualiza tu contraseña'), findsOneWidget);
      expect(find.text('Contraseña actual'), findsOneWidget);
      expect(find.text('Nueva contraseña'), findsOneWidget);
    });
  });
}
