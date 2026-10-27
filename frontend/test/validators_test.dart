import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/validators.dart';

void main() {
  group('Validators.correoInstitucional', () {
    test('acepta el dominio institucional configurado por la API', () {
      expect(
        Validators.correoInstitucional('estudiante@dinamikutb.dev'),
        isNull,
      );
    });

    test('normaliza mayúsculas y espacios alrededor del correo', () {
      expect(
        Validators.correoInstitucional('  Estudiante@DINAMIKUTB.DEV  '),
        isNull,
      );
    });

    test('rechaza dominios que la API no admite', () {
      expect(
        Validators.correoInstitucional('estudiante@dinamikutb.dev'),
        contains('@dinamikutb.dev'),
      );
    });

    test('rechaza direcciones con formato inválido', () {
      expect(Validators.correoInstitucional('correo-invalido'), isNotNull);
    });
  });
}
