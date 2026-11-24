// RUTA: frontend/lib/estudiantes/widgets/elevation_chart.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../progreso_models.dart';
import 'dash_style.dart';

/// Perfil de elevación S1 a S10: sube con los créditos aprobados de cada
/// semestre. Línea punteada = aprobados + en curso. Al tocar (o pasar el
/// cursor) sobre un semestre se muestra su detalle y se avisa con [onSeleccion].
class ElevationChart extends StatefulWidget {
  const ElevationChart({
    super.key,
    required this.niveles,
    required this.enCursoPorNivel,
    required this.onSeleccion,
  });

  final List<NivelProgreso> niveles;
  final Map<int, int> enCursoPorNivel;
  final ValueChanged<int> onSeleccion;

  @override
  State<ElevationChart> createState() => _ElevationChartState();
}

class _ElevationChartState extends State<ElevationChart>
    with TickerProviderStateMixin {
  late final AnimationController _trazo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  int? _seleccion;
  int? _hover;
  bool _iniciada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciada) return;
    _iniciada = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _trazo.value = 1;
    } else {
      _trazo.forward();
      _pulso.repeat();
    }
  }

  @override
  void dispose() {
    _trazo.dispose();
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final niveles = widget.niveles;
    final n = niveles.length;
    if (n < 2) {
      return Text('Aún no hay semestres para graficar.', style: Dash.body(14));
    }
    final aprobado = [for (final x in niveles) x.porcentaje];
    final conEnCurso = [
      for (final x in niveles)
        x.creditosTotales == 0
            ? 0.0
            : math.min(
                100.0,
                (x.creditosAprobados + (widget.enCursoPorNivel[x.nivel] ?? 0)) *
                    100 /
                    x.creditosTotales,
              ),
    ];
    final enCurso = [for (final x in niveles) (widget.enCursoPorNivel[x.nivel] ?? 0) > 0];
    final tips = [
      for (final x in niveles)
        'S${x.nivel} · ${x.porcentaje.toStringAsFixed(0)} % · '
            '${x.creditosAprobados}/${x.creditosTotales} cr'
            '${(widget.enCursoPorNivel[x.nivel] ?? 0) > 0 ? ' · +${widget.enCursoPorNivel[x.nivel]} en curso' : ''}',
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final tamano = Size(c.maxWidth, 230);
        int? indiceDe(Offset p) {
          final g = _Geom(tamano, n);
          final i = ((p.dx - _Geom.izq) / g.paso).round();
          if (i < 0 || i >= n) return null;
          if ((p.dx - g.x(i)).abs() > math.max(g.paso / 2, 18)) return null;
          return i;
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onHover: (e) {
            final i = indiceDe(e.localPosition);
            if (i != _hover) setState(() => _hover = i);
          },
          onExit: (_) {
            if (_hover != null) setState(() => _hover = null);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              final i = indiceDe(d.localPosition);
              if (i == null) return;
              setState(() => _seleccion = i);
              widget.onSeleccion(niveles[i].nivel);
            },
            child: Semantics(
              label: 'Gráfico de avance por semestre. Toca un semestre para ver sus materias.',
              child: SizedBox(
                width: tamano.width,
                height: tamano.height,
                child: CustomPaint(
                  painter: _ElevacionPainter(
                    aprobado: aprobado,
                    conEnCurso: conEnCurso,
                    enCurso: enCurso,
                    tips: tips,
                    niveles: [for (final x in niveles) x.nivel],
                    trazo: _trazo,
                    pulso: _pulso,
                    activo: _hover ?? _seleccion,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Geom {
  _Geom(this.size, this.n);

  final Size size;
  final int n;

  static const double izq = 40;
  static const double der = 20;
  static const double arriba = 26;
  static const double abajo = 34;

  double get ancho => size.width - izq - der;
  double get alto => size.height - arriba - abajo;
  double get paso => n > 1 ? ancho / (n - 1) : ancho;
  double x(int i) => izq + paso * i;
  double y(double pct) => arriba + alto * (1 - pct / 100);
}

class _ElevacionPainter extends CustomPainter {
  _ElevacionPainter({
    required this.aprobado,
    required this.conEnCurso,
    required this.enCurso,
    required this.tips,
    required this.niveles,
    required this.trazo,
    required this.pulso,
    required this.activo,
  }) : super(repaint: Listenable.merge([trazo, pulso]));

  final List<double> aprobado;
  final List<double> conEnCurso;
  final List<bool> enCurso;
  final List<String> tips;
  final List<int> niveles;
  final Animation<double> trazo;
  final Animation<double> pulso;
  final int? activo;

  Path _suave(List<Offset> p) {
    final path = Path()..moveTo(p.first.dx, p.first.dy);
    for (var i = 0; i < p.length - 1; i++) {
      final p0 = i == 0 ? p[i] : p[i - 1];
      final p1 = p[i];
      final p2 = p[i + 1];
      final p3 = i + 2 < p.length ? p[i + 2] : p[i + 1];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  void _punteada(Canvas canvas, Path path, Paint paint) {
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 9, m.length)), paint);
        d += 15;
      }
    }
  }

  void _texto(
    Canvas canvas,
    String s,
    Offset o,
    TextStyle st, {
    double ancla = 0.5,
    bool vertical = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: st),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.drawPath(Path(), Paint());
    tp.paint(canvas, Offset(o.dx - tp.width * ancla, vertical ? o.dy - tp.height / 2 : o.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = aprobado.length;
    final g = _Geom(size, n);
    final revela = Curves.easeInOutCubic.transform(trazo.value);

    // Rejilla y eje Y.
    final rejilla = Paint()
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.12);
    for (final v in [0, 50, 100]) {
      final y = g.y(v.toDouble());
      canvas.drawLine(Offset(_Geom.izq, y), Offset(size.width - _Geom.der, y), rejilla);
      _texto(
        canvas,
        '$v%',
        Offset(_Geom.izq - 8, y),
        Dash.code(11, color: Colors.white.withValues(alpha: 0.6), weight: FontWeight.w500),
        ancla: 1,
        vertical: true,
      );
    }

    final puntosA = [for (var i = 0; i < n; i++) Offset(g.x(i), g.y(aprobado[i]))];
    final puntosE = [for (var i = 0; i < n; i++) Offset(g.x(i), g.y(conEnCurso[i]))];
    final curvaA = _suave(puntosA);
    final curvaE = _suave(puntosE);

    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(0, 0, _Geom.izq + g.ancho * revela + 12, size.height),
    );

    final area = Path.from(curvaA)
      ..lineTo(puntosA.last.dx, g.y(0))
      ..lineTo(puntosA.first.dx, g.y(0))
      ..close();
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, _Geom.arriba - 6, size.width, g.alto + 12));
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Dash.aqua.withValues(alpha: 0.38), Dash.aqua.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, _Geom.arriba, size.width, g.alto)),
    );

    if (conEnCurso.asMap().entries.any((e) => e.value > aprobado[e.key] + 0.5)) {
      _punteada(
        canvas,
        curvaE,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..color = Dash.amber,
      );
    }
    canvas.drawPath(
      curvaA,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..color = Dash.aqua.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      curvaA,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = Dash.aqua,
    );
    canvas.restore();
    canvas.restore();

    // Guía vertical del semestre activo.
    final a = activo;
    if (a != null) {
      canvas.drawLine(
        Offset(g.x(a), _Geom.arriba - 4),
        Offset(g.x(a), g.y(0)),
        Paint()
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.35),
      );
    }

    // Nodos y etiquetas del eje X.
    for (var i = 0; i < n; i++) {
      final visible = revela >= i / (n - 1) - 0.02;
      final seleccionado = a == i;
      _texto(
        canvas,
        'S${niveles[i]}',
        Offset(g.x(i), size.height - _Geom.abajo + 12),
        Dash.code(
          12,
          color: seleccionado ? Colors.white : Colors.white.withValues(alpha: 0.65),
          weight: seleccionado ? FontWeight.w800 : FontWeight.w500,
        ),
      );
      if (visible) _nodo(canvas, puntosA[i], i, seleccionado);
    }

    if (a != null) _tooltip(canvas, size, puntosA[a], tips[a]);
  }

  void _nodo(Canvas canvas, Offset o, int i, bool activo) {
    final pct = aprobado[i];
    final r = activo ? 9.0 : 7.0;
    if (enCurso[i] && pct < 99.5) {
      final v = pulso.value;
      canvas.drawCircle(
        o,
        r + 4 + v * 10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Dash.amber.withValues(alpha: 0.55 * (1 - v)),
      );
    }
    canvas.drawCircle(o, r + 2, Paint()..color = Dash.ink.withValues(alpha: 0.9));
    if (pct >= 99.5) {
      canvas.drawCircle(o, r, Paint()..color = Dash.aqua);
      final x = Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = Dash.ink;
      final d = r * 0.42;
      canvas.drawLine(o + Offset(-d, -d), o + Offset(d, d), x);
      canvas.drawLine(o + Offset(d, -d), o + Offset(-d, d), x);
    } else {
      canvas.drawCircle(o, r, Paint()..color = Colors.white.withValues(alpha: 0.14));
      if (pct > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: o, radius: r - 1.5),
          -math.pi / 2,
          2 * math.pi * pct / 100,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Dash.aqua,
        );
      }
      canvas.drawCircle(
        o,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = enCurso[i] ? Dash.amber : Colors.white.withValues(alpha: 0.5),
      );
    }
  }

  void _tooltip(Canvas canvas, Size size, Offset o, String texto) {
    final tp = TextPainter(
      text: TextSpan(text: texto, style: Dash.code(12, weight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    const pad = 10.0;
    final w = tp.width + pad * 2;
    final h = tp.height + pad * 1.4;
    final x = (o.dx - w / 2).clamp(4.0, math.max(4.0, size.width - w - 4)).toDouble();
    final y = math.max(2.0, o.dy - h - 16);
    final caja = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(10));
    canvas.drawRRect(caja, Paint()..color = Dash.ink.withValues(alpha: 0.94));
    canvas.drawRRect(
      caja,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Dash.aqua.withValues(alpha: 0.7),
    );
    tp.paint(canvas, Offset(x + pad, y + pad * 0.7));
  }

  @override
  bool shouldRepaint(_ElevacionPainter old) =>
      old.activo != activo || old.aprobado != aprobado || old.conEnCurso != conEnCurso;
}
