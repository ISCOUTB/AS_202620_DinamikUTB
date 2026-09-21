import 'package:flutter/material.dart';

import 'requisitos/requisitos_screen.dart';
import 'requisitos/requisitos_service.dart';

const Color colorGranate = Color(0xFF8C1D24);
const Color colorNegro = Color(0xFF161414);
const Color colorFondo = Color(0xFFFAF7F5);
const Color colorTextoSecundario = Color(0xFF6B6560);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DinamikUTB',
      theme: ThemeData(
        scaffoldBackgroundColor: colorFondo,
        appBarTheme: const AppBarTheme(
          backgroundColor: colorNegro,
          foregroundColor: Colors.white,
        ),
        colorScheme: const ColorScheme.light(
          primary: colorGranate,
          onPrimary: Colors.white,
          surface: colorFondo,
          onSurface: colorNegro,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: colorGranate,
        ),
      ),
      home: RequisitosScreen(
        service: RequisitosService(baseUrl: 'http://127.0.0.1:8000'),
        estudianteId: 'T000123456',
      ),
    );
  }
}
