import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/usuarios/models.dart';
import 'package:frontend/usuarios/perfil_screen.dart';

void main() {
  testWidgets('el perfil adapta los datos reales a pantallas móviles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PerfilScreen(
            usuario: const Usuario(
              id: 1,
              email: 'estudiante@dinamikutb.dev',
              rol: Rol.estudiante,
              codigoEstudiantil: 'T00012345',
              nombre: 'Ana Torres',
              programa: 'Ingeniería de Sistemas y Computación',
              semestre: 6,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana Torres'), findsOneWidget);
    expect(find.text('T00012345'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Actualizar contraseña'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Actualizar contraseña'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
