import 'dart:ui' show FontFeature, ImageFilter;

import 'package:flutter/material.dart';

/// Paleta y estilos del panorama del estudiante.
///
/// Mismos colores de la bienvenida (morado) y de «¿Olvidaste tu contraseña?»
/// (naranja); Outfit y Syne para texto, monoespaciada tabular para códigos,
/// fechas y notas.
abstract final class Dash {
  static const navy = Color(0xFF0A192F);
  static const cobalt = Color(0xFF0052A5);
  static const turquoise = Color(0xFF0D9488);
  static const aqua = Color(0xFF2DD4BF);
  static const coral = Color(0xFFD94E34);
  static const amber = Color(0xFFFBBF24);
  static const sky = Color(0xFF7DD3FC);
  static const ink = Color(0xFF1A0640);

  static const _mono = TextStyle(
    fontFamily: 'monospace',
    fontFamilyFallback: ['Courier New', 'Roboto Mono', 'Menlo'],
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static TextStyle display(double size, {Color color = Colors.white}) =>
      TextStyle(
        fontFamily: 'Syne',
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.02,
        color: color,
      );

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = Colors.white,
    double height = 1.3,
  }) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color,
  );

  static TextStyle code(
    double size, {
    Color color = Colors.white,
    FontWeight weight = FontWeight.w700,
  }) => _mono.copyWith(fontSize: size, color: color, fontWeight: weight);
}

abstract final class DashAssets {
  static const head = 'assets/images/dash_head.png';
  static const guide = 'assets/images/dash_guide.png';
  static const siluetas = 'assets/images/dash_siluetas.png';
}

bool esCompacto(BuildContext context) => MediaQuery.sizeOf(context).width < 600;

String fechaCorta(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

double c01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

/// Panel de vidrio, como el de la bienvenida y el inicio de sesión.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.radius = 28,
    this.blur = true,
    this.alpha = 0.42,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool blur;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    final contenido = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: Dash.ink.withValues(alpha: alpha),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: child,
    );
    if (!blur) return contenido;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: contenido,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.titulo, this.subtitulo});

  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    final compacto = esCompacto(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Dash.display(compacto ? 26 : 32)),
        if (subtitulo != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitulo!,
            style: Dash.body(
              14.5,
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}
