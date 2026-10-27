import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/validators.dart';
import 'package:frontend/core/widgets/app_shell.dart';
import 'package:frontend/requisitos/requisitos_screen.dart';
import 'package:frontend/requisitos/requisitos_service.dart';
import 'package:frontend/usuarios/auth_controller.dart';
import 'package:frontend/usuarios/auth_service.dart';
import 'package:frontend/usuarios/login_screen.dart';

class ClienteFalso extends http.BaseClient {
  ClienteFalso(this._respuesta, this._statusCode);

  final String _respuesta;
  final int _statusCode;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode(_respuesta)),
      _statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}

ApiClient _api(String respuesta, [int status = 200]) => ApiClient(
  baseUrl: 'http://127.0.0.1:8000',
  tokenStorage: InMemoryTokenStorage(),
  client: ClienteFalso(respuesta, status),
);

AuthController _auth() {
  final almacen = InMemoryTokenStorage();
  final api = ApiClient(
    baseUrl: 'http://127.0.0.1:8000',
    tokenStorage: almacen,
    client: ClienteFalso('{}', 401),
  );
  return AuthController(service: AuthService(api), storage: almacen);
}

void main() {
  testWidgets('Muestra los requisitos del estudiante', (tester) async {
    final json = jsonEncode([
      {'id': 1, 'nombre': 'Inglés B2', 'estado': 'pendiente'},
      {'id': 2, 'nombre': 'Práctica profesional', 'estado': 'cumplido'},
    ]);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: RequisitosScreen(
            service: RequisitosService(_api(json)),
            estudianteId: 'T000123456',
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Inglés B2'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Práctica profesional'), findsOneWidget);
    expect(find.text('Cumplido'), findsOneWidget);
  });

  testWidgets('Muestra un mensaje cuando no hay requisitos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: RequisitosScreen(
            service: RequisitosService(_api('[]')),
            estudianteId: 'T999999999',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No tienes requisitos registrados.'), findsOneWidget);
  });

  testWidgets('Muestra error con opción de reintentar si el servidor falla', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: RequisitosScreen(
            service: RequisitosService(_api('{}', 500)),
            estudianteId: 'T000123456',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('El login valida los campos antes de enviar', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: _auth(),
        child: MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pump();

    expect(find.text('Ingresa tu correo'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    expect(find.text('Regístrate'), findsNothing);
  });

  testWidgets('El campo de contraseña permite escribir números', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: _auth(),
        child: MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
      ),
    );

    final passwordField = tester.widget<TextField>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Contraseña'),
        matching: find.byType(TextField),
      ),
    );
    expect(passwordField.keyboardType, TextInputType.visiblePassword);

    await tester.enterText(find.byType(TextFormField).last, '12345678');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pump();

    expect(find.text('Mínimo 8 caracteres'), findsNothing);
    expect(find.text('Ingresa tu contraseña'), findsNothing);
  });

  testWidgets(
    'El shell es adaptativo: barra inferior en móvil, riel en escritorio',
    (tester) async {
      addTearDown(tester.view.reset);
      final destinos = [
        for (final nombre in ['Uno', 'Dos'])
          ShellDestination(
            label: nombre,
            icon: Icons.circle_outlined,
            selectedIcon: Icons.circle,
            builder: (_) => Text('contenido $nombre'),
          ),
      ];
      Widget app() => ChangeNotifierProvider<AuthController>.value(
        value: _auth(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: AppShell(destinations: destinos),
        ),
      );

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpWidget(app());
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpWidget(app());
      await tester.pump();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    },
  );

  test('Validators rechaza entradas con caracteres de inyección', () {
    expect(Validators.codigoEstudiantil("T1' OR '1'='1"), isNotNull);
    expect(Validators.codigoEstudiantil('T000123456'), isNull);
    expect(Validators.email('no-es-correo'), isNotNull);
    expect(Validators.email('ana@dinamikutb.dev'), isNull);
    expect(Validators.password('corta'), isNotNull);
  });
}
