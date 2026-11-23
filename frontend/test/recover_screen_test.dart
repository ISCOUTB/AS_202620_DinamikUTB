import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/usuarios/auth_controller.dart';
import 'package:frontend/usuarios/auth_service.dart';
import 'package:frontend/usuarios/recover_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

AuthController _auth(int status) {
  final almacen = InMemoryTokenStorage();
  final api = ApiClient(
    baseUrl: 'https://example.test',
    tokenStorage: almacen,
    client: MockClient((_) async => http.Response('{}', status)),
  );
  return AuthController(service: AuthService(api), storage: almacen);
}

Widget _app(AuthController auth) =>
    ChangeNotifierProvider<AuthController>.value(
      value: auth,
      child: MaterialApp(theme: AppTheme.light, home: const RecoverScreen()),
    );

void main() {
  testWidgets('valida el correo antes de enviar', (tester) async {
    await tester.pumpWidget(_app(_auth(200)));
    // Hay animaciones en bucle: no usar pumpAndSettle.
    await tester.pump(const Duration(seconds: 4));

    await tester.enterText(find.byType(TextFormField), '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('Ingresa tu correo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'explica que no hay correo configurado si el servidor responde 503',
    (tester) async {
      await tester.pumpWidget(_app(_auth(503)));
      await tester.pump(const Duration(seconds: 4));

      await tester.enterText(find.byType(TextFormField), 'ana@utb.edu.co');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.textContaining('no tiene correo de recuperación'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'confirma el envío cuando el servidor acepta la solicitud',
    (tester) async {
      await tester.pumpWidget(_app(_auth(200)));
      await tester.pump(const Duration(seconds: 4));

      await tester.enterText(find.byType(TextFormField), 'ana@utb.edu.co');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('recibirás instrucciones'), findsOneWidget);
    },
  );
}
