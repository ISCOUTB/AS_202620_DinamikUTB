import 'package:flutter/material.dart';

import '../progreso_models.dart';
import 'dash_motion.dart';
import 'dash_style.dart';
import 'sello_x.dart';

class _Logro {
  const _Logro({
    required this.fecha,
    required this.periodo,
    required this.titulo,
    required this.detalle,
    required this.esRequisito,
    this.creditos = 0,
  });

  final DateTime fecha;
  final String periodo;
  final String titulo;
  final String detalle;
  final bool esRequisito;
  final int creditos;
}

String _periodoDe(DateTime f) => '${f.year}-${f.month <= 6 ? 1 : 2}';

/// Línea de tiempo de todo lo sellado con ✕, agrupado por periodo.
class BitacoraLogros extends StatefulWidget {
  const BitacoraLogros({super.key, required this.cursos, required this.requisitos});

  final List<CursoProgreso> cursos;
  final List<RutaRequisito> requisitos;

  @override
  State<BitacoraLogros> createState() => _BitacoraLogrosState();
}

class _BitacoraLogrosState extends State<BitacoraLogros> {
  bool _todo = false;

  Map<String, List<_Logro>> _agrupar() {
    final logros = <_Logro>[
      for (final c in widget.cursos)
        if (c.aprobado && c.fechaAprobacion != null)
          _Logro(
            fecha: c.fechaAprobacion!,
            periodo: c.periodo ?? _periodoDe(c.fechaAprobacion!),
            titulo: c.nombre,
            detalle: '${c.codigo} · ${c.creditos} cr'
                '${c.nota == null ? '' : ' · nota ${c.nota!.toStringAsFixed(1)}'}',
            esRequisito: false,
            creditos: c.creditos,
          ),
      for (final r in widget.requisitos)
        if (r.estado == 'cumplido' && r.fechaCumplimiento != null)
          _Logro(
            fecha: r.fechaCumplimiento!,
            periodo: r.periodo ?? _periodoDe(r.fechaCumplimiento!),
            titulo: r.nombre,
            detalle: 'Requisito de grado${r.codigoInterno == null ? '' : ' · ${r.codigoInterno}'}',
            esRequisito: true,
          ),
    ]..sort((a, b) => b.fecha.compareTo(a.fecha));
    final grupos = <String, List<_Logro>>{};
    for (final l in logros) {
      grupos.putIfAbsent(l.periodo, () => []).add(l);
    }
    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _agrupar();
    if (grupos.isEmpty) {
      return GlassPanel(
        blur: false,
        child: Text(
          'Aún no hay logros sellados. Cuando tu coordinación registre una materia '
          'aprobada o un requisito cumplido, aparecerá aquí con su fecha.',
          style: Dash.body(14.5, height: 1.4),
        ),
      );
    }
    final periodos = grupos.keys.toList()..sort((a, b) => b.compareTo(a));
    final visibles = _todo ? periodos : periodos.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              for (var g = 0; g < visibles.length; g++)
                _Grupo(
                  periodo: visibles[g],
                  logros: grupos[visibles[g]]!,
                  ultimo: g == visibles.length - 1,
                ),
            ],
          ),
        ),
        if (periodos.length > 2)
          Padding(
            padding: const EdgeInsets.only(left: 44, top: 4),
            child: TextButton.icon(
              onPressed: () => setState(() => _todo = !_todo),
              icon: Icon(_todo ? Icons.expand_less : Icons.history_rounded, color: Dash.aqua),
              label: Text(
                _todo ? 'Ver solo lo reciente' : 'Ver todo el historial (${periodos.length - 2} periodos más)',
                style: Dash.body(14, weight: FontWeight.w700, color: Dash.aqua),
              ),
            ),
          ),
      ],
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo({required this.periodo, required this.logros, required this.ultimo});

  final String periodo;
  final List<_Logro> logros;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    final materias = logros.where((l) => !l.esRequisito).length;
    final creditos = logros.fold<int>(0, (s, l) => s + l.creditos);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Dash.amber,
                    boxShadow: [BoxShadow(color: Dash.amber.withValues(alpha: 0.6), blurRadius: 10)],
                  ),
                ),
                if (!ultimo)
                  Expanded(
                    child: Container(width: 2, color: Colors.white.withValues(alpha: 0.25)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(periodo, style: Dash.code(20, color: Dash.amber)),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          [
                            if (materias > 0) '$materias ${materias == 1 ? 'materia' : 'materias'}',
                            if (creditos > 0) '$creditos cr',
                          ].join(' · '),
                          style: Dash.body(13, color: Colors.white.withValues(alpha: 0.75)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < logros.length; i++)
                    Reveal(
                      delay: Duration(milliseconds: 40 * (i % 6)),
                      offset: 16,
                      child: _Entrada(logro: logros[i]),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Entrada extends StatelessWidget {
  const _Entrada({required this.logro});

  final _Logro logro;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Dash.ink.withValues(alpha: logro.esRequisito ? 0.62 : 0.42),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: logro.esRequisito ? Dash.amber.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.14),
      ),
    ),
    child: Row(
      children: [
        const SelloX(size: 30, animar: false),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(logro.titulo, style: Dash.body(14.5, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                logro.detalle,
                style: Dash.code(11.5, color: Colors.white70, weight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(fechaCorta(logro.fecha), style: Dash.code(12, color: Dash.sky, weight: FontWeight.w600)),
      ],
    ),
  );
}
