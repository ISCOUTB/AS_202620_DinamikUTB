
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/administracion/admin_accounts_screen.dart';
import 'package:frontend/administracion/service/admin_service.dart';

class ClienteAdminFalso extends http.BaseClient {
  ClienteAdminFalso(this.respuesta, {this.statusCode = 200});

  final String respuesta;
  final int statusCode;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode(respuesta)),
      statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}

AdminService crearServicio(String respuesta, {int statusCode = 200}) {
  final api = ApiClient(
    baseUrl: 'http://127.0.0.1:8000',
    tokenStorage: InMemoryTokenStorage(),
    client: ClienteAdminFalso(respuesta, statusCode: statusCode),
  );

  return AdminService(api);
}

void main() {
  group('AdminAccountsScreen', () {
    testWidgets('muestra las cuentas administrativas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminAccountsScreen(
              service: crearServicio('''
              [
                {
                  "id": 1,
                  "email": "coordinador@test.com",
                  "rol": "coordinador",
                  "activo": true,
                  "codigo_estudiantil": null
                }
              ]
              '''),
              onLogout: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cuentas y administradores'), findsOneWidget);
      expect(find.text('coordinador@test.com'), findsOneWidget);
      expect(find.text('Activo'), findsOneWidget);
    });

    testWidgets('muestra mensaje cuando no hay cuentas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminAccountsScreen(
              service: crearServicio('[]'),
              onLogout: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No hay cuentas'), findsOneWidget);
    });

    testWidgets('muestra error cuando falla la consulta', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminAccountsScreen(
              service: crearServicio('{}', statusCode: 500),
              onLogout: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('abre el formulario para agregar una cuenta', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminAccountsScreen(
              service: crearServicio('[]'),
              onLogout: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Agregar cuenta de gestión'));
      await tester.pumpAndSettle();

      expect(find.text('Crear cuenta de gestión'), findsOneWidget);
      expect(find.text('Correo institucional'), findsOneWidget);
      expect(find.text('Crear cuenta'), findsOneWidget);
    });

    testWidgets('permite cancelar la creación de una cuenta', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminAccountsScreen(
              service: crearServicio('[]'),
              onLogout: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Agregar cuenta de gestión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Crear cuenta de gestión'), findsNothing);
    });
  });
}
