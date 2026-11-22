
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/administracion/service/admin_service.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/estudiantes/estudiantes_service.dart';
import 'package:frontend/requisitos/models.dart';
import 'package:frontend/requisitos/requisitos_service.dart';
import 'package:frontend/requisitos/gestion_requisitos_screen.dart';

// Cliente HTTP simulado.
class FakeHttpClient extends http.BaseClient {
  FakeHttpClient(this.handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
      handler;

  final List<http.BaseRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requests.add(request);
    return handler(request);
  }
}

// Crea respuestas HTTP para el cliente falso.
http.StreamedResponse respuesta(
  int status,
  Object? data,
) {
  final body = data == null ? '' : jsonEncode(data);

  return http.StreamedResponse(
    Stream.value(utf8.encode(body)),
    status,
    headers: {'content-type': 'application/json'},
  );
}

Map<String, dynamic> estudianteJson() => {
      'id': 1,
      'codigo_estudiantil': '1234',
      'nombre': 'Juan Pérez',
      'programa': 'Ingeniería de Sistemas',
      'semestre': 6,
    };

Map<String, dynamic> requisitoJson({
  int id = 10,
  String estado = 'pendiente',
}) =>
    {
      'id': id,
      'nombre': 'Prácticas profesionales',
      'estado': estado,
    };

Future<void> montarPantalla(
  WidgetTester tester,
  FakeHttpClient client,
) async {
  final api = ApiClient(
    baseUrl: 'https://test.dinamikutb.dev',
    tokenStorage: InMemoryTokenStorage(),
    client: client,
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GestionRequisitosScreen(
          estudiantes: EstudiantesService(api),
          requisitos: RequisitosService(
            api,
            esperaBase: Duration.zero,
          ),
          administracion: AdminService(api),
        ),
      ),
    ),
  );
}

