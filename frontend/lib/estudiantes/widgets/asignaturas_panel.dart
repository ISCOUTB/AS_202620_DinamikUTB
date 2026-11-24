import 'package:flutter/material.dart';

import '../progreso_models.dart';
import 'dash_sheets.dart';
import 'dash_style.dart';

/// Qué sigue en la malla: materias en curso, disponibles hoy (matrícula
/// inmediata) y bloqueadas por prerrequisito, con lo que falta aprobar.
class AsignaturasPanel extends StatefulWidget {
  const AsignaturasPanel({super.key, required this.cursos});

  final List<CursoProgreso> cursos;

  @override
  State<AsignaturasPanel> createState() => _AsignaturasPanelState();
}

class _AsignaturasPanelState extends State<AsignaturasPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  bool _iniciada = false;
  bool _todasDisponibles = false;
  bool _todasBloqueadas = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciada) return;
    _iniciada = true;
    if (!MediaQuery.disableAnimationsOf(context)) _pulso.repeat();
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enCurso = widget.cursos.where((c) => c.enCurso).toList();
    final disponibles = widget.cursos.where((c) => c.pendiente && c.desbloqueada).toList();
    final bloqueadas = widget.cursos.where((c) => c.pendiente && !c.desbloqueada).toList();

    final colDisponibles = _Columna(
      titulo: 'Disponibles hoy',
      subtitulo: 'Matrícula inmediata: ya cumples sus prerrequisitos.',
      color: Dash.sky,
      total: disponibles.length,
      expandida: _todasDisponibles,
      onExpandir: () => setState(() => _todasDisponibles = !_todasDisponibles),
      items: [
        for (final c in disponibles)
          _Fila(
            curso: c,
            lider: _Pin(pulso: _pulso),
            extra: c.desbloquea.isEmpty ? null : 'desbloquea ${c.desbloquea.length}',
          ),
      ],
      vacio: 'No hay materias disponibles por ahora.',
    );
    final colBloqueadas = _Columna(
      titulo: 'Bloqueadas por prerrequisito',
      subtitulo: 'Ruta crítica: aprueba primero lo que aparece en rojo.',
      color: Dash.coral,
      total: bloqueadas.length,
      expandida: _todasBloqueadas,
      onExpandir: () => setState(() => _todasBloqueadas = !_todasBloqueadas),
      items: [
        for (final c in bloqueadas)
          _Fila(
            curso: c,
            lider: const Icon(Icons.lock_outline_rounded, color: Colors.white54, size: 22),
            faltantes: c.prerequisitosFaltantes,
          ),
      ],
      vacio: 'Nada bloqueado. ¡Vas despejado!',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (enCurso.isNotEmpty) ...[
          GlassPanel(
            blur: false,
            alpha: 0.46,
            radius: 24,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cursando ahora', style: Dash.body(16, weight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in enCurso)
                      ActionChip(
                        onPressed: () => mostrarCurso(context, c),
                        backgroundColor: Dash.amber.withValues(alpha: 0.18),
                        side: const BorderSide(color: Dash.amber),
                        avatar: RotationTransition(
                          turns: _pulso,
                          child: const Icon(Icons.autorenew_rounded, size: 16, color: Dash.amber),
                        ),
                        label: Text(
                          '${c.nombre} · ${c.periodo ?? ''}',
                          style: Dash.body(12.5, weight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth >= 760) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: colDisponibles),
                  const SizedBox(width: 16),
                  Expanded(child: colBloqueadas),
                ],
              );
            }
            return Column(children: [colDisponibles, const SizedBox(height: 16), colBloqueadas]);
          },
        ),
      ],
    );
  }
}

class _Columna extends StatelessWidget {
  const _Columna({
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.total,
    required this.expandida,
    required this.onExpandir,
    required this.items,
    required this.vacio,
  });

  final String titulo;
  final String subtitulo;
  final Color color;
  final int total;
  final bool expandida;
  final VoidCallback onExpandir;
  final List<Widget> items;
  final String vacio;

  static const _limite = 6;

  @override
  Widget build(BuildContext context) {
    final visibles = expandida ? items : items.take(_limite).toList();
    return GlassPanel(
      blur: false,
      alpha: 0.46,
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(titulo, style: Dash.body(17, weight: FontWeight.w800))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$total', style: Dash.code(13, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitulo, style: Dash.body(12.5, color: Colors.white.withValues(alpha: 0.75))),
          const SizedBox(height: 10),
          if (items.isEmpty) Text(vacio, style: Dash.body(14)),
          ...visibles,
          if (items.length > _limite)
            TextButton(
              onPressed: onExpandir,
              child: Text(
                expandida ? 'Ver menos' : 'Ver las ${items.length}',
                style: Dash.body(13.5, weight: FontWeight.w700, color: Dash.aqua),
              ),
            ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.curso, required this.lider, this.extra, this.faltantes});

  final CursoProgreso curso;
  final Widget lider;
  final String? extra;
  final List<String>? faltantes;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: () => mostrarCurso(context, curso),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 30, child: Center(child: lider)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(curso.nombre, style: Dash.body(14.5, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  'S${curso.nivel} · ${curso.codigo} · ${curso.creditos} cr'
                  '${extra == null ? '' : ' · $extra'}',
                  style: Dash.code(11.5, color: Colors.white70, weight: FontWeight.w500),
                ),
                if (faltantes != null && faltantes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final f in faltantes!)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Dash.coral.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Dash.coral),
                          ),
                          child: Text(f, style: Dash.code(11)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Pin de ubicación con anillo de pulso suave.
class _Pin extends StatelessWidget {
  const _Pin({required this.pulso});

  final Animation<double> pulso;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: pulso,
    builder: (context, _) => Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 12 + pulso.value * 20,
          height: 12 + pulso.value * 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Dash.sky.withValues(alpha: 0.7 * (1 - pulso.value)),
              width: 2,
            ),
          ),
        ),
        const Icon(Icons.place_rounded, color: Dash.sky, size: 22),
      ],
    ),
  );
}
