import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;

/// Fondo del panorama: morado de la bienvenida arriba; al bajar se tiñe de
/// magenta y termina en el naranja de «¿Olvidaste tu contraseña?».
class DashBackground extends StatelessWidget {
  const DashBackground({super.key, required this.scroll, required this.ambient});

  /// Progreso del scroll entre 0 (arriba) y 1.
  final ValueListenable<double> scroll;
  final Animation<double> ambient;

  static const _top = [Color(0xFF3A0090), Color(0xFF7A1FA2), Color(0xFFE13B44)];
  static const _mid = [Color(0xFF5B00C8), Color(0xFFB02E9C), Color(0xFFFC673F)];
  static const _bot = [Color(0xFF6A00D8), Color(0xFFD2457A), Color(0xFFFD7A38)];

  static const _orbes = [
    (-0.9, -0.8, 380.0, Color(0xFFA855F7), Color(0xFFFDBA74), 0.0),
    (0.95, -0.2, 320.0, Color(0xFF3B82F6), Color(0xFFF97316), 0.3),
    (-0.7, 0.55, 340.0, Color(0xFFD946EF), Color(0xFFFB7185), 0.6),
    (0.85, 0.95, 400.0, Color(0xFF7C3AED), Color(0xFFFACC15), 0.15),
  ];

  static Color _k(List<Color> claves, double p) {
    final x = c01(p) * (claves.length - 1);
    final i = x.floor().clamp(0, claves.length - 2);
    return Color.lerp(claves[i], claves[i + 1], x - i)!;
  }

  static double c01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([scroll, ambient]),
        builder: (context, _) {
          final p = scroll.value;
          final t = ambient.value * 2 * math.pi;
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_k(_top, p), _k(_mid, p), _k(_bot, p)],
                  ),
                ),
              ),
              CustomPaint(painter: _AnillosPainter(t)),
              for (final o in _orbes)
                Align(
                  alignment: Alignment(
                    o.$1 + 0.05 * math.sin(t + o.$6 * 6),
                    o.$2 + 0.05 * math.cos(t + o.$6 * 6),
                  ),
                  child: Container(
                    width: o.$3,
                    height: o.$3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color.lerp(o.$4, o.$5, p)!.withValues(alpha: 0.34),
                          Color.lerp(o.$4, o.$5, p)!.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Círculos concéntricos tenues, como las curvas de un mapa topográfico.
class _AnillosPainter extends CustomPainter {
  _AnillosPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width * 0.82, size.height * 0.16);
    final pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.06);
    for (var i = 1; i <= 7; i++) {
      canvas.drawCircle(centro, 70.0 * i + 6 * math.sin(t + i), pincel);
    }
  }

  @override
  bool shouldRepaint(_AnillosPainter old) => old.t != t;
}
