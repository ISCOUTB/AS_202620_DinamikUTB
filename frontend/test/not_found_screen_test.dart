import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/main.dart' show AppDependencias, DinamikApp;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('la página 404 informa y permite volver al inicio', (
    tester,
  ) async {
    final dependencies = AppDependencias.crear(
      baseUrl: 'https://example.test',
      storage: InMemoryTokenStorage(),
      client: MockClient((_) async => http.Response('{}', 401)),
    );
    await tester.pumpWidget(DinamikApp(dependencias: dependencies));
    await tester.pumpAndSettle();
    unawaited(
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .pushNamed<void>('/ruta-inexistente'),
    );
    await tester.pumpAndSettle();

    expect(find.text('404'), findsOneWidget);
    expect(find.text('No encontramos esta página'), findsOneWidget);
    expect(find.text('Volver al inicio'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Volver al inicio'));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenido a DinamikUTB'), findsOneWidget);
  });
}
