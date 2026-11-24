import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dash_motion.dart';
import 'dash_style.dart';

/// Astrolabio: anillo exterior = créditos aprobados del plan; anillo interior =
/// requisitos de grado cumplidos. Un aro de marcas gira muy despacio.
/// Tocar la leyenda resalta un anillo.
class Astrolabio extends StatefulWidget {
  const Astrolabio({
    super.key,
    required this.creditosPct,
    required this.requisitosPct,
    required this.creditosAprobados,
    required this.creditosEnCurso,
    required this.creditosPendientes,
    required this.creditosTotales,
    required this.requisitosCumplidos,
    required this.requisitosTotal,
    required this.semestresRestantes,
    required this.hitos,
    this.promedio,
    this.periodoGrado,
  });

  final double creditosPct;
  final double requisitosPct;
  final int creditosAprobados;
  final int creditosEnCurso;
  final int creditosPendientes;
  final int creditosTotales;
  final int requisitosCumplidos;
  final int requisitosTotal;
  final int semestresRestantes;
  final List<double> hitos;
  final double? promedio;
  final String? periodoGrado;

  @override
  State<Astrolabio> createState() => _AstrolabioState();
}

class _AstrolabioState extends State<Astrolabio> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );
  late final AnimationController _giro = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 120),
  );
  int _foco = 0; // 0 ninguno, 1 créditos, 2 requisitos
  bool _iniciada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciada) return;
    _iniciada = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
      _giro.repeat();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _giro.dispose();
    super.dispose();
  }

  void _alternar(int valor) =>
      setState(() => _foco = _foco == valor ? 0 : valor);

  @override
  Widget build(BuildContext context) {
    final compacto = esCompacto(context);
    return GlassPanel(
      padding: EdgeInsets.all(compacto ? 18 : 26),
      child: LayoutBuilder(
        builder: (context, c) {
          final ancho = c.maxWidth >= 720;
          final lado = math.min(ancho ? 380.0 : c.maxWidth, 400.0);
          final anillo = _anillo(lado);
          final datos = _datos();
          if (ancho) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: lado, child: anillo),
                const SizedBox(width: 28),
                Expanded(child: datos),
              ],
            );
          }
          return Column(
            children: [
              Center(
                child: SizedBox(width: lado, child: anillo),
              ),
              const SizedBox(height: 20),
              datos,
            ],
          );
        },
      ),
    );
  }

  Widget _anillo(double lado) {
    return Column(
      children: [
        SizedBox(
          width: lado,
          height: lado,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _AstrolabioPainter(
                      cred: widget.creditosPct,
                      req: widget.requisitosPct,
                      hitos: widget.hitos,
                      intro: _intro,
                      giro: _giro,
                      foco: _foco,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: lado * 0.42,
                child: FittedBox(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AnimatedCounter(
                            value: widget.creditosPct,
                            decimals: 1,
                            style: Dash.display(54),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, left: 2),
                            child: Text(
                              '%',
                              style: Dash.display(22, color: Dash.sky),
                            ),
                          ),
                        ],
                      ),
                      Text('del plan aprobado', style: Dash.body(13)),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.creditosAprobados} / ${widget.creditosTotales} cr',
                        style: Dash.code(13, color: Dash.sky),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _Leyenda(
              color: Dash.aqua,
              titulo: 'Créditos del plan',
              valor: '${widget.creditosPct.toStringAsFixed(0)} %',
              activo: _foco == 1,
              onTap: () => _alternar(1),
            ),
            _Leyenda(
              color: Dash.amber,
              titulo: 'Requisitos de grado',
              valor:
                  '${widget.requisitosCumplidos} de ${widget.requisitosTotal}',
              activo: _foco == 2,
              onTap: () => _alternar(2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _datos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tu brújula académica', style: Dash.display(26)),
        const SizedBox(height: 6),
        Text(
          'El anillo de afuera mide tus créditos; el de adentro, los requisitos '
          'institucionales. Toca la leyenda para resaltar uno.',
          style: Dash.body(
            14,
            color: Colors.white.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Tile(
              etiqueta: 'Promedio acumulado',
              hijo: widget.promedio == null
                  ? Text('—', style: Dash.code(28))
                  : AnimatedCounter(
                      value: widget.promedio!,
                      decimals: 2,
                      style: Dash.code(28),
                    ),
            ),
            _Tile(
              etiqueta: 'Grado estimado',
              hijo: Text(
                widget.periodoGrado ?? 'Completado',
                style: Dash.code(24, color: Dash.amber),
              ),
              pie: widget.semestresRestantes > 0
                  ? '${widget.semestresRestantes} semestres por delante'
                  : null,
            ),
            _Tile(
              etiqueta: 'Aprobados',
              hijo: AnimatedCounter(
                value: widget.creditosAprobados.toDouble(),
                style: Dash.code(26, color: Dash.aqua),
                suffix: ' cr',
              ),
            ),
            _Tile(
              etiqueta: 'En curso',
              hijo: AnimatedCounter(
                value: widget.creditosEnCurso.toDouble(),
                style: Dash.code(26, color: Dash.amber),
                suffix: ' cr',
              ),
            ),
            _Tile(
              etiqueta: 'Por cursar',
              hijo: AnimatedCounter(
                value: widget.creditosPendientes.toDouble(),
                style: Dash.code(26),
                suffix: ' cr',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.etiqueta, required this.hijo, this.pie});

  final String etiqueta;
  final Widget hijo;
  final String? pie;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 140),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          etiqueta,
          style: Dash.body(12, color: Colors.white.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 4),
        hijo,
        if (pie != null) ...[
          const SizedBox(height: 2),
          Text(pie!, style: Dash.body(11.5, color: Dash.sky)),
        ],
      ],
    ),
  );
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({
    required this.color,
    required this.titulo,
    required this.valor,
    required this.activo,
    required this.onTap,
  });

  final Color color;
  final String titulo;
  final String valor;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: activo,
    label: '$titulo: $valor',
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: activo
              ? color.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo ? color : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                titulo,
                overflow: TextOverflow.ellipsis,
                style: Dash.body(12.5, weight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Text(valor, style: Dash.code(12.5, color: color)),
          ],
        ),
      ),
    ),
  );
}

