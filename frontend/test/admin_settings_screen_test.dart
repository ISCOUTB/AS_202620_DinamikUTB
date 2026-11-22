
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/administracion/admin_settings_screen.dart';
import 'package:frontend/usuarios/account_screen.dart';

void main() {
  group('AdminSettingsScreen', () {
    testWidgets('muestra la información de la cuenta', (tester) async {
      await tester.view.setPhysicalSize(const Size(1200, 900));
      await tester.view.setDevicePixelRatio(1);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminSettingsScreen(
            email: 'admin@dinamikutb.dev',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cuenta actual'), findsOneWidget);
      expect(find.text('Administrador institucional'), findsOneWidget);
      expect(find.text('admin@dinamikutb.dev'), findsOneWidget);
      expect(find.text('Configuración'), findsOneWidget);
    });

    testWidgets('muestra el botón para actualizar contraseña', (
      tester,
    ) async {
      await tester.view.setPhysicalSize(const Size(1200, 900));
      await tester.view.setDevicePixelRatio(1);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminSettingsScreen(
            email: 'admin@dinamikutb.dev',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Actualizar contraseña'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('navega a la pantalla de actualización de contraseña', (
      tester,
    ) async {
      await tester.view.setPhysicalSize(const Size(1200, 900));
      await tester.view.setDevicePixelRatio(1);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminSettingsScreen(
            email: 'admin@dinamikutb.dev',
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Actualizar contraseña'));
      await tester.pumpAndSettle();

      expect(find.text('Actualiza tu contraseña'), findsOneWidget);
      expect(find.text('Contraseña actual'), findsOneWidget);
      expect(find.text('Nueva contraseña'), findsOneWidget);
      expect(find.text('admin@dinamikutb.dev'), findsOneWidget);
    });
  });
}
