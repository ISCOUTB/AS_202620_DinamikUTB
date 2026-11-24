import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dash_style.dart';
import 'sello_x.dart';

class Hito {
  const Hito(this.pct, this.etiqueta);

  final double pct;
  final String etiqueta;
}

/// Barra de camino a la graduación con marcadores de hito (75 %, 80 %, 100 %).
/// La cabeza avanza sobre el relleno y rebota suavemente.
class HitoBar extends StatefulWidget {
  const HitoBar({
    super.key,
    required this.porcentaje,
    required this.creditosAprobados,
    required this.creditosTotales,
    required this.hitos,
  });

  final double porcentaje;
  final int creditosAprobados;
  final int creditosTotales;
  final List<Hito> hitos;

  @override
  State<HitoBar> createState() => _HitoBarState();
}

class _Grupo {
  _Grupo(this.pct, this.pcts, this.etiquetas);

  final double pct;
  final List<double> pcts;
  final List<String> etiquetas;
}

class _HitoBarState extends State<HitoBar> with TickerProviderStateMixin {
  late final AnimationController _llena = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final AnimationController _rebote = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _iniciada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciada) return;
    _iniciada = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _llena.value = 1;
    } else {
      _llena.forward();
      _rebote.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _llena.dispose();
    _rebote.dispose();
    super.dispose();
  }

  /// Junta hitos cercanos (menos de 6 puntos) en una sola etiqueta.
  List<_Grupo> _grupos() {
    final orden = [...widget.hitos]..sort((a, b) => a.pct.compareTo(b.pct));
    final grupos = <_Grupo>[];
    for (final h in orden) {
      if (grupos.isNotEmpty && h.pct - grupos.last.pct <= 6) {
        grupos.last.pcts.add(h.pct);
        grupos.last.etiquetas.add(h.etiqueta);
      } else {
        grupos.add(_Grupo(h.pct, [h.pct], [h.etiqueta]));
      }
    }
    return grupos;
  }

  String _siguiente() {
    final w = widget;
    for (final h in [...w.hitos]..sort((a, b) => a.pct.compareTo(b.pct))) {
      final requeridos = (w.creditosTotales * h.pct.round() + 99) ~/ 100;
      final faltan = requeridos - w.creditosAprobados;
      if (faltan > 0) {
        return 'Te faltan $faltan créditos para llegar al ${h.pct.toStringAsFixed(0)} %: ${h.etiqueta.toLowerCase()}.';
      }
    }
    return '¡Alcanzaste todos los hitos de créditos!';
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.porcentaje.clamp(0.0, 100.0).toDouble();
    final grupos = _grupos();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_siguiente(), style: Dash.body(15, weight: FontWeight.w600)),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            const alto = 20.0;
            const zona = 66.0;
            final anchoEtiqueta = math.min(160.0, w / 2);
            return AnimatedBuilder(
              animation: Listenable.merge([_llena, _rebote]),
              builder: (context, _) {
                final llena = Curves.easeOutCubic.transform(_llena.value);
                final relleno = w * pct / 100 * llena;
                final salto = Curves.easeInOut.transform(_rebote.value) * 5;
                return SizedBox(
                  height: zona * 2 + alto,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: zona,
                        left: 0,
                        right: 0,
                        height: alto,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(alto),
                            color: Colors.white.withValues(alpha: 0.14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                        ),
                      ),
                      Positioned(
                        top: zona,
                        left: 0,
                        width: math.max(relleno, 0),
                        height: alto,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(alto),
                            gradient: const LinearGradient(colors: [Dash.turquoise, Dash.aqua, Dash.sky]),
                            boxShadow: [
                              BoxShadow(
                                color: Dash.aqua.withValues(alpha: 0.5),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                      for (final h in widget.hitos)
                        Positioned(
                          left: w * h.pct / 100 - 1,
                          top: zona - 6,
                          width: 2,
                          height: alto + 12,
                          child: ColoredBox(color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      for (var i = 0; i < grupos.length; i++)
                        _etiqueta(grupos[i], i, w, anchoEtiqueta, zona, alto),
                      Positioned(
                        left: (relleno - 22).clamp(-6.0, math.max(-6.0, w - 38)).toDouble(),
                        top: zona + alto / 2 - 26 - salto,
                        child: Image.asset(
                          DashAssets.head,
                          width: 44,
                          errorBuilder: (context, error, stack) => const SizedBox(width: 44, height: 44),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _etiqueta(_Grupo g, int i, double w, double ancho, double zona, double alto) {
    final alcanzado = widget.porcentaje >= g.pct;
    final x = (w * g.pct / 100 - ancho / 2).clamp(0.0, math.max(0.0, w - ancho)).toDouble();
    final arriba = i.isEven;
    final pcts = g.pcts.map((p) => '${p.toStringAsFixed(0)} %').join(' · ');
    final contenido = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (alcanzado)
              const SelloX(size: 18, animar: false)
            else
              const Icon(Icons.flag_outlined, size: 16, color: Dash.sky),
            const SizedBox(width: 5),
            Text(pcts, style: Dash.code(13, color: alcanzado ? Dash.aqua : Colors.white)),
          ],
        ),
        Text(
          g.etiquetas.join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Dash.body(11.5, color: Colors.white.withValues(alpha: 0.85), height: 1.2),
        ),
      ],
    );
    return Positioned(
      left: x,
      width: ancho,
      top: arriba ? 0 : zona + alto + 10,
      height: zona - 14,
      child: Align(
        alignment: arriba ? Alignment.bottomLeft : Alignment.topLeft,
        child: contenido,
      ),
    );
  }
}
