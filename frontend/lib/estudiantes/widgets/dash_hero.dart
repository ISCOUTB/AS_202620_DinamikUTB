import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dash_style.dart';

/// Saludo con el personaje verde señalando el mensaje clave del momento.
class DashHero extends StatefulWidget {
  const DashHero({
    super.key,
    required this.nombre,
    required this.programa,
    required this.codigo,
    required this.semestre,
    required this.periodo,
    required this.mensaje,
    this.submensaje,
  });

  final String nombre;
  final String programa;
  final String codigo;
  final int? semestre;
  final String periodo;
  final String mensaje;
  final String? submensaje;

  @override
  State<DashHero> createState() => _DashHeroState();
}

class _DashHeroState extends State<DashHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  bool _iniciada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciada) return;
    _iniciada = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _bob.value = 0.25;
    } else {
      _bob.repeat();
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compacto = esCompacto(context);
    final alto = compacto ? 150.0 : 210.0;
    final primerNombre = widget.nombre.trim().split(' ').first;

    final guia = TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Transform.translate(
        offset: Offset((1 - v) * -60, 0),
        child: Opacity(opacity: c01(v), child: child),
      ),
      child: AnimatedBuilder(
        animation: _bob,
        builder: (context, child) {
          final s = math.sin(_bob.value * 2 * math.pi);
          return Transform.translate(
            offset: Offset(0, s * 6),
            child: Transform.rotate(angle: s * 0.03, child: child),
          );
        },
        child: Image.asset(
          DashAssets.guide,
          height: alto,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => SizedBox(height: alto),
        ),
      ),
    );

    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(icono: Icons.badge_outlined, texto: 'Código ${widget.codigo}'),
        if (widget.semestre != null)
          _Chip(
            icono: Icons.calendar_month_outlined,
            texto: 'Semestre ${widget.semestre}',
          ),
        _Chip(icono: Icons.event_note_outlined, texto: 'Periodo ${widget.periodo}'),
      ],
    );

    final burbuja = GlassPanel(
      blur: false,
      alpha: 0.5,
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.mensaje, style: Dash.body(18, weight: FontWeight.w700)),
          if (widget.submensaje != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.submensaje!,
              style: Dash.body(13.5, color: Dash.sky),
            ),
          ],
        ],
      ),
    );

    final texto = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        chips,
        const SizedBox(height: 14),
        Text('Hola, $primerNombre', style: Dash.display(compacto ? 40 : 54)),
        const SizedBox(height: 6),
        Text(
          widget.programa,
          style: Dash.body(16, color: Colors.white.withValues(alpha: 0.85)),
        ),
        const SizedBox(height: 16),
        burbuja,
      ],
    );

    if (compacto) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(alignment: Alignment.centerLeft, child: guia),
          const SizedBox(height: 4),
          texto,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [guia, const SizedBox(width: 24), Expanded(child: texto)],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 15, color: Dash.sky),
        const SizedBox(width: 6),
        Text(texto, style: Dash.body(12.5, weight: FontWeight.w600)),
      ],
    ),
  );
}
