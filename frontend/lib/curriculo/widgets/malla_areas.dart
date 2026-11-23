import 'package:flutter/material.dart';

/// Área curricular de un curso. El área se deriva del prefijo del código
/// (CBAS, CHUL, CHUM, ISCO, …) y conserva la codificación de color del
/// PDF oficial de la malla: básicas en violeta, lenguas en ámbar,
/// humanidades en verde, sistemas en azul de marca y proyectos en índigo.
class MallaArea {
  const MallaArea({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.color,
    required this.tinte,
    required this.texto,
  });

  final String id;
  final String nombre;
  final IconData icono;

  /// Color fuerte del área (acento del curso, letra de las etiquetas).
  final Color color;

  /// Fondo tenue del área (etiquetas de código y de créditos).
  final Color tinte;

  /// Color de texto legible sobre [tinte].
  final Color texto;
}

abstract final class MallaAreas {
  static const basicas = MallaArea(
    id: 'basicas',
    nombre: 'Básicas',
    icono: Icons.calculate_outlined,
    color: Color(0xFF7C3AED),
    tinte: Color(0xFFF5F3FF),
    texto: Color(0xFF6D28D9),
  );

  static const lenguas = MallaArea(
    id: 'lenguas',
    nombre: 'Lenguas',
    icono: Icons.translate_rounded,
    color: Color(0xFFF59E0B),
    tinte: Color(0xFFFFFBEB),
    texto: Color(0xFFB45309),
  );

  static const humanidades = MallaArea(
    id: 'humanidades',
    nombre: 'Humanidades',
    icono: Icons.menu_book_rounded,
    color: Color(0xFF10B981),
    tinte: Color(0xFFECFDF5),
    texto: Color(0xFF047857),
  );

  static const sistemas = MallaArea(
    id: 'sistemas',
    nombre: 'Sistemas',
    icono: Icons.code_rounded,
    color: Color(0xFF0284C7),
    tinte: Color(0xFFEFF9FF),
    texto: Color(0xFF0369A1),
  );

  static const proyectos = MallaArea(
    id: 'proyectos',
    nombre: 'Proyectos',
    icono: Icons.rocket_launch_rounded,
    color: Color(0xFF4F46E5),
    tinte: Color(0xFFEEF2FF),
    texto: Color(0xFF4338CA),
  );

  static const empresariales = MallaArea(
    id: 'empresariales',
    nombre: 'Empresariales',
    icono: Icons.insights_rounded,
    color: Color(0xFFEC4899),
    tinte: Color(0xFFFDF2F8),
    texto: Color(0xFFBE185D),
  );

  /// Todas las áreas del plan, en el orden en que se muestran en la leyenda.
  static const List<MallaArea> todas = <MallaArea>[
    basicas,
    lenguas,
    humanidades,
    sistemas,
    proyectos,
    empresariales,
  ];

  /// Resuelve el área de un curso a partir de su código (`CBAS-M01A`).
  static MallaArea deCodigo(String codigo) {
    final partes = codigo.split('-');
    final prefijo = partes.first;
    final sufijo = partes.length > 1 ? partes.last : '';
    switch (prefijo) {
      case 'CBAS':
        return basicas;
      case 'CHUL':
        return lenguas;
      case 'CHUM':
        return humanidades;
      case 'ISCO':
        // ISCO-PxxA son los proyectos de ingeniería; el resto (C y A) son
        // cursos de sistemas, incluidas las electivas complementarias.
        return sufijo.startsWith('P') ? proyectos : sistemas;
      default:
        return empresariales;
    }
  }

  /// Número en romanos para los encabezados de nivel (I, II, III, …).
  static String romano(int numero) {
    const valores = <int>[10, 9, 5, 4, 1];
    const simbolos = <String>['X', 'IX', 'V', 'IV', 'I'];
    var restante = numero;
    final texto = StringBuffer();
    for (var i = 0; i < valores.length; i++) {
      while (restante >= valores[i]) {
        texto.write(simbolos[i]);
        restante -= valores[i];
      }
    }
    return texto.toString();
  }
}
