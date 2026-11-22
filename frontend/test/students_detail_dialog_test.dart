
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:frontend/administracion/service/admin_service.dart';
import 'package:frontend/administracion/widgets/students_detail_dialog.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/requisitos/requisitos_service.dart';

class FakeHttpClient extends http.BaseClient {
  FakeHttpClient(this.handler);

  final Future<http.StreamedResponse> Function(http.Request request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return handler(request as http.Request);
  }
}

http.StreamedResponse respuesta(
  int statusCode,
  Map<String, dynamic> data,
) {
  return http.StreamedResponse(
    Stream.value(utf8.encode(jsonEncode(data))),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}

final resumenNormal = {
  'total': 10,
  'cumplidos': 6,
  'en_proceso': 2,
  'pendientes': 2,
  'porcentaje_avance': 60.0,
};

final resumenRiesgo = {
  'total': 10,
  'cumplidos': 3,
  'en_proceso': 1,
  'pendientes': 6,
  'porcentaje_avance': 30.0,
};

final resumenCompleto = {
  'total': 10,
  'cumplidos': 10,
  'en_proceso': 0,
  'pendientes': 0,
  'porcentaje_avance': 100.0,
};

AdminStudent crearEstudiante({
  String nombre = 'Juan Pérez',
  String codigo = '2024001',
  String email = 'juan@utb.edu.co',
  String programa = 'Ingeniería de Sistemas',
  int? semestre = 6,
  bool activo = true,
}) {
  return AdminStudent(
    id: 1,
    codigo: codigo,
    nombre: nombre,
    email: email,
    programa: programa,
    semestre: semestre,
    activo: activo,
  );
}

Widget crearAplicacion({
  required Future<http.StreamedResponse> Function(http.Request) handler,
  AdminStudent? student,
  VoidCallback? onEdit,
}) {
  final client = FakeHttpClient(handler);

  final api = ApiClient(
    baseUrl: 'http://127.0.0.1:8000',
    tokenStorage: InMemoryTokenStorage(),
    client: client,
  );

  final service = RequisitosService(api);

  return Provider<RequisitosService>.value(
    value: service,
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => StudentDetailDialog(
                      student: student ?? crearEstudiante(),
                      onEdit: onEdit ?? () {},
                    ),
                  );
                },
                child: const Text('Ver detalle'),
              ),
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  group('StudentDetailDialog', () {
    testWidgets('muestra los datos del estudiante y su progreso', (
      tester,
    ) async {
      await tester.pumpWidget(
        crearAplicacion(
          handler: (_) async => respuesta(200, resumenNormal),
        ),
      );

      await tester.tap(find.text('Ver detalle'));
      await tester.pumpAndSettle();

      expect(find.text('Juan Pérez'), findsOneWidget);
      expect(find.text('2024001 · juan@utb.edu.co'), findsOneWidget);
      expect(
        find.text('Ingeniería de Sistemas · Semestre 6'),
        findsOneWidget,
      );

      expect(find.text('Activo'), findsOneWidget);
      expect(find.text('Estado y Avance Académico'), findsOneWidget);
      expect(find.text('Cumplimiento general'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
      expect(find.text('Requisitos pendientes'), findsOneWidget);
      expect(find.text('2'), findsWidgets);

      expect(find.text('Diagnóstico y Advertencias'), findsOneWidget);
      expect(find.text('Avance normal'), findsOneWidget);
    });

    testWidgets('muestra el estado inactivo y los datos opcionales', (
      tester,
    ) async {
      await tester.pumpWidget(
        crearAplicacion(
          student: crearEstudiante(
            nombre: '',
            semestre: null,
            activo: false,
          ),
          handler: (_) async => respuesta(200, resumenNormal),
        ),
      );

      await tester.tap(find.text('Ver detalle'));
      await tester.pumpAndSettle();

      expect(find.text('?'), findsOneWidget);
      expect(find.text(' · Semestre —'), findsOneWidget);
      expect(find.text('Inactivo'), findsOneWidget);
    });

    testWidgets('muestra el indicador de carga mientras espera el servicio', (
      tester,
    ) async {
      final respuestaPendiente = Completer<http.StreamedResponse>();

      await tester.pumpWidget(
        crearAplicacion(
          handler: (_) => respuestaPendiente.future,
        ),
      );

      await tester.tap(find.text('Ver detalle'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      respuestaPendiente.complete(respuesta(200, resumenNormal));

      await tester.pumpAndSettle();

      expect(find.text('Estado y Avance Académico'), findsOneWidget);
    });

    testWidgets('muestra un mensaje cuando ocurre un error al cargar', (
      tester,
    ) async {
      await tester.pumpWidget(
        crearAplicacion(
          handler: (_) async => respuesta(500, {
            'detail': 'Error del servidor',
          }),
        ),
      );

      await tester.tap(find.text('Ver detalle'));
      await tester.pumpAndSettle();

      expect(
        find.text('No se pudo obtener el progreso del estudiante.'),
        findsOneWidget,
      );

      expect(find.text('Cerrar'), findsOneWidget);
      expect(find.text('Editar estudiante'), findsOneWidget);
    });

    testWidgets('muestra advertencia de riesgo con avance inferior al 50%', (
      tester,
    ) async {
      await tester.pumpWidget(
        crearAplicacion(
          handler: (_) async => respuesta(200, resumenRiesgo),
        ),
      );

      await tester.tap(find.text('Ver detalle'));
      await tester.pumpAndSettle();

      expect(find.text('30%'), findsOneWidget);
      expect(find.text('Riesgo de rezago académico'), findsOneWidget);

      expect(
        find.textContaining('avance inferior al 50%'),
        findsOneWidget,
      );
    });

    testWidgets('muestra advertencia de próximo a egreso', (
      tester,
    ) async {
      await tester.pumpWidget(
        crearAplicacion(
          student: crearEstudiante(semestre: 8),
          handler: (_) async => respuesta(200, resumenNormal),
        ),
      );

      await tester.tap(find.text('Ver detalle'));
      await tester.pumpAndSettle();

      expect(find.text('Atención: Próximo a egreso'), findsOneWidget);

      expect(
        find.textContaining('Cursa semestres finales'),
        findsOneWidget,
      );
    });

    testWidgets('muestra avance normal cuando no hay alertas', (
      tester,
    ) async {
      await tester.pumpWidget(
        crearAplicacion(
          student: crearEstudiante(semestre: 9),
          handler: (_) async => respuesta(200, resumenCompleto),
        ),
      );

      await tester.tap(find.text('Ver detalle'));
      await tester.pumpAndSettle();

      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Avance normal'), findsOneWidget);

      expect(
        find.textContaining('sin alertas críticas'),
        findsOneWidget,
      );
    });

    testWidgets('el botón Cerrar cierra el diálogo', (
      tester,
    ) async {
      await tester.pumpWidget(
        crearAplicacion(
          handler: (_) async => respuesta(200, resumenNormal),
        ),
      );

      await tester.tap(find.text('Ver detalle'));
      await tester.pumpAndSettle();

      expect(find.byType(StudentDetailDialog), findsOneWidget);

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      expect(find.byType(StudentDetailDialog), findsNothing);
    });

    testWidgets('Editar estudiante cierra el diálogo y ejecuta onEdit', (
      tester,
    ) async {
      var editado = false;

      await tester.pumpWidget(
        crearAplicacion(
          handler: (_) async => respuesta(200, resumenNormal),
          onEdit: () {
            editado = true;
          },
        ),
      );

      await tester.tap(find.text('Ver detalle'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Editar estudiante'));
      await tester.pumpAndSettle();

      expect(editado, isTrue);
      expect(find.byType(StudentDetailDialog), findsNothing);
    });

    testWidgets('el riesgo académico tiene prioridad sobre próximo a egreso', (
      tester,
    ) async {
      await tester.pumpWidget(
        crearAplicacion(
          student: crearEstudiante(semestre: 9),
          handler: (_) async => respuesta(200, resumenRiesgo),
        ),
      );

      await tester.tap(find.text('Ver detalle'));
      await tester.pumpAndSettle();

      expect(find.text('Riesgo de rezago académico'), findsOneWidget);
      expect(find.text('Atención: Próximo a egreso'), findsNothing);
    });
  });
}
