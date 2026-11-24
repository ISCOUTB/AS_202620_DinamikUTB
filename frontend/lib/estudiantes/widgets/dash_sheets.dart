import 'package:flutter/material.dart';

import '../progreso_models.dart';
import 'dash_style.dart';
import 'sello_x.dart';

class _Hoja extends StatelessWidget {
  const _Hoja({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final alto = MediaQuery.sizeOf(context).height * 0.82;
    return Container(
      constraints: BoxConstraints(maxHeight: alto, maxWidth: 760),
      decoration: BoxDecoration(
        color: Dash.ink.withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

(IconData, Color, String) _visual(CursoProgreso c) {
  if (c.aprobado) return (Icons.check_circle_rounded, Dash.aqua, 'Aprobada');
  if (c.enCurso) return (Icons.autorenew_rounded, Dash.amber, 'En curso');
  if (c.desbloqueada) return (Icons.place_rounded, Dash.sky, 'Disponible hoy');
  return (Icons.lock_outline_rounded, Colors.white54, 'Bloqueada');
}

String _detalleCurso(CursoProgreso c) {
  if (c.aprobado) {
    final f = c.fechaAprobacion == null ? '' : fechaCorta(c.fechaAprobacion!);
    final n = c.nota == null ? '' : ' · nota ${c.nota!.toStringAsFixed(1)}';
    return '$f$n'.trim();
  }
  if (c.enCurso) return 'Periodo ${c.periodo ?? '—'}';
  if (!c.desbloqueada) return 'Falta: ${c.prerequisitosFaltantes.join(', ')}';
  return 'Matrícula inmediata';
}

/// Materias de un semestre con su estado, fecha y nota.
Future<void> mostrarSemestre(
  BuildContext context, {
  required int nivel,
  required NivelProgreso? resumen,
  required List<CursoProgreso> cursos,
  required VoidCallback onVerMalla,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheet) => Align(
      alignment: Alignment.bottomCenter,
      child: _Hoja(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Semestre $nivel', style: Dash.display(30)),
            if (resumen != null) ...[
              const SizedBox(height: 6),
              Text(
                '${resumen.creditosAprobados} de ${resumen.creditosTotales} créditos aprobados '
                '(${resumen.porcentaje.toStringAsFixed(0)} %)',
                style: Dash.body(14, color: Dash.sky),
              ),
            ],
            const SizedBox(height: 14),
            for (final c in cursos)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.aprobado)
                      const SelloX(size: 26, animar: false)
                    else
                      Icon(_visual(c).$1, color: _visual(c).$2, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.nombre, style: Dash.body(15, weight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            '${c.codigo} · ${c.creditos} cr · ${_detalleCurso(c)}',
                            style: Dash.code(12, color: Colors.white70, weight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Dash.aqua,
                foregroundColor: Dash.ink,
              ),
              onPressed: () {
                Navigator.of(sheet).pop();
                onVerMalla();
              },
              icon: const Icon(Icons.account_tree_outlined),
              label: const Text('Ver malla completa'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Detalle de una materia: estado, fecha/nota, prerrequisitos y lo que desbloquea.
Future<void> mostrarCurso(BuildContext context, CursoProgreso c) {
  final v = _visual(c);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheet) => Align(
      alignment: Alignment.bottomCenter,
      child: _Hoja(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (c.aprobado)
                  const SelloX(size: 38)
                else
                  Icon(v.$1, color: v.$2, size: 34),
                const SizedBox(width: 12),
                Expanded(child: Text(c.nombre, style: Dash.display(24))),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${c.codigo} · Semestre ${c.nivel} · ${c.creditos} créditos · ${v.$3}',
              style: Dash.code(12.5, color: Dash.sky, weight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(_detalleCurso(c), style: Dash.body(14)),
            if (c.prerequisitos.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Prerrequisitos', style: Dash.body(14, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              _Fichas(codigos: c.prerequisitos, resaltar: c.prerequisitosFaltantes),
            ],
            if (c.desbloquea.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Desbloquea', style: Dash.body(14, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              _Fichas(codigos: c.desbloquea, resaltar: const []),
            ],
          ],
        ),
      ),
    ),
  );
}

class _Fichas extends StatelessWidget {
  const _Fichas({required this.codigos, required this.resaltar});

  final List<String> codigos;
  final List<String> resaltar;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final c in codigos)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: resaltar.contains(c)
                ? Dash.coral.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: resaltar.contains(c) ? Dash.coral : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Text(c, style: Dash.code(12.5)),
        ),
    ],
  );
}