class _AstrolabioPainter extends CustomPainter {
  _AstrolabioPainter({
    required this.cred,
    required this.req,
    required this.hitos,
    required this.intro,
    required this.giro,
    required this.foco,
  }) : super(repaint: Listenable.merge([intro, giro]));

  final double cred;
  final double req;
  final List<double> hitos;
  final Animation<double> intro;
  final Animation<double> giro;
  final int foco;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final radio = size.shortestSide / 2;
    final avance = Curves.easeOutCubic.transform(intro.value);

    _marcas(canvas, c, radio);

    final rExt = radio - 34;
    final rInt = rExt - 32;

    _anillo(canvas, c, rExt, 16, cred / 100 * avance, const [
      Dash.aqua,
      Dash.sky,
      Dash.aqua,
    ], atenuado: foco == 2);
    _anillo(canvas, c, rInt, 12, req / 100 * avance, const [
      Dash.amber,
      Color(0xFFFB923C),
      Dash.amber,
    ], atenuado: foco == 1);

    // Hitos de créditos sobre el anillo exterior.
    for (final h in hitos) {
      final a = -math.pi / 2 + 2 * math.pi * h / 100;
      final dir = Offset(math.cos(a), math.sin(a));
      final alcanzado = cred >= h && avance > 0.98;
      canvas.drawLine(
        c + dir * (rExt - 15),
        c + dir * (rExt + 15),
        Paint()
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: alcanzado ? 0.95 : 0.5),
      );
    }

    // Punta luminosa del anillo exterior.
    final fin = -math.pi / 2 + 2 * math.pi * cred / 100 * avance;
    final punta = c + Offset(math.cos(fin), math.sin(fin)) * rExt;
    canvas.drawCircle(
      punta,
      13,
      Paint()
        ..color = Dash.aqua.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawCircle(punta, 7, Paint()..color = Colors.white);

    // Retícula interior, como la de una carta de navegación.
    final fino = Paint()
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.1);
    final rRet = rInt - 22;
    canvas.drawLine(c + Offset(-rRet, 0), c + Offset(rRet, 0), fino);
    canvas.drawLine(c + Offset(0, -rRet), c + Offset(0, rRet), fino);
    canvas.drawCircle(c, rRet, fino..style = PaintingStyle.stroke);
  }

  void _marcas(Canvas canvas, Offset c, double radio) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(giro.value * 2 * math.pi);
    final corta = Paint()
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.2);
    final larga = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.5);
    for (var i = 0; i < 120; i++) {
      final a = i * 2 * math.pi / 120;
      final largo = i % 10 == 0;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        d * (radio - (largo ? 14 : 7)),
        d * (radio - 1),
        largo ? larga : corta,
      );
    }
    final rombo = Paint()..color = Dash.amber;
    for (var k = 0; k < 4; k++) {
      final a = k * math.pi / 2;
      final o = Offset(math.cos(a), math.sin(a)) * (radio - 22);
      canvas.save();
      canvas.translate(o.dx, o.dy);
      canvas.rotate(a + math.pi / 4);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 7, height: 7),
        rombo,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  void _anillo(
    Canvas canvas,
    Offset c,
    double r,
    double grosor,
    double fraccion,
    List<Color> colores, {
    required bool atenuado,
  }) {
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor
        ..color = Colors.white.withValues(alpha: 0.1),
    );
    final barrido = 2 * math.pi * c01(fraccion);
    if (barrido <= 0) return;
    final filtro = atenuado
        ? ColorFilter.mode(
            Colors.white.withValues(alpha: 0.3),
            BlendMode.modulate,
          )
        : null;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      barrido,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor + 8
        ..strokeCap = StrokeCap.round
        ..color = colores.first.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..colorFilter = filtro,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      barrido,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: colores,
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..colorFilter = filtro,
    );
  }

  @override
  bool shouldRepaint(_AstrolabioPainter old) =>
      old.cred != cred ||
      old.req != req ||
      old.foco != foco ||
      old.hitos != hitos;
}