void main() {
  group('GestionRequisitosScreen', () {
    testWidgets('muestra el mensaje inicial sin realizar consultas',
        (tester) async {
      final client = FakeHttpClient((request) async {
        return respuesta(200, []);
      });

      await montarPantalla(tester, client);

      expect(
        find.text(
          'Busca un estudiante para gestionar sus requisitos.',
        ),
        findsOneWidget,
      );

      expect(find.text('Buscar'), findsOneWidget);
      expect(find.text('Registrar estudiante'), findsOneWidget);
      expect(client.requests, isEmpty);
    });

    testWidgets('valida un código estudiantil vacío', (tester) async {
      final client = FakeHttpClient((request) async {
        return respuesta(200, []);
      });

      await montarPantalla(tester, client);

      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ingresa el código estudiantil'),
        findsOneWidget,
      );

      expect(client.requests, isEmpty);
    });

    testWidgets('valida un código estudiantil incorrecto',
        (tester) async {
      final client = FakeHttpClient((request) async {
        return respuesta(200, []);
      });

      await montarPantalla(tester, client);

      await tester.enterText(
        find.byType(TextFormField),
        '12@!',
      );

      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Solo letras y números (4 a 20 caracteres)',
        ),
        findsOneWidget,
      );

      expect(client.requests, isEmpty);
    });

    testWidgets('busca un estudiante y muestra sus requisitos',
        (tester) async {
      final client = FakeHttpClient((request) async {
        if (request.url.path == '/estudiantes/1234') {
          return respuesta(200, estudianteJson());
        }

        if (request.url.path == '/requisitos/1234') {
          return respuesta(200, [
            requisitoJson(),
          ]);
        }

        return respuesta(404, null);
      });

      await montarPantalla(tester, client);

      await tester.enterText(
        find.byType(TextFormField),
        '1234',
      );

      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      expect(find.text('Juan Pérez'), findsOneWidget);
      expect(
        find.text('Ingeniería de Sistemas · 1234'),
        findsOneWidget,
      );
      expect(
        find.text('Prácticas profesionales'),
        findsOneWidget,
      );
      expect(find.text('Pendiente'), findsOneWidget);

      expect(client.requests.length, 2);
    });

    testWidgets('muestra un error cuando falla la consulta',
        (tester) async {
      final client = FakeHttpClient((request) async {
        return respuesta(500, {
          'detail': 'Error interno',
        });
      });

      await montarPantalla(tester, client);

      await tester.enterText(
        find.byType(TextFormField),
        '1234',
      );

      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'El servidor no está disponible. Intenta más tarde.',
        ),
        findsOneWidget,
      );

      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('permite reintentar una consulta fallida',
        (tester) async {
      var intentos = 0;

      final client = FakeHttpClient((request) async {
        if (request.url.path == '/estudiantes/1234') {
          intentos++;

          if (intentos == 1) {
            return respuesta(500, null);
          }

          return respuesta(200, estudianteJson());
        }

        if (request.url.path == '/requisitos/1234') {
          return respuesta(200, [
            requisitoJson(),
          ]);
        }

        return respuesta(404, null);
      });

      await montarPantalla(tester, client);

      await tester.enterText(
        find.byType(TextFormField),
        '1234',
      );

      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      expect(find.text('Reintentar'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Juan Pérez'), findsOneWidget);
      expect(find.text('Prácticas profesionales'), findsOneWidget);
    });

    testWidgets('muestra el mensaje cuando no hay requisitos',
        (tester) async {
      final client = FakeHttpClient((request) async {
        if (request.url.path == '/estudiantes/1234') {
          return respuesta(200, estudianteJson());
        }

        if (request.url.path == '/requisitos/1234') {
          return respuesta(200, []);
        }

        return respuesta(404, null);
      });

      await montarPantalla(tester, client);

      await tester.enterText(
        find.byType(TextFormField),
        '1234',
      );

      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      expect(find.text('Juan Pérez'), findsOneWidget);

      expect(
        find.text(
          'Este estudiante no tiene requisitos registrados.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('actualiza correctamente el estado de un requisito',
        (tester) async {
      final client = FakeHttpClient((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/estudiantes/1234') {
          return respuesta(200, estudianteJson());
        }

        if (request.method == 'GET' &&
            request.url.path == '/requisitos/1234') {
          return respuesta(200, [
            requisitoJson(),
          ]);
        }

        if (request.method == 'PUT' &&
            request.url.path == '/requisitos/10/estado') {
          final body = jsonDecode(
            (request as http.Request).body,
          ) as Map<String, dynamic>;

          return respuesta(
            200,
            requisitoJson(
              estado: body['estado'] as String,
            ),
          );
        }

        return respuesta(404, null);
      });

      await montarPantalla(tester, client);

      await tester.enterText(
        find.byType(TextFormField),
        '1234',
      );

      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byType(DropdownButton<EstadoRequisito>),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Cumplido').last);
      await tester.pumpAndSettle();

      expect(
        find.text('Estado actualizado.'),
        findsOneWidget,
      );

      expect(
        find.text('Cumplido'),
        findsOneWidget,
      );

      expect(
        client.requests.any(
          (request) =>
              request.method == 'PUT' &&
              request.url.path == '/requisitos/10/estado',
        ),
        isTrue,
      );
    });

    testWidgets('muestra el error cuando falla la actualización',
        (tester) async {
      final client = FakeHttpClient((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/estudiantes/1234') {
          return respuesta(200, estudianteJson());
        }

        if (request.method == 'GET' &&
            request.url.path == '/requisitos/1234') {
          return respuesta(200, [
            requisitoJson(),
          ]);
        }

        if (request.method == 'PUT') {
          return respuesta(403, {
            'detail': 'No tienes permiso para actualizar.',
          });
        }

        return respuesta(404, null);
      });

      await montarPantalla(tester, client);

      await tester.enterText(
        find.byType(TextFormField),
        '1234',
      );

      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byType(DropdownButton<EstadoRequisito>),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Cumplido').last);
      await tester.pumpAndSettle();

      expect(
        find.text('No tienes permiso para actualizar.'),
        findsOneWidget,
      );

      expect(find.text('Pendiente'), findsOneWidget);
    });

    testWidgets('no consulta nuevamente si se busca el mismo código',
        (tester) async {
      final client = FakeHttpClient((request) async {
        if (request.url.path == '/estudiantes/1234') {
          return respuesta(200, estudianteJson());
        }

        if (request.url.path == '/requisitos/1234') {
          return respuesta(200, []);
        }

        return respuesta(404, null);
      });

      await montarPantalla(tester, client);

      await tester.enterText(
        find.byType(TextFormField),
        '1234',
      );

      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      expect(client.requests.length, 2);

      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      expect(client.requests.length, 2);
    });

    testWidgets('permite buscar otro estudiante',
        (tester) async {
      final client = FakeHttpClient((request) async {
        if (request.url.path == '/estudiantes/1234') {
          return respuesta(200, estudianteJson());
        }

        if (request.url.path == '/requisitos/1234') {
          return respuesta(200, []);
        }

        if (request.url.path == '/estudiantes/5678') {
          return respuesta(200, {
            ...estudianteJson(),
            'codigo_estudiantil': '5678',
            'nombre': 'María López',
          });
        }

        if (request.url.path == '/requisitos/5678') {
          return respuesta(200, []);
        }

        return respuesta(404, null);
      });

      await montarPantalla(tester, client);

      await tester.enterText(
        find.byType(TextFormField),
        '1234',
      );

      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      expect(find.text('Juan Pérez'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField),
        '5678',
      );

      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      expect(find.text('María López'), findsOneWidget);
      expect(find.text('Juan Pérez'), findsNothing);
    });
  });
}
