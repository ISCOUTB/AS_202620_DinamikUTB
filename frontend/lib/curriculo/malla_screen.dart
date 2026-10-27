import 'package:flutter/material.dart';

import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/widgets/async_view.dart';
import 'package:frontend/core/widgets/metric_card.dart';
import 'package:frontend/core/widgets/page_list.dart';
import 'package:frontend/core/widgets/responsive_grid.dart';
import 'malla_service.dart';
import 'models.dart';
import 'widgets/course_card.dart';

class MallaScreen extends StatelessWidget {
  const MallaScreen({
    super.key,
    required this.service,
    required this.programa,
    this.semestreActual,
  });

  final MallaService service;
  final String programa;
  final int? semestreActual;

  @override
  Widget build(BuildContext context) => AsyncView<MallaCurricular>(
    load: () => service.obtener(programa),
    builder: (context, malla) {
      final cursosPorNivel = <int, List<CursoCurricular>>{};
      for (final curso in malla.cursos) {
        cursosPorNivel.putIfAbsent(curso.nivel, () => []).add(curso);
      }
      return PageList(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Malla curricular',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    malla.programa,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PlanTag(label: 'Plan ${malla.plan}'),
                      _PlanTag(label: 'Catálogo curricular'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ResponsiveGrid(
            minTileWidth: 170,
            spacing: 10,
            children: [
              MetricCard(
                title: 'Cursos',
                value: '${malla.cursos.length}',
                caption: 'En el plan de estudios',
                icon: Icons.menu_book_outlined,
                color: AppColors.navy,
                background: AppColors.surfaceLow,
              ),
              MetricCard(
                title: 'Créditos',
                value: '${malla.creditosTotales}',
                caption: 'Total declarado del plan',
                icon: Icons.school_outlined,
                color: AppColors.cyan,
                background: AppColors.infoBg,
              ),
              MetricCard(
                title: 'Niveles',
                value: '${malla.niveles}',
                caption: 'Semestres académicos',
                icon: Icons.calendar_month_outlined,
                color: AppColors.cyan,
                background: AppColors.infoBg,
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final entry in cursosPorNivel.entries) ...[
            _NivelCurricular(
              nivel: entry.key,
              cursos: entry.value,
              esActual: entry.key == semestreActual,
            ),
            const SizedBox(height: 12),
          ],
        ],
      );
    },
  );
}

class _NivelCurricular extends StatelessWidget {
  const _NivelCurricular({
    required this.nivel,
    required this.cursos,
    required this.esActual,
  });

  final int nivel;
  final List<CursoCurricular> cursos;
  final bool esActual;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Semestre $nivel',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (esActual) const _PlanTag(label: 'Tu semestre'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${cursos.length} cursos · ${cursos.fold<int>(0, (total, curso) => total + curso.creditos)} créditos',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          ResponsiveGrid(
            minTileWidth: 300,
            spacing: 10,
            children: [for (final curso in cursos) CourseCard(curso: curso)],
          ),
        ],
      ),
    ),
  );
}

class _PlanTag extends StatelessWidget {
  const _PlanTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.infoBg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.cyan,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
