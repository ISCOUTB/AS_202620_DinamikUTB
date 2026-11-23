
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/usuarios/auth_service.dart';
import 'package:frontend/usuarios/models.dart';

class ClienteFalso extends http.BaseClient {
  ClienteFalso(this.respuesta);

  final String respuesta;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode(respuesta)),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}

AuthService crearServicio(String respuesta) {
  final api = ApiClient(
    baseUrl: 'http://127.0.0.1:8000',
    tokenStorage: InMemoryTokenStorage(),
    client: ClienteFalso(respuesta),
  );

  return AuthService(api);
}

void main() {
  group('AuthService', () {
    test('login devuelve el token de acceso', () async {
      final service = crearServicio('{"access_token":"token-prueba"}');

      final resultado = await service.login(' usuario@test.com ', '12345678');

      expect(resultado, 'token-prueba');
    });

    test('perfil devuelve los datos del usuario', () async {
      final service = crearServicio('''
      {
        "id": 1,
        "email": "estudiante@test.com",
        "rol": "estudiante",
        "codigo_estudiantil": "T000123456",
        "nombre": "Ana",
        "programa": "Ingeniería de Sistemas",
        "semestre": 5
      }
      ''');

      final resultado = await service.perfil();

      expect(resultado.id, 1);
      expect(resultado.email, 'estudiante@test.com');
      expect(resultado.nombre, 'Ana');
      expect(resultado.semestre, 5);
    });

    test('solicitarRecuperacion acepta una solicitud', () async {
      final service = crearServicio('{}');

      await expectLater(
        service.solicitarRecuperacion(' usuario@test.com '),
        completes,
      );
    });

    test('restablecerPassword acepta una solicitud', () async {
      final service = crearServicio('{}');

      await expectLater(
        service.restablecerPassword('token-prueba', 'Nueva12345'),
        completes,
      );
    });

    test('actualizarPerfil devuelve el usuario actualizado', () async {
      final service = crearServicio('''
      {
        "id": 1,
        "email": "estudiante@test.com",
        "rol": "estudiante",
        "nombre": "Ana María",
        "programa": "Ingeniería de Sistemas",
        "semestre": 6
      }
      ''');

      final resultado = await service.actualizarPerfil(
        nombre: 'Ana María',
        programa: 'Ingeniería de Sistemas',
        semestre: 6,
      );

      expect(resultado.nombre, 'Ana María');
      expect(resultado.semestre, 6);
    });

    test('cambiarPassword acepta una solicitud', () async {
      final service = crearServicio('{}');

      await expectLater(
        service.cambiarPassword(
          actual: 'Anterior123',
          nueva: 'Nueva12345',
        ),
        completes,
      );
    });
  });

  group('Usuario y Rol', () {
    test('reconoce los roles disponibles', () {
      expect(Rol.desde('estudiante'), Rol.estudiante);
      expect(Rol.desde('coordinador'), Rol.coordinador);
      expect(Rol.desde('administrador'), Rol.administrador);
    });

    test('asigna estudiante cuando el rol es desconocido', () {
      expect(Rol.desde('desconocido'), Rol.estudiante);
    });

    test('identifica los roles de gestión', () {
      expect(Rol.estudiante.esGestion, false);
      expect(Rol.coordinador.esGestion, true);
      expect(Rol.administrador.esGestion, true);
    });

    test('convierte los datos JSON de un usuario', () {
      final usuario = Usuario.fromJson({
        'id': 2,
        'email': 'admin@test.com',
        'rol': 'administrador',
        'codigo_estudiantil': null,
        'nombre': 'Administrador',
        'programa': null,
        'semestre': null,
      });

      expect(usuario.id, 2);
      expect(usuario.rol, Rol.administrador);
      expect(usuario.nombre, 'Administrador');
      expect(usuario.codigoEstudiantil, isNull);
    });
  });
}
