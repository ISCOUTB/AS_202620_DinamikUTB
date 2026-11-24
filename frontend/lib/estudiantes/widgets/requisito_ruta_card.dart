import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../progreso_models.dart';
import 'dash_style.dart';
import 'sello_x.dart';

/// Tarjeta de un requisito de grado: sello ✕ si está cumplido, aviso de
/// créditos si aún no se habilita, y guía paso a paso al desplegarla.
class RequisitoRutaCard extends StatefulWidget {
  const RequisitoRutaCard({super.key, required this.requisito});

  final RutaRequisito requisito;

  @override
  State<RequisitoRutaCard> createState() => _RequisitoRutaCardState();
}

class _RequisitoRutaCardState extends State<RequisitoRutaCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _giro = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  bool _abierta = false;
  bool _iniciada = false;
  final Set<int> _hechos = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciada) return;
    _iniciada = true;
    if (widget.requisito.estado == 'en_proceso' &&
        !MediaQuery.disableAnimationsOf(context)) {
      _giro.repeat();
    }
  }

  @override
  void dispose() {
    _giro.dispose();
    super.dispose();
  }

  static Color _colorCategoria(String? c) => switch (c) {
    'Idiomas' => Dash.aqua,
    'Evaluacion' => Dash.amber,
    'Proyeccion' => const Color(0xFFFB923C),
    'Administrativo' => const Color(0xFFC4B5FD),
    _ => Dash.sky,
  };

  String _subtitulo(RutaRequisito r) {
    switch (r.estado) {
      case 'cumplido':
        final f = r.fechaCumplimiento;
        return f == null ? 'Cumplido' : 'Cumplido el ${fechaCorta(f)}';
      case 'en_proceso':
        return r.periodo == null ? 'En proceso' : 'En proceso · ${r.periodo}';
      default:
        final faltan = r.creditosFaltantes;
        if (faltan != null && faltan > 0) {
          return 'Te faltan $faltan créditos para el ${r.porcentajeCreditosRequerido} %';
        }
        if (r.habilitado == true) return '¡Ya puedes iniciarlo!';
        return 'Pendiente';
    }
  }

  double? _avanceCreditos(RutaRequisito r) {
    final req = r.creditosRequeridos;
    final faltan = r.creditosFaltantes;
    if (req == null || faltan == null || req == 0) return null;
    return c01((req - faltan) / req);
  }

  Widget _indicador(RutaRequisito r) {
    switch (r.estado) {
      case 'cumplido':
        return const SelloX(size: 48);
      case 'en_proceso':
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Dash.amber.withValues(alpha: 0.2),
            border: Border.all(color: Dash.amber, width: 2),
          ),
          child: RotationTransition(
            turns: _giro,
            child: const Icon(Icons.autorenew_rounded, color: Dash.amber, size: 26),
          ),
        );
      default:
        final avance = _avanceCreditos(r);
        if (r.habilitado == true) {
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Dash.aqua.withValues(alpha: 0.2),
              border: Border.all(color: Dash.aqua, width: 2),
            ),
            child: const Icon(Icons.rocket_launch_outlined, color: Dash.aqua, size: 24),
          );
        }
        return SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: avance ?? 0,
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  color: Dash.amber,
                ),
              ),
              Icon(
                avance == null ? Icons.hourglass_empty_rounded : Icons.lock_clock_outlined,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.requisito;
    final color = _colorCategoria(r.categoria);
    final pasos = r.pasosGuia;
    return GlassPanel(
      blur: false,
      alpha: 0.48,
      radius: 24,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => setState(() => _abierta = !_abierta),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _indicador(r),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (r.categoria != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              r.categoria!,
                              style: Dash.body(11.5, weight: FontWeight.w700, color: color),
                            ),
                          ),
                        Text(r.nombre, style: Dash.body(17, weight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(
                          _subtitulo(r),
                          style: Dash.body(
                            13,
                            color: r.habilitado == true && r.estado == 'pendiente'
                                ? Dash.aqua
                                : Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _abierta ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.expand_more_rounded, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _abierta
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _detalle(r, pasos),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _detalle(RutaRequisito r, List<PasoGuia> pasos) {
    final avance = _avanceCreditos(r);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 12),
        if (avance != null && r.estado != 'cumplido') ...[
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: avance,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    color: avance >= 1 ? Dash.aqua : Dash.amber,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${r.creditosRequeridos! - (r.creditosFaltantes ?? 0)}/${r.creditosRequeridos} cr',
                style: Dash.code(12),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (r.guiaResumen != null)
          Text(
            r.guiaResumen!,
            style: Dash.body(14, color: Colors.white.withValues(alpha: 0.9), height: 1.4),
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (r.tiempoEstimado != null)
              _Dato(icono: Icons.schedule_outlined, texto: r.tiempoEstimado!),
            if (r.portalOficial != null)
              _Dato(icono: Icons.link_rounded, texto: r.portalOficial!, seleccionable: true),
            if (r.evidencia != null && r.evidencia!.isNotEmpty)
              _Dato(icono: Icons.verified_outlined, texto: r.evidencia!),
          ],
        ),
        if (pasos.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text('Cómo cumplirlo paso a paso', style: Dash.body(15, weight: FontWeight.w700)),
              ),
              Text('${_hechos.length}/${pasos.length}', style: Dash.code(13, color: Dash.aqua)),
            ],
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < pasos.length; i++)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Dash.aqua,
              checkColor: Dash.ink,
              side: const BorderSide(color: Colors.white70, width: 1.5),
              value: _hechos.contains(i),
              onChanged: (v) => setState(() {
                if (v ?? false) {
                  _hechos.add(i);
                } else {
                  _hechos.remove(i);
                }
              }),
              title: Text(
                pasos[i].titulo,
                style: Dash.body(
                  14,
                  weight: FontWeight.w600,
                  color: _hechos.contains(i) ? Colors.white54 : Colors.white,
                ).copyWith(
                  decoration: _hechos.contains(i) ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text(
                [pasos[i].detalle, if (pasos[i].oficina.isNotEmpty) '→ ${pasos[i].oficina}']
                    .where((s) => s.isNotEmpty)
                    .join('\n'),
                style: Dash.body(12.5, color: Colors.white.withValues(alpha: 0.7), height: 1.3),
              ),
            ),
        ],
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto, this.seleccionable = false});

  final IconData icono;
  final String texto;
  final bool seleccionable;

  @override
  Widget build(BuildContext context) {
    final estilo = Dash.body(12.5, color: Colors.white.withValues(alpha: 0.9));
    return Container(
      constraints: BoxConstraints(maxWidth: math.max(120, MediaQuery.sizeOf(context).width - 120)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 15, color: Dash.sky),
          const SizedBox(width: 6),
          Flexible(
            child: seleccionable
                ? SelectableText(texto, style: estilo)
                : Text(texto, style: estilo),
          ),
        ],
      ),
    );
  }
}
