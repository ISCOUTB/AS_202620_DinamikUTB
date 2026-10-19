import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/requisitos/requisitos_service.dart';

typedef Paso = Future<http.StreamedResponse> Function();

/// Cliente que ejecuta un guion de respuestas, en orden. El último paso se repite.
class ClienteConGuion extends http.BaseClient {
  ClienteConGuion(this._pasos);

  final List<Paso> _pasos;
  int llamadas = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final indice = llamadas < _pasos.length ? llamadas : _pasos.length - 1;
    llamadas++;
    return _pasos[indice]();
  }
}

Future<http.StreamedResponse> _respuesta(int status, String cuerpo) async {
  return http.StreamedResponse(
    Stream.value(utf8.encode(cuerpo)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

const _json = '[{"id": 1, "nombre": "Inglés B2", "estado": "pendiente"}]';

RequisitosService _servicio(ClienteConGuion cliente) => RequisitosService(
      baseUrl: 'http://127.0.0.1:8000',
      client: cliente,
      timeout: const Duration(milliseconds: 50),
      maxIntentos: 3,
      esperaBase: Duration.zero,
    );

void main() {
  test('Fallo "no responde": reintenta tras un 503 y termina con éxito', () async {
    final cliente = ClienteConGuion([
      () => _respuesta(503, ''),
      () => _respuesta(200, _json),
    ]);

    final requisitos = await _servicio(cliente).obtenerRequisitos('T000123456');

    expect(requisitos.length, 1);
    expect(cliente.llamadas, 2);
  });

  test('Fallo "no responde": reintenta tras una falla de conexión', () async {
    final cliente = ClienteConGuion([
      () => throw http.ClientException('sin conexión'),
      () => _respuesta(200, _json),
    ]);

    final requisitos = await _servicio(cliente).obtenerRequisitos('T000123456');

    expect(requisitos.first.nombre, 'Inglés B2');
    expect(cliente.llamadas, 2);
  });

  test('Fallo "responde tarde": corta por timeout y agota los intentos', () async {
    final cliente = ClienteConGuion([
      () => Completer<http.StreamedResponse>().future, // nunca responde
    ]);

    await expectLater(
      _servicio(cliente).obtenerRequisitos('T000123456'),
      throwsException,
    );
    expect(cliente.llamadas, 3);
  });

  test('Fallo "responde tarde": una respuesta lenta pero dentro de los intentos se recupera', () async {
    final cliente = ClienteConGuion([
      () => Completer<http.StreamedResponse>().future, // 1.er intento: timeout
      () => _respuesta(200, _json),
    ]);

    final requisitos = await _servicio(cliente).obtenerRequisitos('T000123456');

    expect(requisitos.length, 1);
    expect(cliente.llamadas, 2);
  });

  test('Un 404 no se reintenta: un error del cliente no se arregla repitiendo', () async {
    final cliente = ClienteConGuion([() => _respuesta(404, '')]);

    await expectLater(
      _servicio(cliente).obtenerRequisitos('T000123456'),
      throwsException,
    );
    expect(cliente.llamadas, 1);
  });

  test('Fallo "responde dos veces": la consulta repetida devuelve el mismo resultado', () async {
    final cliente = ClienteConGuion([() => _respuesta(200, _json)]);
    final servicio = _servicio(cliente);

    final primera = await servicio.obtenerRequisitos('T000123456');
    final segunda = await servicio.obtenerRequisitos('T000123456');

    expect(segunda.length, primera.length);
    expect(segunda.first.estado, primera.first.estado);
  });
}
