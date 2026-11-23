import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dash_style.dart';

/// Sello ✕ de «hecho»: el anillo se cierra y las dos diagonales se dibujan
/// una tras otra, con un pequeño golpe de escala como un sello de goma.
class SelloX extends StatefulWidget {
  const SelloX({
    super.key,
    this.size = 46,
    this.animar = true,
    this.color = Dash.coral,
  });

  final double size;
  final bool animar;
  final Color color;

  @override
  State<SelloX> createState() => _SelloXState();
}

class _SelloXState extends State<SelloX> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _iniciada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciada) return;
    _iniciada = true;
    if (!widget.animar || MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) {
      final golpe = Curves.easeOutBack.transform(c01(_c.value * 2));
      return Transform.rotate(
        angle: -0.14,
        child: Transform.scale(
          scale: 1 + (1 - golpe) * 0.6,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(painter: _SelloPainter(_c.value, widget.color)),
          ),
        ),
      );
    },
  );
}

class _SelloPainter extends CustomPainter {
  _SelloPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 3;
    final anillo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, size.shortestSide * 0.065)
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.92);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * c01(t * 2.5),
      false,
      anillo,
    );
    final cruz = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.4, size.shortestSide * 0.11)
      ..strokeCap = StrokeCap.round
      ..color = color;
    final d = r * 0.5;
    final a1 = c + Offset(-d, -d);
    final b1 = c + Offset(d, d);
    final a2 = c + Offset(d, -d);
    final b2 = c + Offset(-d, d);
    canvas.drawLine(a1, Offset.lerp(a1, b1, c01((t - 0.35) / 0.3))!, cruz);
    canvas.drawLine(a2, Offset.lerp(a2, b2, c01((t - 0.6) / 0.3))!, cruz);
  }

  @override
  bool shouldRepaint(_SelloPainter old) => old.t != t || old.color != color;
}
