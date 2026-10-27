import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/metric_card.dart';
import 'package:frontend/estudiantes/models.dart';
import 'package:frontend/estudiantes/widgets/dashboard_components.dart';
import 'package:frontend/requisitos/models.dart';

void main() {
  testWidgets('el tablero no desborda en una pantalla móvil', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final components = <Widget>[
      const DashboardWelcomeCard(
        estudiante: Estudiante(
          id: 1,
          codigoEstudiantil: 'T1234567',
          nombre: 'Estudiante de prueba',
          programa: 'Ingeniería de Sistemas y Computación',
          semestre: 4,
        ),
        resumen: ResumenRequisitos(
          total: 3,
          cumplidos: 1,
          enProceso: 1,
          pendientes: 1,
          porcentajeAvance: 33.33,
        ),
      ),
      const MetricCard(
        title: 'Requisitos de grado',
        value: '3',
        caption: 'En tu plan académico',
        icon: Icons.fact_check_outlined,
        color: Colors.blue,
        background: Colors.blueGrey,
      ),
      const DashboardRequirementsPanel(
        requisitos: [
          Requisito(
            id: 1,
            nombre: 'Requisito académico de ejemplo',
            estado: EstadoRequisito.pendiente,
          ),
        ],
      ),
    ];
    for (final component in components) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [component],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '${component.runtimeType} no debe desbordarse',
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: components,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
